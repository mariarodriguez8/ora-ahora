import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/community_stats_service.dart';
import '../../services/prayer_repository.dart';
import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/route_observer.dart';
import '../../services/streak_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/faith_tree_widget.dart';
import '../../widgets/prayer_card.dart';
import '../../widgets/streak_badge.dart';
import '../journal/journal_screen.dart';
import '../paywall/paywall_screen.dart';
import '../prayer_detail/prayer_detail_screen.dart';
import '../settings/settings_screen.dart';

/// Contenedor principal de la app despues del onboarding: pestañas de
/// Inicio, Diario y Ajustes con una barra de navegacion inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // El paywall se muestra UNA sola vez, justo despues de terminar el
    // onboarding (el momento "aha" del usuario): ver
    // `PrefsService.paywallShownAfterOnboarding`. Es un paywall "suave":
    // se puede cerrar libremente (boton atras del AppBar) y no vuelve a
    // aparecer automaticamente ni bloquea ninguna funcion gratuita.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboardingPaywall());
  }

  Future<void> _maybeShowOnboardingPaywall() async {
    final prefs = context.read<PrefsService>();
    if (prefs.paywallShownAfterOnboarding) return;
    await prefs.setPaywallShownAfterOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      _HomeFeedTab(),
      JournalScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Diario',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _HomeFeedTab extends StatefulWidget {
  const _HomeFeedTab();

  @override
  State<_HomeFeedTab> createState() => _HomeFeedTabState();
}

/// `SingleTickerProviderStateMixin` se agrega unicamente para poder animar
/// la entrada escalonada ("staggered") de las secciones del inicio la
/// primera vez que se construyen (ver `_entranceController`/
/// `_sectionAnimation`), con una curva organica en vez del aparecer seco
/// de antes.
class _HomeFeedTabState extends State<_HomeFeedTab>
    with RouteAware, SingleTickerProviderStateMixin {
  late Future<_FeedData> _future;
  PageRoute<dynamic>? _subscribedRoute;
  int? _celebratingMilestone;

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceController.forward();
    // Se aprovecha para refrescar el cupo mensual de fichas de
    // congelación (solo aplica si el usuario es Plus), asi la insignia de
    // racha muestra el conteo correcto sin que el usuario tenga que orar
    // primero.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isPlus = context.read<PurchaseService>().isPlusUser;
      context.read<StreakService>().refreshFreezeTokens(isPlusUser: isPlus);
      // Cubre el caso (poco comun) de que ya hubiera un hito pendiente de
      // celebrar apenas se construye esta pantalla por primera vez.
      _maybeCelebrateMilestone();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se suscribe al `RouteObserver` compartido para detectar cuando el
    // usuario *vuelve* a esta pantalla (p. ej. al cerrar
    // `PrayerDetailScreen` despues de marcar una oracion como orada), que
    // es el momento correcto para mostrar la celebracion de hito de racha
    // (ver `didPopNext`).
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        appRouteObserver.unsubscribe(this);
      }
      appRouteObserver.subscribe(this, route);
      _subscribedRoute = route;
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _entranceController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Se volvio a esta pantalla desde otra que se acaba de cerrar (ver
    // `PrayerDetailScreen`): buen momento para mostrar una celebracion de
    // hito si `markPrayedToday` dejo una pendiente.
    _maybeCelebrateMilestone();
  }

  void _maybeCelebrateMilestone() {
    if (!mounted) return;
    final streak = context.read<StreakService>();
    final milestone = streak.pendingMilestone;
    if (milestone == null) return;
    streak.acknowledgeMilestoneShown();
    HapticFeedback.mediumImpact();
    setState(() => _celebratingMilestone = milestone);
  }

  Future<_FeedData> _load() async {
    final repo = context.read<PrayerRepository>();
    final prefs = context.read<PrefsService>();
    final categories = prefs.preferredCategories;
    final oracionDelDia = await repo.prayerOfTheDay(
      preferredCategories: categories,
    );
    final feed = await repo.byCategories(categories);
    feed.removeWhere((p) => p.id == oracionDelDia.id);

    // Prueba social honesta (ver `CommunityStatsService`): hoy siempre
    // devuelve `null` porque no existe un backend real que agregue
    // usuarios activos, asi que el widget de inicio cae de forma segura al
    // copy no cuantificado. Queda listo para mostrar un numero en vivo el
    // dia que se conecte un backend real, sin volver a tocar esta pantalla.
    const communityStats = StubCommunityStatsService();
    final prayingNowEstimate = await communityStats.getPrayingNowEstimate();

    return _FeedData(
      oracionDelDia: oracionDelDia,
      feed: feed,
      prayingNowEstimate: prayingNowEstimate,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  /// Envuelve [child] en una entrada escalonada de fundido+desplazamiento:
  /// el fundido usa una curva suave sin overshoot (`Curves.easeOutCubic`,
  /// segura para valores de opacidad entre 0.0 y 1.0), mientras que el
  /// desplazamiento vertical usa una curva organica con "rebote"
  /// (`Curves.easeOutBack`, segura para un `Offset` aunque exceda
  /// momentaneamente el rango 0..1). [start]/[end] ubican el tramo de
  /// [_entranceController] (0.0 a 1.0) que le corresponde a esta seccion,
  /// para que las secciones aparezcan una tras otra en vez de todas a la
  /// vez.
  Widget _staggeredSection(
    Widget child, {
    required double start,
    required double end,
  }) {
    final fade = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    ));
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streak = context.watch<StreakService>();
    final isPlus = context.watch<PurchaseService>().isPlusUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ora Ahora'),
        actions: [
          if (isPlus && streak.freezeTokens > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: _FreezeTokensChip(tokens: streak.freezeTokens)),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: StreakBadge(
                streak: streak.currentStreak,
                atRisk: streak.streakAtRisk,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<_FeedData>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // 1. Hero: la oracion del dia es el unico elemento
                    // dominante de la pantalla (fondo tonal propio,
                    // capas suaves de profundidad, tipografia mas grande).
                    _staggeredSection(
                      _HeroPrayerSection(
                        prayer: data.oracionDelDia,
                        onTap: () => _openDetail(data.oracionDelDia),
                      ),
                      start: 0.0,
                      end: 0.65,
                    ),
                    const SizedBox(height: 24),
                    // 2. Soporte secundario: arbol de fe + prueba social,
                    // visualmente mas pequeños/ligeros que el hero.
                    _staggeredSection(
                      _SecondarySupportSection(
                        cumulativeMinutes: streak.cumulativeMinutes,
                        prayingNowEstimate: data.prayingNowEstimate,
                      ),
                      start: 0.15,
                      end: 0.8,
                    ),
                    const SizedBox(height: 28),
                    // 3. Feed personalizado + banner Plus, tambien
                    // secundario frente al hero.
                    _staggeredSection(
                      _ParaTiSection(
                        feed: data.feed,
                        isPlus: isPlus,
                        onOpenPrayer: _openDetail,
                        onOpenPaywall: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaywallScreen()),
                          );
                        },
                      ),
                      start: 0.3,
                      end: 1.0,
                    ),
                  ],
                ),
              );
            },
          ),
          if (_celebratingMilestone != null)
            _MilestoneCelebrationOverlay(
              milestone: _celebratingMilestone!,
              onDismiss: () => setState(() => _celebratingMilestone = null),
            ),
        ],
      ),
    );
  }

  void _openDetail(Prayer prayer) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrayerDetailScreen(prayer: prayer)),
    );
  }
}

