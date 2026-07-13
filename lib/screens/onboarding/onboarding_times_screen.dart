import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_categories_screen.dart';
import 'onboarding_progress_dots.dart';

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
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 0),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Cuándo sueles orar?',
                style: AppTypography.display,
              ),
              const SizedBox(height: 12),
              Text(
                'Usaremos estos horarios para sugerirte oraciones de '
                'mañana y de noche, y como base para tus recordatorios. '
                'Podrás ajustarlo luego desde Ajustes.',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 32),
              _TimeTile(
                icon: Icons.wb_twilight_rounded,
                label: 'Oración de la mañana',
                time: _fmt(_morning),
                onTap: () => _pick(true),
              ),
              const SizedBox(height: 14),
              _TimeTile(
                icon: Icons.nightlight_round,
                label: 'Oración de la noche',
                time: _fmt(_night),
                onTap: () => _pick(false),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.tealLight, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.tealDeep, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(label, style: AppTypography.title),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  time,
                  style: AppTypography.title.copyWith(color: AppColors.amber),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
