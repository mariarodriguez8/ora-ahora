/// Representa una oracion / devocional corto del catalogo local de Ora Ahora.
///
/// Las categorias usan claves internas en ASCII (sin tildes) para que el
/// filtrado sea identico y sin ambiguedad tanto en Dart como en el codigo
/// nativo Kotlin (ver [PrayerCategories]). Los textos que se muestran al
/// usuario si usan tildes y enye normales en espanol.
class Prayer {
  final String id;
  final String categoria;
  final String titulo;
  final String texto;
  final String referenciaBiblica;
  final int duracionEstimadaMin;

  const Prayer({
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.texto,
    required this.referenciaBiblica,
    required this.duracionEstimadaMin,
  });

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      id: json['id'] as String,
      categoria: json['categoria'] as String,
      titulo: json['titulo'] as String,
      texto: json['texto'] as String,
      referenciaBiblica: json['referencia_biblica'] as String,
      duracionEstimadaMin: (json['duracion_estimada_min'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoria': categoria,
      'titulo': titulo,
      'texto': texto,
      'referencia_biblica': referenciaBiblica,
      'duracion_estimada_min': duracionEstimadaMin,
    };
  }
}

/// Claves de categoria (ASCII, estables) usadas en todo el proyecto
/// (JSON de datos, preferencias de onboarding, filtro nativo del gate).
class PrayerCategories {
  static const manana = 'manana';
  static const noche = 'noche';
  static const ansiedad = 'ansiedad';
  static const gratitud = 'gratitud';
  static const familia = 'familia';
  static const trabajo = 'trabajo';
  static const tentacionEnfoque = 'tentacion_enfoque';
  static const sanidad = 'sanidad';
  static const perdon = 'perdon';
  static const duelo = 'duelo';
  static const soledad = 'soledad';
  static const matrimonio = 'matrimonio';
  static const finanzas = 'finanzas';
  static const paz = 'paz';

  static const List<String> all = [
    manana,
    noche,
    ansiedad,
    gratitud,
    familia,
    trabajo,
    tentacionEnfoque,
    sanidad,
    perdon,
    duelo,
    soledad,
    matrimonio,
    finanzas,
    paz,
  ];

  /// Nombre legible en espanol para mostrar en la interfaz.
  static String displayName(String categoria) {
    switch (categoria) {
      case manana:
        return 'Mañana';
      case noche:
        return 'Noche';
      case ansiedad:
        return 'Ansiedad';
      case gratitud:
        return 'Gratitud';
      case familia:
        return 'Familia';
      case trabajo:
        return 'Trabajo';
      case tentacionEnfoque:
        return 'Tentación y enfoque';
      case sanidad:
        return 'Sanidad';
      case perdon:
        return 'Perdón';
      case duelo:
        return 'Duelo';
      case soledad:
        return 'Soledad';
      case matrimonio:
        return 'Matrimonio y pareja';
      case finanzas:
        return 'Finanzas y provisión';
      case paz:
        return 'Paz interior';
      default:
        return categoria;
    }
  }

  /// Emoji de cada categoria (v11d): los MISMOS que usa el onboarding,
  /// para que toda la app hable igual (Ajustes > Mis intereses incluido).
  static String emojiFor(String categoria) {
    switch (categoria) {
      case manana:
        return '🌅';
      case noche:
        return '😴';
      case ansiedad:
        return '😟';
      case gratitud:
        return '🙌';
      case familia:
        return '👨‍👩‍👧';
      case trabajo:
        return '💼';
      case tentacionEnfoque:
        return '📵';
      case sanidad:
        return '🌿';
      case perdon:
        return '🤝';
      case duelo:
        return '🕯️';
      case soledad:
        return '🫂';
      case matrimonio:
        return '💛';
      case finanzas:
        return '🪙';
      case paz:
        return '🕊️';
      default:
        return '🙏';
    }
  }
}
