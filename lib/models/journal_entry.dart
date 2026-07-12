/// Una entrada del diario de oracion del usuario (intenciones / peticiones).
///
/// Se guarda localmente en un archivo JSON (ver `JournalRepository`), de
/// forma que en el futuro se pueda migrar a `sqflite` sin cambiar el resto
/// de la app: solo habria que reescribir el repositorio.
class JournalEntry {
  final String id;
  final DateTime fecha;
  final String texto;
  final bool respondida;
  final DateTime? fechaRespuesta;
  final String? notaRespuesta;

  const JournalEntry({
    required this.id,
    required this.fecha,
    required this.texto,
    this.respondida = false,
    this.fechaRespuesta,
    this.notaRespuesta,
  });

  JournalEntry copyWith({
    String? texto,
    bool? respondida,
    DateTime? fechaRespuesta,
    String? notaRespuesta,
  }) {
    return JournalEntry(
      id: id,
      fecha: fecha,
      texto: texto ?? this.texto,
      respondida: respondida ?? this.respondida,
      fechaRespuesta: fechaRespuesta ?? this.fechaRespuesta,
      notaRespuesta: notaRespuesta ?? this.notaRespuesta,
    );
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      texto: json['texto'] as String,
      respondida: json['respondida'] as bool? ?? false,
      fechaRespuesta: json['fecha_respuesta'] != null
          ? DateTime.parse(json['fecha_respuesta'] as String)
          : null,
      notaRespuesta: json['nota_respuesta'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'texto': texto,
      'respondida': respondida,
      'fecha_respuesta': fechaRespuesta?.toIso8601String(),
      'nota_respuesta': notaRespuesta,
    };
  }
}
