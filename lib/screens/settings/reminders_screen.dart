import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/notification_service.dart';
import '../../services/prefs_service.dart';
import '../../services/usage_pattern_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Gestiona hasta 3 horarios de recordatorio diario y el interruptor
/// general de notificaciones (con el permiso de Android 13+ POST_NOTIFICATIONS).
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const _maxTimes = 3;

  late List<String> _times;
  late bool _enabled;
  late bool _smartReminderEnabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<PrefsService>();
    _times = List.from(prefs.reminderTimes);
    _enabled = prefs.notificationsEnabled;
    _smartReminderEnabled = prefs.smartReminderEnabled;
    // Si el interruptor ya estaba activo de una sesion anterior y para
    // entonces no habia suficientes datos, aqui se aprovecha para
    // reprogramar el aviso en caso de que ya se hayan acumulado suficientes
    // eventos de uso desde la ultima vez que se abrio esta pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRefreshSmartReminder());
  }

  Future<void> _maybeRefreshSmartReminder() async {
    if (!_smartReminderEnabled) return;
    final usagePatternService = UsagePatternService(context.read<PrefsService>());
    final hour = usagePatternService.mostCommonHour();
    if (hour == null) return;
    if (!mounted) return;
    await context.read<NotificationService>().scheduleSmartReminder(hour);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _addTime() async {
    if (_times.length >= _maxTimes) return;
    final result = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (result != null) {
      setState(() => _times.add(_fmt(result)));
      await _persist();
    }
  }

  Future<void> _editTime(int index) async {
    final result = await showTimePicker(
      context: context,
      initialTime: _parse(_times[index]),
    );
    if (result != null) {
      setState(() => _times[index] = _fmt(result));
      await _persist();
    }
  }

  void _removeTime(int index) {
    setState(() => _times.removeAt(index));
    _persist();
  }

  Future<void> _toggleEnabled(bool value) async {
    if (value) {
      final notifications = context.read<NotificationService>();
      final granted = await notifications.requestPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Activa las notificaciones para Ora Ahora en los ajustes '
              'del sistema para recibir recordatorios.',
            ),
          ),
        );
      }
    }
    setState(() => _enabled = value);
    await _persist();
  }

  Future<void> _persist() async {
    setState(() => _saving = true);
    final prefs = context.read<PrefsService>();
    await prefs.setReminderTimes(_times);
    await prefs.setNotificationsEnabled(_enabled);

    final notifications = context.read<NotificationService>();
    if (_enabled && _times.isNotEmpty) {
      await notifications.refreshSchedule(_times);
    } else {
      await notifications.cancelAll();
    }
    if (mounted) setState(() => _saving = false);
  }

  /// "Recordatorio inteligente" (opt-in, apagado por defecto): un aviso
  /// ADITIVO ademas de los horarios fijos de arriba, basado en la hora en
  /// la que la persona suele abrir una app "gateada" (ver
  /// `UsagePatternService`). Si todavia no hay suficientes datos, se activa
  /// el interruptor pero no se programa nada (ver el subtitle en el
  /// `build`, que ya se lo explica a la persona); en cuanto haya suficientes
  /// datos, basta con volver a abrir esta pantalla para que se programe
  /// (ver `_maybeRefreshSmartReminder`).
  Future<void> _toggleSmartReminder(bool value) async {
    setState(() => _smartReminderEnabled = value);
    final prefs = context.read<PrefsService>();
    await prefs.setSmartReminderEnabled(value);

    final notifications = context.read<NotificationService>();
    if (value) {
      final usagePatternService = UsagePatternService(context.read<PrefsService>());
      final hour = usagePatternService.mostCommonHour();
      if (hour != null) {
        await notifications.scheduleSmartReminder(hour);
      }
    } else {
      await notifications.cancelSmartReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    final usagePatternService = UsagePatternService(context.read<PrefsService>());

    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios diarios')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _enabled,
              onChanged: _saving ? null : _toggleEnabled,
              title: const Text('Activar recordatorios'),
              subtitle: const Text(
                'Avisos suaves para hacer una pausa y orar durante el día.',
              ),
            ),
            const Divider(height: 32),
            Text('Horarios (máximo $_maxTimes)', style: AppTypography.headline),
            const SizedBox(height: 8),
            for (var i = 0; i < _times.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(_parse(_times[i]).format(context)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeTime(i),
                ),
                onTap: () => _editTime(i),
              ),
            if (_times.length < _maxTimes)
              TextButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add),
                label: const Text('Agregar horario'),
              ),
            const Divider(height: 32),
            Text('Recordatorio inteligente', style: AppTypography.headline),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _smartReminderEnabled,
              onChanged: _toggleSmartReminder,
              title: const Text('Avisarme según mi horario habitual'),
              subtitle: Text(
                usagePatternService.hasEnoughData
                    ? 'Además de tus horarios fijos, te avisamos justo antes '
                        'de la hora en la que sueles abrir apps que distraen.'
                    : 'Aún estoy aprendiendo tus horarios habituales. En '
                        'cuanto tenga suficientes datos, te avisaré en el '
                        'momento justo.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}