import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/prayer_repository.dart';
import '../../services/purchase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/prayer_card.dart';
import '../paywall/paywall_screen.dart';
import '../prayer_detail/prayer_detail_screen.dart';

/// v17 — "Carpeta" de un tema. Al tocar un tema en el inicio
/// ("¿Algo te pesa hoy?"), se abre aqui la lista de oraciones SOLO de ese
/// tema, en vez de volcar todas las oraciones en la pantalla principal.
///
/// Monetizacion suave: el usuario gratuito puede orar las primeras
/// [_freeVisible] oraciones del tema; el resto aparece con candado y lleva
/// al paywall. Los usuarios Plus ven todo desbloqueado.
class ThemePrayersScreen extends StatefulWidget {
  final String categoria;

  const ThemePrayersScreen({super.key, required this.categoria});

  @override
  State<ThemePrayersScreen> createState() => _ThemePrayersScreenState();
}

class _ThemePrayersScreenState extends State<ThemePrayersScreen> {
  static const _freeVisible = 3;

  late Future<List<Prayer>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<PrayerRepository>().byCategory(widget.categoria);
  }

  void _openPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  void _openDetail(Prayer p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrayerDetailScreen(prayer: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPlus = context.watch<PurchaseService>().isPlusUser;
    final nombre = PrayerCategories.displayName(widget.categoria);
    final emoji = PrayerCategories.emojiFor(widget.categoria);

    return Scaffold(
      appBar: AppBar(title: Text('$emoji  $nombre')),
      body: SafeArea(
        child: FutureBuilder<List<Prayer>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final prayers = snapshot.data!;
            if (prayers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Pronto agregaremos más oraciones de este tema 🙏',
                    textAlign: TextAlign.center,
                    style:
                        AppTypography.body.copyWith(color: AppColors.inkSoft),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: prayers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Respira. Elige una y ora sobre eso.',
                      style: AppTypography.body
                          .copyWith(color: AppColors.inkSoft),
                    ),
                  );
                }
                final i = index - 1;
                final p = prayers[i];
                final bloqueada = !isPlus && i >= _freeVisible;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: PrayerCard(
                    prayer: p,
                    bloqueada: bloqueada,
                    onTap: bloqueada ? _openPaywall : () => _openDetail(p),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// v17 — Explorador de TODOS los temas, en cuadricula de "carpetas"
/// (emoji + nombre). Se llega desde "Ver todos los temas" en el inicio.
class AllThemesScreen extends StatelessWidget {
  const AllThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final temas = PrayerCategories.all;
    return Scaffold(
      appBar: AppBar(title: const Text('Temas')),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.55,
          ),
          itemCount: temas.length,
          itemBuilder: (context, i) => ThemeFolderCard(categoria: temas[i]),
        ),
      ),
    );
  }
}

/// Tarjeta-"carpeta" de un tema: emoji grande + nombre, toca para abrir la
/// [ThemePrayersScreen] de ese tema. Reutilizable en el inicio y en el
/// explorador de temas.
class ThemeFolderCard extends StatelessWidget {
  final String categoria;

  const ThemeFolderCard({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nombre = PrayerCategories.displayName(categoria);
    final emoji = PrayerCategories.emojiFor(categoria);
    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ThemePrayersScreen(categoria: categoria),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              Text(
                nombre,
                style: AppTypography.title.copyWith(
                  fontSize: 15,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