/// Seccion "hero" del inicio: la unica con fondo tonal propio y la unica
/// pensada para dominar la pantalla por encima del pliegue. Usa
/// `primaryContainer`/`onPrimaryContainer`/`primary` del `ColorScheme`
/// activo (una de las 4 paletas de Ajustes > Apariencia), asi que se
/// adapta automaticamente sin importar cual este seleccionada. Las dos
/// formas circulares translucidas en la esquina son capas planas del
/// mismo tono a distinta opacidad/tamaño (sin gradientes) para dar
/// sensacion de profundidad, siguiendo el mismo principio de "cuentos de
/// color" que las ilustraciones nuevas.
class _HeroPrayerSection extends StatelessWidget {
  final Prayer prayer;
  final VoidCallback onTap;

  const _HeroPrayerSection({required this.prayer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _softCircle(scheme.primary, 130, 0.10),
          ),
          Positioned(
            top: -6,
            right: 24,
            child: _softCircle(scheme.primary, 64, 0.16),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PARA HOY',
                  style: AppTypography.caption.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Oración del día',
                  style: AppTypography.display.copyWith(
                    fontSize: 26,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 18),
                PrayerCard(prayer: prayer, destacada: true, onTap: onTap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _softCircle(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Agrupa el "Arbol de fe" y la prueba social honesta como soporte
/// claramente secundario debajo del hero: sin fondo propio, tipografia
/// mas pequeña, menos aire alrededor.
class _SecondarySupportSection extends StatelessWidget {
  final int cumulativeMinutes;
  final int? prayingNowEstimate;

  const _SecondarySupportSection({
    required this.cumulativeMinutes,
    required this.prayingNowEstimate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaithTreeWidget(cumulativeMinutes: cumulativeMinutes),
        const SizedBox(height: 12),
        _SocialProofBanner(prayingNowEstimate: prayingNowEstimate),
      ],
    );
  }
}

/// Feed personalizado ("Para ti") y banner de Plus: tercer nivel de
/// jerarquia, debajo del hero y del soporte secundario.
class _ParaTiSection extends StatelessWidget {
  final List<Prayer> feed;
  final bool isPlus;
  final ValueChanged<Prayer> onOpenPrayer;
  final VoidCallback onOpenPaywall;

  const _ParaTiSection({
    required this.feed,
    required this.isPlus,
    required this.onOpenPrayer,
    required this.onOpenPaywall,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Para ti', style: AppTypography.headline),
        const SizedBox(height: 4),
        Text(
          'Según los temas que elegiste en tu perfil.',
          style: AppTypography.body.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 12),
        if (feed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Aún no elegiste temas de interés. Ve a Ajustes > '
              'Mis intereses para personalizar tu inicio.',
              style: AppTypography.body.copyWith(color: AppColors.inkSoft),
            ),
          )
        else
          ...feed.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PrayerCard(prayer: p, onTap: () => onOpenPrayer(p)),
            ),
          ),
        const SizedBox(height: 12),
        if (!isPlus) _PlusBanner(onTap: onOpenPaywall),
      ],
    );
  }
}

