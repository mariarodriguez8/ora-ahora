import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/prayer.dart';
import '../../services/community_stats_service.dart';
import '../../services/gate_service.dart';
import '../../services/prayer_repository.dart';
import '../../services/appearance_service.dart';
import '../../services/prefs_service.dart';
import '../../services/purchase_service.dart';
import '../../services/route_observer.dart';
import '../../services/streak_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_palettes.dart';
import '../../theme/app_typography.dart';
import '../../widgets/plant_hero.dart';
import '../../widgets/prayer_card.dart';
import '../gate_explainer/gate_explainer_screen.dart';
import '../journal/journal_screen.dart';
import '../paywall/paywall_screen.dart';
import '../themes/theme_prayers_screen.dart';
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
    // Paso 1: se abre el paywall (prueba/compra).
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
    if (!mounted) return;
    // Paso 2: JUSTO despues del paywall —COMPRE O NO— se piden los permisos de
    // "Pausa y Ora" (acceso de uso + mostrarse encima) si aun faltan. Antes
    // esto solo ocurria si el usuario compraba, y por eso a veces "faltaban"
    // los permisos. Ahora se piden siempre, aqui, de forma garantizada.
    final gate = context.read<GateService>();
    final tienePermisos = await gate.hasAllGatePermissions();
    if (!mounted || tienePermisos) return;
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
            label: 'Peticiones',
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
                      PlantHero(
                        streak: streak.currentStreak,
                        prayedToday: streak.prayedToday,
                        daysSinceLastPrayed: streak.daysSinceLastPrayed ?? 0,
                        isPlus: isPlus,
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
                    // 4. v17: "¿Algo te pesa hoy?" — carpetas de temas
                    // (reemplaza el "chorro" de oraciones sueltas) + banner
                    // Plus. Cada carpeta abre SOLO las oraciones de ese tema.
                    _staggeredSection(
                      _TemasSection(
                        preferredCategories:
                            context.read<PrefsService>().preferredCategories,
                        isPlus: isPlus,
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
                          'petición en tus Peticiones o explora "Para ti".'
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

/// v17 — "¿Algo te pesa hoy?": en vez del "chorro" de oraciones sueltas,
/// el inicio muestra CARPETAS de temas (emoji + nombre). Se muestran los
/// temas que la persona eligio en el onboarding (o un set inicial util si
/// no eligio ninguno) y un boton "Ver todos los temas". Cada carpeta abre
/// la [ThemePrayersScreen] con SOLO las oraciones de ese tema. Inspirado
/// en como organizan Glorify/Abide su contenido por estado de animo/tema.
class _TemasSection extends StatelessWidget {
  final List<String> preferredCategories;
  final bool isPlus;
  final VoidCallback onOpenPaywall;

  const _TemasSection({
    required this.preferredCategories,
    required this.isPlus,
    required this.onOpenPaywall,
  });

  @override
  Widget build(BuildContext context) {
    final temas = preferredCategories.isNotEmpty
        ? preferredCategories.take(6).toList()
        : const [
            PrayerCategories.ansiedad,
            PrayerCategories.familia,
            PrayerCategories.gratitud,
            PrayerCategories.paz,
            PrayerCategories.finanzas,
            PrayerCategories.perdon,
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lo que sientes hoy tiene oración.',
            style: AppTypography.headline),
        const SizedBox(height: 4),
        Text(
          'Toca el tema que más te pesa.',
          style: AppTypography.body.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.55,
          children: [
            for (final c in temas) ThemeFolderCard(categoria: c),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AllThemesScreen()),
            ),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('Ver todos los temas'),
          ),
        ),
        const SizedBox(height: 16),
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
