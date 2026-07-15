import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Selector de hora propio de Ora Ahora: dos ruedas grandes (hora y
/// minutos) en una hoja inferior. Reemplaza al reloj de Material, que se
/// veia desordenado y no se adaptaba bien a pantallas pequenas.
Future<TimeOfDay?> showTimeWheelPicker(
  BuildContext context, {
  required TimeOfDay initial,
  required String titulo,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: false,
    builder: (context) => _TimeWheelSheet(initial: initial, titulo: titulo),
  );
}

class _TimeWheelSheet extends StatefulWidget {
  final TimeOfDay initial;
  final String titulo;
  const _TimeWheelSheet({required this.initial, required this.titulo});

  @override
  State<_TimeWheelSheet> createState() => _TimeWheelSheetState();
}

class _TimeWheelSheetState extends State<_TimeWheelSheet> {
  late int _hour;
  late int _minuteIndex; // pasos de 5 minutos
  late final FixedExtentScrollController _hCtrl;
  late final FixedExtentScrollController _mCtrl;

  @override
  void initState() {
    super.initState();
    _hour = widget.initial.hour;
    _minuteIndex = (widget.initial.minute / 5).round() % 12;
    _hCtrl = FixedExtentScrollController(initialItem: _hour);
    _mCtrl = FixedExtentScrollController(initialItem: _minuteIndex);
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    _mCtrl.dispose();
    super.dispose();
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 92,
      height: 190,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 56,
        physics: const FixedExtentScrollPhysics(),
        overAndUnderCenterOpacity: 0.28,
        magnification: 1.12,
        useMagnifier: true,
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildLoopingListDelegate(
          children: [
            for (var i = 0; i < count; i++)
              Center(
                child: Text(
                  label(i),
                  style: AppTypography.display.copyWith(
                    fontSize: 34,
                    color: scheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.titulo,
                style: AppTypography.headline.copyWith(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              'Desliza los números hasta la hora que prefieras',
              style: AppTypography.body.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _wheel(
                      controller: _hCtrl,
                      count: 24,
                      label: (i) => i.toString().padLeft(2, '0'),
                      onChanged: (i) => setState(() => _hour = i),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(':',
                          style: AppTypography.display.copyWith(fontSize: 34)),
                    ),
                    _wheel(
                      controller: _mCtrl,
                      count: 12,
                      label: (i) => (i * 5).toString().padLeft(2, '0'),
                      onChanged: (i) => setState(() => _minuteIndex = i),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pop(TimeOfDay(hour: _hour, minute: _minuteIndex * 5)),
              child: const Text('Guardar esta hora'),
            ),
          ],
        ),
      ),
    );
  }
}