class _FreezeTokensChip extends StatelessWidget {
  final int tokens;

  const _FreezeTokensChip({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.ac_unit, size: 16, color: AppColors.tealDeep),
          const SizedBox(width: 4),
          Text(
            '$tokens',
            style: AppTypography.caption.copyWith(
              color: AppColors.tealDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner de "prueba social" honesta en el inicio: si [prayingNowEstimate]
/// es `null` (todavia no hay backend real que agregue usuarios activos, ver
/// `CommunityStatsService`), muestra un copy generico y verdadero en vez de
/// inventar un numero (evita el patron oscuro de prueba social falsa).
class _SocialProofBanner extends StatelessWidget {
  final int? prayingNowEstimate;

  const _SocialProofBanner({required this.prayingNowEstimate});

  @override
  Widget build(BuildContext context) {
    final estimate = prayingNowEstimate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tealLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, size: 18, color: AppColors.tealDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              estimate != null
                  ? '$estimate personas orando en este momento'
                  : 'Cada día, muchas personas usan Ora Ahora para hacer una '
                      'pausa y orar.',
              style: AppTypography.caption.copyWith(color: AppColors.tealDeep),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PlusBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.amberLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: AppColors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conoce Ora Ahora Plus', style: AppTypography.title),
                  Text(
                    'Apps ilimitadas en Pausa y Ora, fichas de congelación y más.',
                    style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _FeedData {
  final Prayer oracionDelDia;
  final List<Prayer> feed;
  final int? prayingNowEstimate;

  const _FeedData({
    required this.oracionDelDia,
    required this.feed,
    required this.prayingNowEstimate,
  });
}

/// Overlay breve mostrado al alcanzar un nuevo hito de racha (ver
/// `StreakService.milestones`/`pendingMilestone`). Se descarta al tocar en
/// cualquier parte de la pantalla. Ahora entra con una animacion organica
/// de "rebote" (`Curves.elasticOut` en la escala) en vez de aparecer sin
/// transicion.
class _MilestoneCelebrationOverlay extends StatefulWidget {
  final int milestone;
  final VoidCallback onDismiss;

  const _MilestoneCelebrationOverlay({
    required this.milestone,
    required this.onDismiss,
  });

  @override
  State<_MilestoneCelebrationOverlay> createState() =>
      _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState
    extends State<_MilestoneCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // La escala usa `elasticOut` (rebote organico) para que la celebracion
    // se sienta como un pequeño festejo, no como un dialogo mas.
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    // El fundido del velo oscuro usa una curva sin rebote, y solo ocupa el
    // primer 40% de la duracion (aparece rapido, luego el rebote de la
    // tarjeta sigue un poco mas).
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.celebration, size: 48, color: AppColors.amber),
                    const SizedBox(height: 16),
                    Text(
                      StreakService.milestoneMessage(widget.milestone),
                      textAlign: TextAlign.center,
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: widget.onDismiss,
                      child: const Text('¡Gracias, Dios!'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
