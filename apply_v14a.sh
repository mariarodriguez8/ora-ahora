#!/usr/bin/env bash
# v14a: embudo emocional nuevo (8 pantallas guion cocina) + modo noche Plus
set -euo pipefail
[ -f pubspec.yaml ] || exit 1

cat > 'lib/screens/home/home_screen.dart' <<'EOF_3d2c8f75'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/community_stats_service.dart';
import '../../services/prayer_repository.dart';
import '../../services/appearance_service.dart';
import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/route_observer.dart';
import '../../services/streak_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_palettes.dart';
import '../../theme/app_typography.dart';
import '../../widgets/meadow_hero.dart';
import '../../widgets/prayer_card.dart';
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
/// `_staggeredSection`), con una curva organica en vez del aparecer seco
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
    // congelación (solo aplica si el usuario es Plus), asi la pradera
    // muestra el conteo correcto sin que el usuario tenga que orar
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
    // Coherencia: primero las oraciones del primer tema elegido, luego el
    // segundo, etc.
    feed.sort((a, b) => categories
        .indexOf(a.categoria)
        .compareTo(categories.indexOf(b.categoria)));

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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // 0. Encabezado calido: saludo segun la hora del dia,
                    // ahora mas liviano (la racha y el arbol viven en la
                    // pradera de abajo, no aqui).
                    _staggeredSection(
                      SafeArea(
                        bottom: false,
                        child: _GreetingHeader(
                          nombre: context.read<PrefsService>().userName,
                        ),
                      ),
                      start: 0.0,
                      end: 0.45,
                    ),
                    const SizedBox(height: 16),
                    // 1. HERO v11: la pradera del Salmo 23 — numero
                    // gigante de racha ("dias caminando con el Pastor"),
                    // anillo de minutos del dia, arbol de fe, arroyo,
                    // flores que crecen con los minutos orados y la
                    // ovejita (que eres tu).
                    _staggeredSection(
                      MeadowHero(
                        streak: streak.currentStreak,
                        atRisk: streak.streakAtRisk,
                        prayedToday: streak.prayedToday,
                        minutesToday: streak.minutesToday,
                        cumulativeMinutes: streak.cumulativeMinutes,
                        sheepLost: (streak.daysSinceLastPrayed ?? 0) >= 2,
                        freezeTokens: (isPlus && streak.freezeTokens > 0)
                            ? streak.freezeTokens
                            : null,
                      ),
                      start: 0.05,
                      end: 0.6,
                    ),
                    const SizedBox(height: 14),
                    // 1b. v11d: guia clara de que hacer hoy (pedido de
                    // Maria: "no queda claro que tengo que hacer").
                    _staggeredSection(
                      _NextStepCard(
                        prayedToday: streak.prayedToday,
                        onOrar: () => _openDetail(data.oracionDelDia),
                      ),
                      start: 0.1,
                      end: 0.65,
                    ),
                    const SizedBox(height: 24),
                    // 2. La oracion del dia, ahora segunda en jerarquia
                    // visual despues de la pradera (sigue siendo la
                    // accion principal del dia).
                    _staggeredSection(
                      _HeroPrayerSection(
                        prayer: data.oracionDelDia,
                        onTap: () => _openDetail(data.oracionDelDia),
                      ),
                      start: 0.15,
                      end: 0.75,
                    ),
                    const SizedBox(height: 16),
                    // 3. Prueba social honesta.
                    _staggeredSection(
                      _SocialProofBanner(
                        prayingNowEstimate: data.prayingNowEstimate,
                      ),
                      start: 0.3,
                      end: 0.85,
                    ),
                    const SizedBox(height: 28),
                    // 4. Feed personalizado + banner Plus.
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
                      start: 0.4,
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

/// Tarjeta-guia del dia (v11d): le dice a la persona exactamente cual es
/// su siguiente paso. Si aun no oro hoy, invita a la oracion del dia (y
/// tocarla la abre); si ya oro, sugiere el diario o el feed, sin presion.
class _NextStepCard extends StatelessWidget {
  final bool prayedToday;
  final VoidCallback onOrar;

