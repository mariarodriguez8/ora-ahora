import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Envuelve el paquete `speech_to_text` (que a su vez usa el
/// `SpeechRecognizer` nativo de Android) para la deteccion OPCIONAL,
/// 100% en el dispositivo, de cuando la persona termina de orar en voz
/// alta (ver `PrayerDetailScreen`).
///
/// GARANTIA DE PRIVACIDAD (elegida explicitamente por el cliente, ver
/// `PLAY_STORE_LISTING.md`): este archivo SOLO invoca
/// `SpeechToText.listen(..., onDevice: true)`, que le pide a Android que
/// use unicamente el modelo de reconocimiento de voz descargado en el
/// telefono, sin enviar audio a ningun servidor. No hay ningun codigo en
/// esta clase (ni en el resto del proyecto) que suba audio crudo a un
/// backend, ni ningun modo de "reintentar en la nube" si el
/// reconocimiento en el dispositivo falla: si `onDevice: true` no puede
/// completarse, esta clase simplemente reporta que no hubo exito
/// (`success: false`) y la pantalla que la usa se degrada en silencio al
/// boton manual de "Marcar como orada hoy".
///
/// SESION AUTO-REINICIABLE (v10b, corrige el bug "el microfono se cierra
/// a mitad de la oracion"): el `SpeechRecognizer` de Android tiene un
/// limite interno de sesion (30-60s tipicos) e IGNORA valores grandes de
/// `listenFor`; al llegar a ese limite emite el estado 'done' aunque la
/// persona siga orando. Antes ese 'done' se reportaba como fin de la
/// oracion. Ahora esta clase mantiene una SESION LOGICA por encima de las
/// sesiones fisicas del motor: cuando Android corta, se acumula el texto
/// reconocido y se vuelve a escuchar de inmediato, hasta que (a) la
/// pantalla llama a [stopListening] (p. ej. detecto "amén" o exito), (b)
/// hay silencio real (varios reinicios seguidos sin palabras nuevas), (c)
/// se agota el presupuesto total [listenFor], o (d) hay un error
/// permanente. [onPartialResult] siempre recibe el texto ACUMULADO de
/// todos los segmentos, por lo que la deteccion de "amén" y el heuristico
/// de duracion de la pantalla siguen funcionando sin cambios.
class VoicePrayerService {
  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  bool _available = false;

  void Function(String recognizedWords)? _onPartialResult;
  void Function({required bool success})? _onDone;

  // --- Estado de la sesion logica (ver comentario de clase) ---
  bool _sessionActive = false;
  bool _stopping = false;
  bool _restartPending = false;
  String _accumulated = '';
  String _currentSegment = '';
  int _silentRestarts = 0;
  DateTime _sessionDeadline = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _pauseFor = const Duration(seconds: 8);

  /// Cuantos reinicios seguidos SIN palabras nuevas se toleran antes de
  /// considerar que la persona dejo de hablar de verdad. Con pauseFor=8s
  /// esto equivale a ~25-35s de silencio real.
  static const int _maxSilentRestarts = 3;

  /// Duracion pedida a cada sesion fisica del motor. Por debajo de los
  /// limites internos tipicos de Android para minimizar cortes a mitad
  /// de frase (el corte igual se maneja, esto solo lo hace menos comun).
  static const Duration _segmentListenFor = Duration(seconds: 55);

  static const Duration _restartDelay = Duration(milliseconds: 250);

  bool get isListening => _speech.isListening;

  /// `true` si el sistema YA concedio el permiso de microfono (sin
  /// disparar ningun dialogo). Base del "permission priming" honesto.
  Future<bool> get hasMicPermission async {
    try {
      return await _speech.hasPermission;
    } catch (_) {
      return false;
    }
  }

  /// Inicializa el motor de reconocimiento de voz nativo (una sola vez
  /// por instancia) y devuelve si hay reconocimiento disponible. Nunca
  /// lanza excepciones: cualquier error de la plataforma se trata como
  /// "no disponible" para no romper la pantalla de Ajustes ni la de la
  /// oracion.
  Future<bool> checkAvailability() async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize(
        onError: (error) =>
            _handleEngineStop(permanent: error.permanent),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _handleEngineStop(permanent: false);
          }
        },
        debugLogging: false,
      );
    } catch (_) {
      _available = false;
    }
    _initialized = true;
    return _available;
  }

  /// Empieza a escuchar EXCLUSIVAMENTE con reconocimiento en el
  /// dispositivo (`onDevice: true`, ver comentario de privacidad arriba).
  ///
  /// [onPartialResult] se llama con TODO el texto reconocido en la sesion
  /// logica hasta el momento (acumulado entre reinicios del motor).
  /// [onDone] se llama cuando la sesion logica termina por cualquier
  /// motivo que no sea una llamada explicita a [stopListening], con
  /// `success: false` solo si fue por un error permanente o por no
  /// disponibilidad. [listenFor] es el presupuesto TOTAL de la sesion
  /// logica (no de cada sesion fisica del motor).
  ///
  /// Devuelve `true` si se pudo iniciar la escucha.
  Future<bool> startListening({
    required void Function(String recognizedWords) onPartialResult,
    required void Function({required bool success}) onDone,
    Duration listenFor = const Duration(minutes: 6),
    Duration pauseFor = const Duration(seconds: 8),
  }) async {
    final available = await checkAvailability();
    _onPartialResult = onPartialResult;
    _onDone = onDone;
    if (!available) {
      onDone(success: false);
      return false;
    }
    _sessionActive = true;
    _stopping = false;
    _restartPending = false;
    _accumulated = '';
    _currentSegment = '';
    _silentRestarts = 0;
    _sessionDeadline = DateTime.now().add(listenFor);
    _pauseFor = pauseFor;
    return _beginPhysicalListen();
  }

  String _joinedText() {
    final joined = '$_accumulated $_currentSegment'.trim();
    return joined;
  }

  /// Arranca UNA sesion fisica del motor nativo. Los cortes del motor
  /// llegan por onStatus/onError (ver [checkAvailability]) y se manejan
  /// en [_handleEngineStop].
  Future<bool> _beginPhysicalListen() async {
    _restartPending = false;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (!_sessionActive || _stopping) return;
          _currentSegment = result.recognizedWords;
          if (_currentSegment.trim().isNotEmpty) {
            _silentRestarts = 0;
          }
          _onPartialResult?.call(_joinedText());
        },
        listenFor: _segmentListenFor,
        pauseFor: _pauseFor,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        onDevice: true,
      );
      return true;
    } catch (_) {
      _finishSession(success: false);
      return false;
    }
  }

  /// El motor nativo dejo de escuchar (limite interno, pausa larga o
  /// error). Decide si la sesion logica continua (reinicio) o termina.
  void _handleEngineStop({required bool permanent}) {
    if (!_sessionActive || _stopping || _restartPending) return;

    // Consolida lo reconocido en el segmento que acaba de terminar.
    if (_currentSegment.trim().isNotEmpty) {
      _accumulated = _joinedText();
      _currentSegment = '';
    } else {
      _silentRestarts++;
    }

    final budgetExpired = DateTime.now().isAfter(_sessionDeadline);
    final realSilence = _silentRestarts > _maxSilentRestarts;
    if (permanent || budgetExpired || realSilence) {
      _finishSession(success: !permanent);
      return;
    }

    // Reencender el microfono: pequeño respiro para que el motor nativo
    // libere recursos antes del siguiente listen().
    _restartPending = true;
    Future.delayed(_restartDelay, () {
      if (!_sessionActive || _stopping) return;
      _beginPhysicalListen();
    });
  }

  void _finishSession({required bool success}) {
    if (!_sessionActive) return;
    _sessionActive = false;
    _restartPending = false;
    final onDone = _onDone;
    _onPartialResult = null;
    _onDone = null;
    onDone?.call(success: success);
  }

  /// Detiene la escucha de forma deliberada (por ejemplo, porque ya se
  /// detecto "amén" o la persona toco "Cancelar"). Limpia los callbacks
  /// antes de detener para que el `onStatus`/`onError` posterior de
  /// `speech_to_text` no vuelva a invocar `onDone` con informacion ya
  /// obsoleta.
  Future<void> stopListening() async {
    _stopping = true;
    _sessionActive = false;
    _restartPending = false;
    _onPartialResult = null;
    _onDone = null;
    if (_speech.isListening) {
      await _speech.stop();
    }
    _stopping = false;
  }

  /// Libera los callbacks y cancela cualquier escucha en curso. Se llama
  /// desde `dispose()` de la pantalla que usa este servicio.
  void dispose() {
    _stopping = true;
    _sessionActive = false;
    _restartPending = false;
    _onPartialResult = null;
    _onDone = null;
    if (_speech.isListening) {
      _speech.cancel();
    }
  }
}
