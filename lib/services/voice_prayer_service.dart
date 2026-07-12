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
/// boton manual de "Marcar como orada hoy", sin mostrar dialogos de error
/// ni insistirle a la persona.
///
/// LIMITE CONOCIDO (no se puede verificar sin un telefono real, ver
/// README.md): si el dispositivo no tiene descargado el modelo de voz
/// offline (comun en equipos antiguos, ROMs personalizadas, o telefonos
/// sin los servicios de voz de Google), Android puede: (a) devolver
/// `false` ya en `initialize()`, (b) permitir `initialize()` pero fallar
/// silenciosamente al pedir `listen(onDevice: true)`, o (c) escuchar pero
/// no reconocer ninguna palabra. Los tres casos se tratan igual aqui: se
/// considera que la deteccion por voz no esta disponible y se recurre al
/// boton manual.
class VoicePrayerService {
  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  bool _available = false;

  void Function(String recognizedWords)? _onPartialResult;
  void Function({required bool success})? _onDone;

  bool get isListening => _speech.isListening;

  /// Inicializa el motor de reconocimiento de voz nativo (una sola vez
  /// por instancia) y devuelve si hay reconocimiento de voz disponible en
  /// este telefono en terminos generales. Es una condicion necesaria pero
  /// no 100% suficiente para el reconocimiento en el dispositivo (algunos
  /// equipos reportan disponibilidad general pero no tienen el modelo
  /// offline descargado; eso solo se puede confirmar al intentar escuchar
  /// de verdad, ver [startListening]). Nunca lanza excepciones: cualquier
  /// error de la plataforma se trata como "no disponible" para no romper
  /// la pantalla de Ajustes ni la de la oracion.
  Future<bool> checkAvailability() async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize(
        onError: (error) => _onDone?.call(success: false),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _onDone?.call(success: true);
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
  /// [onPartialResult] se llama con el texto reconocido hasta el momento
  /// cada vez que el motor actualiza su hipotesis (para mostrarlo en
  /// pantalla). [onDone] se llama cuando el motor deja de escuchar por
  /// cualquier motivo que no sea una llamada explicita a [stopListening]
  /// (p. ej. silencio prolongado, error, o no disponibilidad), con
  /// `success: false` si fue por un error para que la pantalla se
  /// degrade en silencio.
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
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _onPartialResult?.call(result.recognizedWords);
        },
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        onDevice: true,
      );
      return true;
    } catch (_) {
      _onDone?.call(success: false);
      return false;
    }
  }

  /// Detiene la escucha de forma deliberada (por ejemplo, porque ya se
  /// detecto "amén" o la persona toco "Cancelar"). Limpia los callbacks
  /// antes de detener para que el `onStatus`/`onError` posterior de
  /// `speech_to_text` no vuelva a invocar [onDone] con informacion ya
  /// obsoleta.
  Future<void> stopListening() async {
    _onPartialResult = null;
    _onDone = null;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Libera los callbacks y cancela cualquier escucha en curso. Se llama
  /// desde `dispose()` de la pantalla que usa este servicio.
  void dispose() {
    _onPartialResult = null;
    _onDone = null;
    if (_speech.isListening) {
      _speech.cancel();
    }
  }
}
