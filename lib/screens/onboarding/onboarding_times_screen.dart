import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_categories_screen.dart';

class OnboardingTimesScreen extends StatefulWidget {
  const OnboardingTimesScreen({super.key});

  @override
  State<OnboardingTimesScreen> createState() => _OnboardingTimesScreenState();
}

class _OnboardingTimesScreenState extends State<OnboardingTimesScreen> {
  TimeOfDay _morning = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _night = const TimeOfDay(hour: 21, minute: 30);

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool morning) async {
    final result = await showTimePicker(
      context: context,
      initialTime: morning ? _morning : _night,
    );
    if (result != null) {
      setState(() {
        if (morning) {
          _morning = result;
        } else {
          _night = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tus horarios')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Cuándo sueles orar?',
                style: AppTypography.headline,
              ),
              const SizedBox(height: 8),
              Text(
                'Usaremos estos horarios para sugerirte oraciones de '
                'mañana y de noche, y como base para tus recordatorios '
                '(los podrás ajustar luego en Ajustes).',
                style: AppTypography.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 28),
              _TimeTile(
                icon: Icons.wb_twilight,
                label: 'Oración de la mañana',
                time: _fmt(_morning),
                onTap: () => _pick(true),
              ),
              const SizedBox(height: 12),
              _TimeTile(
                icon: Icons.nightlight_round,
                label: 'Oración de la noche',
                time: _fmt(_night),
                onTap: () => _pick(false),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = context.read<PrefsService>();
                    await prefs.setMorningTime(_fmt(_morning));
                    await prefs.setNightTime(_fmt(_night));
                    await prefs.setReminderTimes([_fmt(_morning), _fmt(_night)]);
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingCategoriesScreen(),
                      ),
                    );
                  },
                  child: const Text('Siguiente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeTile({
    required this.icon,
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.tealDeep),
        title: Text(label, style: AppTypography.title),
        trailing: Text(time, style: AppTypography.title),
      ),
    );
  }
}
