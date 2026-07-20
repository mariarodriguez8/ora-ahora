#!/usr/bin/env bash
# v16: fix boton notif + espejo profundo + permisos tras compra + ortografia + paywall 3 opciones (prueba/anual/semanal)
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
import '../gate_explainer/gate_explainer_screen.dart';
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
    // Primero el paywall (prueba/compra); SOLO despues se piden los permisos
    // pesados de "Pausa y Ora" (acceso de uso + mostrarse encima).
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GateExplainerScreen()),
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

/// 4. el espejo: no repite los numeros, va al corazon.
class FunnelMirror extends StatelessWidget {
  const FunnelMirror({super.key});
  @override
  Widget build(BuildContext context) {
    return FunnelScreen(
      frase: 'no es que te falte tiempo.\n\nes que el celular siempre pide '
          'primero...\ny Dios espera callado.',
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

cat > 'lib/screens/onboarding/onboarding_reminders_screen.dart' <<'EOF_a9e0c23b'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/notification_service.dart';
import '../../services/prefs_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'onboarding_done_screen.dart';
import 'onboarding_progress_dots.dart';

/// Priming del permiso de notificaciones: primero se explica el beneficio
/// concreto y personal; solo si la persona acepta se dispara el prompt
/// nativo de Android.
class OnboardingRemindersScreen extends StatelessWidget {
  const OnboardingRemindersScreen({super.key});

  void _next(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingDoneScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.read<PrefsService>();
    final nombre = prefs.userName;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const OnboardingTopBar(step: 8),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Te avisamos cuando\nsea tu momento?',
                  style: AppTypography.display.copyWith(fontSize: 28)),
              const SizedBox(height: 12),
              Text(
                'A las ${prefs.morningTime} y a las ${prefs.nightTime} te '
                'mandaremos un recordatorio cortito y amable'
                '${nombre.isEmpty ? '' : ', $nombre'}. '
                'Es lo que más ayuda a no romper la racha 🔥',
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.tealLight),
                ),
                child: Row(
                  children: [
                    const Text('🔔', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '"${nombre.isEmpty ? 'Hola' : nombre}, tu momento '
                        'con Dios te espera 🙏"',
                        style: AppTypography.quote.copyWith(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final notif = context.read<NotificationService>();
                      final ok = await notif.requestPermission();
                      if (ok) {
                        await notif.refreshSchedule(prefs.reminderTimes);
                      }
                    } catch (_) {
                      // Aunque falle el permiso, nunca dejamos a la persona
                      // atascada: seguimos siempre.
                    }
                    if (!context.mounted) return;
                    _next(context);
                  },
                  child: const Text('Sí, recuérdamelo 🔔'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => _next(context),
                  child: Text('Ahora no',
                      style: AppTypography.body
                          .copyWith(color: AppColors.inkSoft)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOF_a9e0c23b

cat > 'lib/screens/paywall/paywall_screen.dart' <<'EOF_93677ff2'
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pantalla de paywall de Ora Ahora Plus.
///
/// Los precios mostrados ($4.99/mes y $39.99/año) son de ejemplo: se
/// deben configurar los productos y precios reales en Google Play
/// Console antes de publicar. Las compras se procesan a traves de
/// `PurchaseService`, que hoy es un stub (ver TODOs alli).
///
/// DISEÑO DEL PAYWALL (paywall "suave", no un patron oscuro):
/// - El plan Anual aparece preseleccionado por defecto (practica estandar
///   de la industria, no oculta el plan Mensual: ambos son visibles y
///   elegibles con un toque).
/// - El precio anual se muestra tambien como equivalente diario
///   ("$39.99 USD/año — equivale a $0.11 USD/día") para dar contexto de
///   valor real, sin ocultar el monto total.
/// - Debajo del boton principal se muestra siempre, de forma clara y
///   visible, "Cancela cuando quieras desde Google Play".
/// - Esta pantalla es una `Scaffold` normal con boton de "atras" del
///   `AppBar`/gesto del sistema: el usuario puede cerrarla en cualquier
///   momento sin ninguna interceptacion ni oferta forzada de reemplazo
///   (deliberadamente NO se implementa ningun "exit drawer" ni mecanismo
///   que intercepte el cierre o el boton atras para insistir con otra
///   oferta antes de dejar salir al usuario).
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PlusPlan _selected = PlusPlan.pruebaAnual;
  bool _loading = false;

  Future<void> _purchase() async {
    setState(() => _loading = true);
    final ok = await context.read<PurchaseService>().purchase(_selected);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido a Ora Ahora Plus!')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    final restored = await context.read<PurchaseService>().restorePurchases();
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(restored
            ? 'Se restauró tu suscripción Plus.'
            : 'No se encontró ninguna suscripción activa.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPlus = context.watch<PurchaseService>().isPlusUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Ora Ahora Plus')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Ilustracion original de "destello premium" (ver
            // `assets/illustrations/paywall_hero.svg`) en reemplazo del
            // icono generico `Icons.workspace_premium`, como elemento
            // dominante de la pantalla.
            Center(
              child: SvgPicture.asset(
                'assets/illustrations/paywall_hero.svg',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PLUS',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.amber),
            ),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final cats = context.read<PrefsService>().preferredCategories;
              final tema = cats.isEmpty
                  ? null
                  : PrayerCategories.displayName(cats.first).toLowerCase();
              return Text(
                tema == null
                    ? 'Lleva tu vida de oración\nmás lejos'
                    : 'Tu plan para\n$tema está listo',
                textAlign: TextAlign.center,
                style: AppTypography.display.copyWith(fontSize: 27),
              );
            }),
            const SizedBox(height: 24),
            const _FeatureRow(
              icon: Icons.lock_open,
              title: 'Apps ilimitadas en Pausa y Ora',
              subtitle: 'El plan gratuito siempre incluye 1 app gratis',
            ),
            const _FeatureRow(
              icon: Icons.ac_unit,
              title: 'Fichas de congelación de racha',
              subtitle: '2 fichas al mes para proteger tu racha si un día se te pasa',
            ),
            const _FeatureRow(
              icon: Icons.headphones,
              title: 'Oraciones narradas en audio',
              subtitle: 'Próximamente',
            ),
            const _FeatureRow(
              icon: Icons.auto_stories,
              title: 'Paquetes de oración exclusivos',
              subtitle: 'Series temáticas para profundizar cada mes',
            ),
            const SizedBox(height: 24),
            if (isPlus)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 10),
                    Expanded(child: Text('Ya eres miembro de Ora Ahora Plus')),
                  ],
                ),
              )
            else ...[
              _PlanOption(
                plan: PlusPlan.pruebaAnual,
                title: 'Prueba 3 días gratis',
                price: PurchaseService.textoPrueba,
                badge: 'Sin pago hoy',
                selected: _selected == PlusPlan.pruebaAnual,
                onTap: () => setState(() => _selected = PlusPlan.pruebaAnual),
              ),
              const SizedBox(height: 12),
              _PlanOption(
                plan: PlusPlan.anual,
                title: 'Anual',
                price: PurchaseService.precioAnual,
                priceSubtitle: PurchaseService.precioAnualDiario,
                badge: 'Ahorra más',
                selected: _selected == PlusPlan.anual,
                onTap: () => setState(() => _selected = PlusPlan.anual),
              ),
              const SizedBox(height: 12),
              _PlanOption(
                plan: PlusPlan.semanal,
                title: 'Semanal',
                price: PurchaseService.precioSemanal,
                selected: _selected == PlusPlan.semanal,
                onTap: () => setState(() => _selected = PlusPlan.semanal),
              ),
              const SizedBox(height: 8),
              Text(
                'Precios de ejemplo. Los precios finales se configuran en '
                'Google Play Console y pueden variar según tu país.',
                style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _purchase,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_selected == PlusPlan.pruebaAnual
                          ? 'Empezar prueba gratis'
                          : 'Continuar'),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Cancela cuando quieras desde Google Play. Sin compromiso.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : _restore,
                  child: const Text('Restaurar compras'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.tealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.tealDeep, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.title),
                Text(subtitle, style: AppTypography.body.copyWith(color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final PlusPlan plan;
  final String title;
  final String price;
  final String? priceSubtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.plan,
    required this.title,
    required this.price,
    this.priceSubtitle,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.tealDeep : AppColors.tealLight,
            width: selected ? 2 : 1,
          ),
          color: selected ? AppColors.tealLight.withValues(alpha: 0.3) : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: AppColors.tealDeep,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Text(title, style: AppTypography.title),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: AppTypography.caption.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: AppTypography.title),
                if (priceSubtitle != null)
                  Text(
                    priceSubtitle!,
                    style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
EOF_93677ff2

cat > 'lib/services/purchase_service.dart' <<'EOF_42871159'
import 'package:flutter/foundation.dart';

import 'prefs_service.dart';

/// Planes disponibles de Ora Ahora Plus.
enum PlusPlan { pruebaAnual, anual, semanal }

/// Servicio de compras "stub" para el MVP.
///
/// IMPORTANTE: esto NO procesa pagos reales todavia. Sirve para que toda la
/// pantalla de paywall y la logica de "usuario Plus" funcionen de extremo a
/// extremo en el MVP, dejando un unico punto de integracion futuro.
///
/// TODO: integrar RevenueCat (recomendado, simplifica recibos/validacion en
/// ambas tiendas) o directamente Play Billing Library a traves del paquete
/// `in_app_purchase` / `in_app_purchase_android`. Esa integracion requiere:
///   1. Crear los productos de suscripcion en Play Console (IDs, precios).
///   2. Configurar RevenueCat (o Billing) con esos IDs de producto.
///   3. Reemplazar los metodos `purchase*` de esta clase para llamar al SDK
///      real y reemplazar `restorePurchases` para consultar el estado real
///      de la suscripcion en la tienda.
///   4. Mantener `_prefs.setIsPlusUser` como la fuente de verdad local que
///      lee el resto de la app (para no tener que tocar las pantallas).
class PurchaseService extends ChangeNotifier {
  final PrefsService _prefs;

  PurchaseService(this._prefs);

  bool get isPlusUser => _prefs.isPlusUser;

  // Precios de EJEMPLO (Maria puede cambiarlos; deben coincidir con los
  // productos configurados en Play Console).
  static const precioAnual = r'$39.99 USD/año';
  static const precioSemanal = r'$4.99 USD/semana';
  static const precioAnualDiario = r'equivale a $0.11 USD/día';
  // La prueba gratis dura 3 dias y al terminar cobra el plan ANUAL.
  static const textoPrueba = r'3 días gratis, luego $39.99 USD/año';

  /// Simula la compra del plan mensual. En producción esto debe abrir el
  /// flujo de compra nativo de Google Play a través de RevenueCat/Billing.
  Future<bool> purchase(PlusPlan plan) async {
    // TODO: integrar RevenueCat o Play Billing aqui. Por ahora, simulamos
    // una compra exitosa localmente para poder probar el resto del flujo
    // (paywall -> desbloqueo de funciones Plus) sin backend de pagos.
    await Future.delayed(const Duration(milliseconds: 400));
    await _prefs.setIsPlusUser(true);
    notifyListeners();
    return true;
  }

  /// Simula restaurar compras anteriores (normalmente consultaria la tienda
  /// o RevenueCat). En el MVP solo respeta el estado local ya guardado.
  Future<bool> restorePurchases() async {
    // TODO: reemplazar por una consulta real a RevenueCat/Play Billing.
    await Future.delayed(const Duration(milliseconds: 300));
    notifyListeners();
    return isPlusUser;
  }

  /// Utilidad para pruebas manuales durante el desarrollo: revierte el
  /// estado Plus. No debe exponerse en una build de producción final.
  Future<void> debugResetPlus() async {
    await _prefs.setIsPlusUser(false);
    notifyListeners();
  }
}
EOF_42871159

echo LISTO_V16