  const _NextStepCard({required this.prayedToday, required this.onOrar});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: prayedToday ? null : onOrar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Text(
                prayedToday ? '✨' : '👉',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  prayedToday
                      ? 'Ya oraste hoy. Si quieres más, escribe una '
                          'intención en tu Diario o explora "Para ti".'
                      : 'Tu paso de hoy: ora la oración del día. '
                          'Toma 2 minutos — toca aquí.',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (!prayedToday)
                Icon(Icons.chevron_right, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encabezado calido del inicio: avatar de la ovejita, fecha en español y
/// saludo serif segun la hora del dia. Desde v11 es deliberadamente
/// liviano: la racha, el arbol y los minutos viven en la pradera
/// (`MeadowHero`), no aqui.
class _GreetingHeader extends StatelessWidget {
  final String nombre;

  const _GreetingHeader({required this.nombre});

  String get _saludo {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hoy = DateTime.now();
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final fecha =
        '${dias[hoy.weekday - 1]}, ${hoy.day} de ${meses[hoy.month - 1]}';

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipOval(
              child: Container(
                width: 48,
                height: 48,
                color: scheme.primaryContainer,
                padding: const EdgeInsets.all(5),
                child: Image.asset(
                  'assets/mascot/ovejita.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fecha.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre.isEmpty ? _saludo : '$_saludo, $nombre 🌅',
                  style: AppTypography.display.copyWith(
                    fontSize: 24,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const _NightModeCorner(),
        ],
      ),
    );
  }
}

/// Boton de esquina dia/noche 🌙☀️: beneficio VISIBLE de Plus. Los Plus
/// alternan la paleta al toque; los gratis ven la invitacion y el paywall.
class _NightModeCorner extends StatelessWidget {
  const _NightModeCorner();

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceService>();
    final esNoche = appearance.explicitPaletteId == AppPaletteId.maresProfundos;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () async {
        final esPlus = context.read<PurchaseService>().isPlusUser;
        if (esPlus) {
          await appearance.setPalette(esNoche
              ? AppPaletteId.zafiroCalmo
              : AppPaletteId.maresProfundos);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Con Plus eliges día o noche 🌙'),
          ));
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          esNoche ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          size: 18,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Seccion de la oracion del dia: overline dorada + titulo serif + la
/// tarjeta destacada (fondo primario profundo, ver
/// `PrayerCard(destacada: true)`).
class _HeroPrayerSection extends StatelessWidget {
  final Prayer prayer;
  final VoidCallback onTap;

  const _HeroPrayerSection({required this.prayer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 2,
              color: scheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'PARA HOY',
              style: AppTypography.caption.copyWith(color: scheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Oración del día',
          style: AppTypography.headline.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 14),
        PrayerCard(prayer: prayer, destacada: true, onTap: onTap),
      ],
    );
  }
}

/// Feed personalizado ("Para ti") y banner de Plus: tercer nivel de
/// jerarquia, debajo de la pradera y de la oracion del dia.
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
          ...List.generate(feed.length, (i) {
            final p = feed[i];
            final bloqueada = !isPlus && i >= 2;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PrayerCard(
                prayer: p,
                bloqueada: bloqueada,
                insignia: (!isPlus && i == 1) ? '🎙️ Órala en voz alta' : null,
                onTap: bloqueada ? onOpenPaywall : () => onOpenPrayer(p),
              ),
            );
          }),
        const SizedBox(height: 12),
        if (!isPlus) _PlusBanner(onTap: onOpenPaywall),
      ],
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
/// cualquier parte de la pantalla. Entra con una animacion organica
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
                    // v11b: la ovejita celebra el hito contigo (antes era
                    // un icono generico de Material).
                    Image.asset(
                      'assets/mascot/ovejita_celebrando.png',
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
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
EOF_3d2c8f75

cat > 'lib/screens/onboarding/funnel_base.dart' <<'EOF_f7679bc2'
import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

/// Respuestas del embudo emocional (viven solo durante el onboarding).
class FunnelAnswers {
  static String horasCelular = '';
  static String tiempoDios = '';
}

const kFunnelIndigo = Color(0xFF18163A);
const kFunnelEsmeralda = Color(0xFF0A3A30);
const kFunnelDorado = Color(0xFFFFD18C);
const kFunnelMarfil = Color(0xFFF7F3EA);

/// Pantalla del embudo: UNA frase, la ovejita actuando la frase, y
/// opciones grandes. Cero adornos compitiendo con la emocion.
class FunnelScreen extends StatelessWidget {
  final String frase;
  final String? subtitulo;
  final String mascota; // ruta del asset de la ovejita
  final List<(String, VoidCallback)> opciones;
  final bool amanecer; // true = el fondo amanece (momento de gracia)

  const FunnelScreen({
    super.key,
    required this.frase,
    this.subtitulo,
    required this.mascota,
    required this.opciones,
    this.amanecer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: amanecer
                ? [const Color(0xFF2E3A2F), const Color(0xFFB98352)]
                : [kFunnelIndigo, kFunnelEsmeralda],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Center(
                  child: Image.asset(mascota, height: 170,
                      filterQuality: FilterQuality.medium),
                ),
                const Spacer(),
                Text(frase,
                    style: AppTypography.display
                        .copyWith(fontSize: 30, color: kFunnelMarfil)),
                if (subtitulo != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitulo!,
                      style: AppTypography.body.copyWith(
                          color: kFunnelMarfil.withValues(alpha: 0.6))),
                ],
                const SizedBox(height: 24),
                for (final (texto, onTap) in opciones) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            opciones.first.$1 == texto && opciones.length == 1
                                ? kFunnelDorado
                                : kFunnelMarfil.withValues(alpha: 0.94),
                        foregroundColor: const Color(0xFF241F10),
                      ),
                      onPressed: onTap,
                      child: Text(texto, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
EOF_f7679bc2

cat > 'lib/screens/onboarding/funnel_screens.dart' <<'EOF_2c7bfcc6'
import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import 'funnel_base.dart';
import 'onboarding_name_screen.dart';

void _go(BuildContext c, Widget s) =>
    Navigator.of(c).push(MaterialPageRoute(builder: (_) => s));

/// 1. "ahorita oro..."
class FunnelQ1 extends StatelessWidget {
  const FunnelQ1({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        frase: '¿te ha pasado?\ndices "ahorita oro"...\ny se te va el día.',
        mascota: 'assets/mascot/ovejita_pensativa.png',
        opciones: [
          ('todos los días 😔', () => _go(context, const FunnelQ2())),
          ('a veces', () => _go(context, const FunnelQ2())),
          ('casi nunca', () => _go(context, const FunnelQ2())),
        ],
      );
}

/// 2. horas de celular
class FunnelQ2 extends StatelessWidget {
  const FunnelQ2({super.key});
  void _pick(BuildContext c, String v) {
    FunnelAnswers.horasCelular = v;
    _go(c, const FunnelQ3());
  }

  @override
  Widget build(BuildContext context) => FunnelScreen(
        frase: '¿cuánto tiempo pasaste\nayer en el celular?',
        subtitulo: 'sé honesta',
        mascota: 'assets/mascot/ovejita_esperando.png',
        opciones: [
          ('1 o 2 horas', () => _pick(context, '1 o 2 horas')),
          ('3 o 4 horas', () => _pick(context, '3 o 4 horas')),
          ('5 horas o más', () => _pick(context, '5 horas o más')),
        ],
      );
}

/// 3. tiempo a Dios
class FunnelQ3 extends StatelessWidget {
  const FunnelQ3({super.key});
  void _pick(BuildContext c, String v) {
    FunnelAnswers.tiempoDios = v;
    _go(c, const FunnelMirror());
  }

  @override
  Widget build(BuildContext context) => FunnelScreen(
        frase: '¿y cuánto tiempo\nle diste a Dios?',
        mascota: 'assets/mascot/ovejita_orando.png',
        opciones: [
          ('nada 💔', () => _pick(context, 'nada')),
          ('unos minutitos', () => _pick(context, 'unos minutitos')),
          ('media hora o más', () => _pick(context, 'media hora o más')),
        ],
      );
}

/// 4. el espejo (sus propios numeros)
class FunnelMirror extends StatelessWidget {
  const FunnelMirror({super.key});
  @override
  Widget build(BuildContext context) {
    final cel = FunnelAnswers.horasCelular.isEmpty
        ? 'varias horas'
        : FunnelAnswers.horasCelular;
    final dios =
        FunnelAnswers.tiempoDios.isEmpty ? 'casi nada' : FunnelAnswers.tiempoDios;
    return FunnelScreen(
      frase: 'ayer le diste\n$cel al celular...\n\ny $dios a Dios.',
      mascota: 'assets/mascot/ovejita_perdida.png',
      opciones: [
        ('continuar', () => _go(context, const FunnelWins())),
      ],
    );
  }
}

/// 5. la validacion
class FunnelWins extends StatelessWidget {
  const FunnelWins({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        frase: 'y no es que no ames a Dios.\n\nes que el celular\nsiempre gana.',
        mascota: 'assets/mascot/ovejita_pensativa.png',
        opciones: [
          ('así me siento 😔', () => _go(context, const FunnelGrace())),
        ],
      );
}

/// 6. la gracia (el fondo amanece)
class FunnelGrace extends StatelessWidget {
  const FunnelGrace({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        amanecer: true,
        frase: 'la buena noticia:\n\nDios no está enojado contigo.\nestá esperándote.',
        mascota: 'assets/mascot/ovejita_celebrando.png',
        opciones: [
          ('quiero volver a Él 🤍', () => _go(context, const FunnelMinute())),
        ],
      );
}

/// 7. 1 minuto
class FunnelMinute extends StatelessWidget {
  const FunnelMinute({super.key});
  @override
  Widget build(BuildContext context) => FunnelScreen(
        frase: '¿y si empezamos\ncon 1 minuto al día?',
        mascota: 'assets/mascot/ovejita_esperando.png',
        opciones: [
          ('sí, con 1 minuto sí puedo 🙏',
              () => _go(context, const FunnelShame())),
        ],
      );
}

/// 8. la pena de orar en voz alta
class FunnelShame extends StatelessWidget {
  const FunnelShame({super.key});
  void _answer(BuildContext c, bool pena) {
    if (pena) {
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(
        content: Text('tranquila. empieza en susurro. Dios escucha igual 🤍',
            style: AppTypography.body),
        duration: const Duration(seconds: 3),
      ));
    }
    _go(c, const OnboardingNameScreen());
  }

  @override
  Widget build(BuildContext context) => FunnelScreen(
        frase: '¿te da pena orar\nen voz alta?',
        mascota: 'assets/mascot/ovejita_escuchando.png',
        opciones: [
          ('un poquito 🙈', () => _answer(context, true)),
          ('no, para nada', () => _answer(context, false)),
        ],
      );
}
EOF_2c7bfcc6

cat > 'lib/screens/onboarding/onboarding_mic_screen.dart' <<'EOF_d1f399c4'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../services/voice_prayer_service.dart';
import '../../theme/app_typography.dart';
import 'onboarding_reminders_screen.dart';
import 'onboarding_progress_dots.dart';

/// Contexto del microfono DENTRO del onboarding, justo despues de la
/// primera oracion: primero se explica con calma y diseno, y solo si la
/// persona acepta se dispara el dialogo del sistema. Nunca en frio.
class OnboardingMicScreen extends StatefulWidget {
  const OnboardingMicScreen({super.key});

  @override
  State<OnboardingMicScreen> createState() => _OnboardingMicScreenState();
}

class _OnboardingMicScreenState extends State<OnboardingMicScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);
  bool _pidiendo = false;

  static const _dorado = Color(0xFFFFD18C);
  static const _marfil = Color(0xFFF7F3EA);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _next() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingRemindersScreen()),
    );
  }

  Future<void> _pedir() async {
    setState(() => _pidiendo = true);
    final prefs = context.read<PrefsService>();
    final voice = VoicePrayerService();
    final ok = await voice.checkAvailability();
    voice.dispose();
    await prefs.setMicPrimingDone(true);
    await prefs.setVoiceDisclosureSeen(true);
    if (!mounted) return;
    setState(() => _pidiendo = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '¡Listo! Cuando ores en voz alta, te escucho 🙏'
          : 'Sin problema, puedes activarlo luego desde una oración.'),
    ));
    _next();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18163A), Color(0xFF0A3A30)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const OnboardingTopBar(step: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Y si la próxima\nla oramos en voz alta?',
                          style: AppTypography.display
                              .copyWith(fontSize: 28, color: _marfil)),
                      const SizedBox(height: 12),
                      Text(
                        'Cuando ores en voz alta, te escucho y marco la '
                        'oración por ti al terminar. Tu voz se queda en tu '
                        'teléfono: nunca se graba ni se envía a ningún lado.',
                        style: AppTypography.bodyLarge.copyWith(
                            color: _marfil.withValues(alpha: 0.75)),
                      ),
                      const Spacer(),
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, _) {
                            final v = _pulse.value;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                for (final (base, a) in [
                                  (196.0, 0.25),
                                  (156.0, 0.45)
                                ])
                                  Container(
                                    width: base + 34 * v,
                                    height: base + 34 * v,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _dorado.withValues(
                                            alpha: a * (1 - v * 0.55)),
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 116,
                                  height: 116,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFFE7C2),
                                        Color(0xFFFFD18C),
                                        Color(0xFFE2A85B),
                                      ],
                                      stops: [0.0, 0.6, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _dorado.withValues(
                                            alpha: 0.45 + 0.3 * v),
                                        blurRadius: 38 + 16 * v,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.mic_rounded,
                                      size: 56, color: Color(0xFF241F10)),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dorado,
                            foregroundColor: const Color(0xFF241F10),
                          ),
                          onPressed: _pidiendo ? null : _pedir,
                          child: Text(_pidiendo
                              ? 'Activando…'
                              : 'Sí, escúchame orar 🎙️'),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: _next,
                          child: Text('Ahora no',
                              style: TextStyle(
                                  color:
                                      _marfil.withValues(alpha: 0.55))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOF_d1f399c4

cat > 'lib/screens/onboarding/onboarding_times_screen.dart' <<'EOF_a4eeae00'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/time_wheel_picker.dart';
import 'onboarding_first_prayer_screen.dart';
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
    final result = await showTimeWheelPicker(
      context,
      initial: morning ? _morning : _night,
      titulo: morning ? 'Tu oración de la mañana' : 'Tu oración de la noche',
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
      appBar: const OnboardingTopBar(step: 2),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿A qué horas te queda\nbien orar?',
                  style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                'Un momento al despertar y otro antes de dormir. '
                'Toca cada tarjeta para ajustar la hora — luego puedes '
                'cambiarla cuando quieras.',
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 32),
              _TimeTile(
                icon: Icons.wb_sunny_outlined,
                label: 'Al empezar el día',
                time: _fmt(_morning),
                onTap: () => _pick(true),
              ),
              const SizedBox(height: 14),
              _TimeTile(
                icon: Icons.nightlight_round,
                label: 'Antes de dormir',
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
                        builder: (_) => const OnboardingFirstPrayerScreen(),
                      ),
                    );
                  },
                  child: const Text('Continuar'),
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
                decoration: const BoxDecoration(
                  color: AppColors.tealLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.tealDeep, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: AppTypography.title)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  time,
                  style: AppTypography.headline
                      .copyWith(fontSize: 20, color: AppColors.amber),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOF_a4eeae00

cat > 'lib/screens/onboarding/onboarding_welcome_screen.dart' <<'EOF_f44cb358'
import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';
import 'funnel_screens.dart';

/// Bienvenida "WOW" 2026: fondo degradado profundo (como el logo), halo
/// de luz dorado que respira con una CRUZ LUMINOSA (restaurada en v11c),
/// y la ovejita — que eres tu (Juan 10:27) — asomandose desde la esquina
/// inferior derecha de la pantalla, mirando hacia la cruz.
///
/// v11c: se deshace el experimento de v11a de meter a la ovejita DENTRO
/// del halo (el recorte tenia fondo y se veia un rectangulo verde dentro
/// del circulo). La cruz vuelve a ser la protagonista del halo, como
/// estaba antes, y la mascota entra por la esquina con su recorte
/// transparente real (assets/mascot/ovejita_esperando.png, mirando hacia
/// arriba), sin tocar el resto de la composicion.
class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _entrance;

  static const _indigo = Color(0xFF18163A);
  static const _esmeralda = Color(0xFF0A3A30);
  static const _dorado = Color(0xFFFFD18C);
  static const _marfil = Color(0xFFF7F3EA);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Widget _luz(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _dorado.withValues(alpha: opacity),
              blurRadius: size * 0.45,
              spreadRadius: size * 0.08,
            ),
          ],
        ),
      );

  /// Barra redondeada y luminosa (marfil→dorado) para armar la cruz de
  /// luz. [glow] varia con el pulso para que la cruz "respire" junto con
  /// el halo.
  Widget _barraDeLuz({
    required double width,
    required double height,
    required double glow,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_marfil, _dorado],
        ),
        boxShadow: [
          BoxShadow(
            color: _dorado.withValues(alpha: glow),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fadeIn = CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic));
    // La ovejita entra deslizandose desde la esquina, con la misma curva
    // de entrada del resto de la pantalla.
    final sheepIn = CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_indigo, _esmeralda],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Halo con cruz de luz que respira (como antes de v11a)
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final v = 0.92 + 0.08 * _pulse.value;
                          final glow = 0.55 + 0.25 * _pulse.value;
                          return Transform.scale(
                            scale: v,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _luz(210, 0.22 + 0.12 * _pulse.value),
                                Container(
                                  width: 190,
                                  height: 190,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: _marfil, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            _dorado.withValues(alpha: 0.55),
                                        blurRadius: 26,
                                      ),
                                    ],
                                  ),
                                ),
                                // Cruz de luz: brazo vertical + brazo
                                // horizontal un poco por encima del centro.
                                SizedBox(
                                  width: 160,
                                  height: 160,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _barraDeLuz(
                                        width: 13,
                                        height: 96,
                                        glow: glow,
                                      ),
                                      Transform.translate(
                                        offset: const Offset(0, -16),
                                        child: _barraDeLuz(
                                          width: 64,
                                          height: 13,
                                          glow: glow,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: fadeIn,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu momento\ncon Dios,\ntodos los días',
                            style: AppTypography.display
                                .copyWith(fontSize: 38, color: _marfil),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Una oración corta cada día, a tu hora. Y una '
                            'pausa para orar antes de abrir las apps que '
                            'más te distraen. La ovejita eres tú: "Mis '
                            'ovejas oyen mi voz, y me siguen" (Juan 10:27).',
                            style: AppTypography.bodyLarge.copyWith(
                                color: _marfil.withValues(alpha: 0.78)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    // El boton deja aire a la derecha para que la ovejita
                    // de la esquina no lo tape.
                    Padding(
                      padding: const EdgeInsets.only(right: 96),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dorado,
                            foregroundColor: const Color(0xFF241F10),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const FunnelQ1()),
                            );
                          },
                          child: const Text('Comenzar mi camino 🙏'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 96),
                      child: Center(
                        child: Text(
                          'Gratis · Menos de 2 minutos',
                          style: AppTypography.caption.copyWith(
                              color: _marfil.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // La ovejita asoma desde la esquina inferior derecha de la
            // PANTALLA (recorte transparente, mirando hacia la cruz),
            // entrando con un deslizamiento suave.
            Positioned(
              right: 16,
              bottom: 10,
              child: AnimatedBuilder(
                animation: sheepIn,
                builder: (context, child) {
                  final t = sheepIn.value;
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(40 * (1 - t), 0),
                      child: child,
                    ),
                  );
                },
                // v11d: la mascota OFICIAL, completa y sin recortar.
                child: Image.asset(
                  'assets/mascot/ovejita.png',
                  height: 124,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF_f44cb358

echo LISTO_V14A
