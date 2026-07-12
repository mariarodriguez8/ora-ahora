# Ora Ahora

App de oración cristiana interdenominacional en español, con la función diferencial **"Pausa y Ora"**: en vez de solo bloquear apps que distraen (Instagram, TikTok, juegos...), invita a una breve pausa de oración antes de abrirlas.

Este proyecto fue escrito a mano, archivo por archivo, en un entorno **sin acceso a internet ni a Flutter/Android SDK instalados**. Nunca se ejecutó `flutter create`, `flutter pub get`, `flutter analyze` ni `flutter build`. Todo el código fue verificado por lectura cuidadosa (ver sección "Qué se verificó" más abajo), pero **debes ejecutar el proyecto localmente antes de confiar en que compila sin errores.**

## Requisitos

- Flutter estable (canal `stable`), Dart \>= 3.3, Flutter \>= 3.22 recomendado (se usan algunas APIs relativamente recientes, ver nota de versiones abajo).  
- Android Studio (para SDK de Android, emulador y firma de la app).  
- Un dispositivo o emulador Android real para probar "Pausa y Ora" (el Accessibility Service **no se puede probar sin un dispositivo/emulador encendido**, ver más abajo).

## Primeros pasos

cd ora\_ahora

\# 1\. Trae las dependencias declaradas en pubspec.yaml

flutter pub get

\# 2\. Revisa que no haya errores estáticos

flutter analyze

\# 3\. Corre la app en un emulador o dispositivo conectado

flutter run

\# 4\. Genera el App Bundle para subir a Play Console

flutter build appbundle \--release

### Sobre `android/gradlew`, `gradlew.bat` y `gradle-wrapper.jar`

Este entorno no pudo generar los scripts binarios del *Gradle Wrapper* (`gradlew`, `gradlew.bat`, `gradle-wrapper.jar`), ya que son archivos generados automáticamente por `flutter create` / Android Studio, no código que se deba escribir a mano. **La primera vez que abras `android/` en Android Studio, o corras `flutter pub get` / `flutter run` desde la raíz del proyecto, Flutter/Android Studio los regenerará automáticamente.** Si por alguna razón no aparecen, corre `flutter create .` en la raíz del proyecto (es una operación no destructiva: solo rellena archivos de scaffolding faltantes, no borra tu código) o abre el proyecto en Android Studio y deja que sincronice Gradle.

También falta `android/local.properties` (contiene rutas específicas de tu máquina, como `flutter.sdk` y `sdk.dir`) — Android Studio lo crea solo al abrir el proyecto.

## Cómo probar la función "Pausa y Ora" (Accessibility Service)

1. Corre la app en un dispositivo/emulador real (Android 8+ recomendado).  
2. Completa el onboarding y ve a **Ajustes \> Apps con pausa de oración**.  
3. Activa el interruptor "Activar Pausa y Ora": te llevará primero a la pantalla explicativa (`GateExplainerScreen`) y luego al Intent nativo `android.settings.ACCESSIBILITY_SETTINGS`, donde debes activar manualmente "Ora Ahora" en la lista de servicios de Accesibilidad.  
4. Vuelve a la app, marca 1 app instalada (o varias, si activaste el plan Plus de prueba) para que quede en la lista de apps "gateadas".  
5. Sal de Ora Ahora y abre la app que elegiste: debería aparecer `PrayerGateActivity` encima, con una oración, la guía de respiración y, tras 10 segundos, el botón "Continuar a la app".

**Esto no se pudo probar en este entorno** (no hay emulador ni dispositivo disponible aquí). Es la parte más sensible del proyecto porque depende de comportamiento real de Android (AccessibilityService, ciclo de vida de actividades, `SharedPreferences` compartidas entre Kotlin y Flutter) que solo se puede validar en un dispositivo/emulador real con Android Studio.

## Cómo probar la detección de oración por voz (speech\_to\_text)

1. Ve a **Ajustes \> Voz** y activa "Detectar cuando termino de orar (con micrófono)". Si el interruptor aparece deshabilitado con el subtítulo "No disponible en este dispositivo", significa que `VoicePrayerService.checkAvailability()` no encontró reconocimiento de voz disponible en ese teléfono (ver limitación abajo).  
2. La primera vez, esto te llevará a `VoiceExplainerScreen` (aviso previo en español) y luego pedirá el permiso runtime `RECORD_AUDIO` (lo pide el propio paquete `speech_to_text` dentro de `initialize()`).  
3. Abre cualquier oración (`PrayerDetailScreen`) y deberías ver el botón adicional "Escuchar mi oración" junto al botón manual "Marcar como orada hoy" (el manual sigue siempre visible).  
4. Tócalo y ora en voz alta: deberías ver el ícono de micrófono pulsando y el texto parcial reconocido. Di "amén" al final, o sigue hablando de forma continua por \~70% de la duración estimada de la oración, y debería confirmarse automáticamente (mismo efecto que el botón manual: actualiza la racha).

**Esto tampoco se pudo probar en este entorno** (sin dispositivo físico ni acceso a internet/pub.dev). Es, si acaso, más sensible a variaciones de hardware que "Pausa y Ora": la disponibilidad real del reconocimiento **en el dispositivo** (`onDevice: true`) depende de si el teléfono concreto tiene descargado el modelo de voz offline de Android/Google, lo cual varía por marca, modelo y región, y no se puede simular ni verificar por lectura de código. Prueba en al menos 2-3 teléfonos distintos (incluyendo alguno más antiguo o con Android sin servicios de Google completos) antes de confiar en que el interruptor se comporta como se espera en todos los casos.

## Checklist para publicar en Google Play

Ya conoces estos puntos de tu investigación previa, aquí quedan como lista accionable:

- [ ] Pagar la cuota única de registro de Google Play Console (USD $25).  
- [ ] Si tu cuenta de desarrollador es nueva/personal, completar el programa de **pruebas cerradas de 14 días con al menos 12 testers** antes de poder publicar en producción (requisito reciente de Google Play para cuentas nuevas).  
- [ ] Publicar una **política de privacidad real** en una URL pública y reemplazar el texto de marcador de posición en `lib/screens/settings/privacy_screen.dart`.  
- [ ] Completar el **formulario de seguridad de datos** (Data Safety) en Play Console, siendo honestos sobre qué datos se guardan (todo es local en este MVP) y sobre el uso del permiso de Accesibilidad.  
- [ ] Declarar honestamente en el formulario de Data Safety el uso del permiso `RECORD_AUDIO` (función opcional de detección de oración por voz, ver `VoicePrayerService`): el audio se procesa 100% en el dispositivo (reconocimiento on-device de Android), nunca se sube ni se comparte con terceros, y la app no graba ni guarda archivos de audio en ningún momento.  
- [ ] Declarar explícitamente el uso de la **Accessibility API** en Play Console (formulario de declaración de permisos sensibles) explicando el caso de uso de "Pausa y Ora" — Google revisa esto manualmente y puede tardar más que una revisión estándar.  
- [ ] Reemplazar la firma de `release` en `android/app/build.gradle` (hoy usa la clave de debug) por un keystore de producción real.  
- [x] Ícono de la app: reemplazado. `ic_launcher.png` en las 5 densidades (`mipmap-mdpi` a `mipmap-xxxhdpi`) ahora usan el diseño real (manos en oración estilizadas, silueta azul marino `#1C1D37` sobre círculo crema, con un punto ámbar cálido arriba), generado a partir de un concepto aprobado por el cliente y renderizado localmente con PIL (sin depender de internet). Verificado: los 5 PNG son válidos, con las dimensiones correctas (48/72/96/144/192 px) y aún legibles a tamaño mínimo. Sigue pendiente, antes de publicar: revisar cómo se ve en un lanzador real (los lanzadores Android recortan el ícono en círculo/squircle según el fabricante) y, si se quiere pulir más, migrar a un ícono adaptativo (`mipmap-anydpi-v26` con capas foreground/background separadas) — hoy usa el esquema clásico de ícono único, que es válido pero menos flexible. También está `store_assets/icon_512.png` (512×512, PNG de 32 bits con alfa, 48 KB) listo para subir como ícono de la ficha en Play Console.  
- [ ] Configurar los productos de suscripción reales en Play Console ($4.99/mes y $39.99/año son precios de ejemplo) e integrar RevenueCat o Play Billing en `lib/services/purchase_service.dart` (hoy es un stub funcional, ver TODOs en ese archivo).  
- [ ] Probar "Pausa y Ora" en al menos 2-3 dispositivos/marcas distintas (Samsung, Xiaomi, etc. suelen tener restricciones agresivas de batería que pueden matar servicios de Accesibilidad en segundo plano; puede requerir pedirle al usuario que desactive la optimización de batería para Ora Ahora).  
- [ ] Para conseguir los 12 testers de las pruebas cerradas: usa tu red de contactos/colegas en Bogotá (deben mantener la app instalada los 14 días consecutivos, sin desactivarla, o no cuentan) y, si te hacen falta más, comunidades de intercambio como r/AndroidClosedTesting. No necesitas pagar por esto.

## Qué se verificó manualmente (sin compilador disponible)

- Todos los archivos `.dart` (32 archivos): cada `import` relativo resuelve a un archivo real; cada clase/método del proyecto referenciado desde otro archivo existe con el nombre y firma esperados (verificado con scripts de análisis estático simples, no con el analizador de Dart real).  
    
- Todos los `Provider`/`ChangeNotifierProvider` registrados en `main.dart` coinciden exactamente con los tipos que se piden vía `context.read<T>()`/`context.watch<T>()` en el resto de la app.  
    
- Los 42 registros de `assets/data/prayers_es.json` son JSON válido (parseado con `json.load`), con las 6 claves requeridas cada uno, sin IDs duplicados y con conteo de palabras entre 60-150 en `texto`.  
    
- Los 9 archivos `.xml` de Android (manifest, layout, estilos, colores, accessibility config) son XML bien formado (parseado con `xml.etree.ElementTree`).  
    
- Cada `android:id`, `@style`, `@color`, `@drawable`, `@string`, `@mipmap` y `@xml` referenciado desde el manifest, los layouts o el Kotlin coincide con un recurso realmente definido.  
    
- Los 5 archivos `ic_launcher.png` son PNGs válidos (verificado con `file` y lectura de cabecera IHDR), aunque son solo un cuadrado de color sólido (ver checklist de publicación).  
    
- Se corrigieron 2 errores reales encontrados en esta revisión:  
    
  1. `home_screen.dart` tenía una referencia muerta a una clase `PurchaseGate` que nunca existió (código muerto dentro de un `if` que no hacía nada) — eliminada.  
  2. `journal_repository.dart` declaraba `static const _uuid = Uuid();`, pero el constructor de `Uuid` (paquete `uuid`) **no es `const`** — esto habría sido un error de compilación. Se cambió a `static final`.


- Lectura cuidadosa línea por línea de los 3 archivos Kotlin (`MainActivity.kt`, `PrayerGateAccessibilityService.kt`, `PrayerGateActivity.kt`) verificando balance de llaves, tipos de `findViewById`, nombres de constantes de Android (`Settings.Secure.*`, `AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED`, `Intent.FLAG_ACTIVITY_NEW_TASK`, etc.) contra mi conocimiento de la API de Android, y consistencia de las claves de `SharedPreferences` compartidas con el lado Flutter.  
    
- **Pase de diseño visual (ilustraciones \+ jerarquía \+ animación \+ tipografía, ver `assets/illustrations/`)**: los 7 archivos `.svg` nuevos se parsearon con `xml.etree.ElementTree` (bien formados) y se revisó a mano que cada `viewBox` sea consistente con las coordenadas usadas, que cada `polygon points` tenga pares `x,y` válidos y que cada atributo numérico (`x`, `y`, `width`, `height`, `cx`, `cy`, `r`, `rx`, `ry`) parsee como número. Todos usan solo `rect`/`circle`/`ellipse`/ `polygon` y un par de `path` con únicamente comandos `M`/`L` (líneas rectas, sin curvas Bézier) para minimizar el riesgo de un `d` mal formado sin poder renderizarlo. Se verificó que cada ruta `assets/illustrations/*.svg` referenciada desde Dart (`faith_tree_widget.dart`, `onboarding_welcome_screen.dart`, `journal_screen.dart`, `paywall_screen.dart`) coincide exactamente con un archivo real y con una entrada en `pubspec.yaml` → `flutter.assets`. `pubspec.yaml` se volvió a parsear con `pyyaml` después de los cambios para confirmar que sigue siendo YAML válido. Se relevó cada uso de `AppTypography` en el proyecto para confirmar que el refinamiento de la escala tipográfica (tamaños/pesos/`letterSpacing`) no cambió ningún nombre de campo existente (`display`/`headline`/`title`/`body`/`bodyLarge`/`caption`), así que ningún call site necesitó cambios.

## Lo que NO se pudo verificar (requiere que lo corras tú)

Sin `flutter`/`dart`/Android SDK/emulador instalados en este entorno, lo siguiente **no se ejecutó ni se puede garantizar al 100%** hasta que tú corras:

- `flutter pub get` — para confirmar que todas las versiones de paquetes en `pubspec.yaml` existen tal cual en pub.dev y son compatibles entre sí (ver lista de versiones abajo; las escribí de memoria, sin poder consultar pub.dev).  
- `flutter analyze` — para atrapar cualquier error de tipos, null-safety o API que mi lectura manual no haya detectado (especialmente en las APIs más nuevas de Flutter usadas: `Color.withValues`, `CardThemeData`, `WidgetStateProperty`, `NavigationBar`/`NavigationDestination`).  
- `flutter build apk` / `flutter build appbundle` — para confirmar que Gradle resuelve todas las dependencias nativas (`device_apps`, `flutter_local_notifications`, `flutter_timezone`) sin conflictos de `minSdkVersion` o de *manifest merger*.  
- **Cualquier comportamiento real del `PrayerGateAccessibilityService`** en un dispositivo/emulador: detección del evento de ventana, lectura de `SharedPreferences` compartidas entre Flutter y Kotlin, lanzamiento de `PrayerGateActivity`, y el comportamiento de fabricantes con gestión de batería agresiva (Xiaomi, Samsung, Huawei) que a veces matan servicios de Accesibilidad en segundo plano.  
- El disparo real de las notificaciones locales programadas (zona horaria, permisos de Android 13+, comportamiento tras reiniciar el teléfono).  
- **La detección de oración por voz (`VoicePrayerService`, `speech_to_text`)**: no se pudo probar en ningún dispositivo real. En particular, no se pudo confirmar (a) que `initialize()`/`listen(onDevice: true)` tengan exactamente la firma y el comportamiento aquí asumidos en la version de `speech_to_text` que finalmente instale `flutter pub get`, (b) cómo se comporta un teléfono sin el modelo de voz offline descargado (se asume que falla o no reconoce nada, y el código se degrada en silencio a ese caso, pero es una suposición, no algo observado), y (c) el heurístico de "\~70% de la duración estimada sin más de unos segundos de silencio" para auto-confirmar, que es una regla razonable pero no calibrada con audio real.

## Pase de diseño visual (ilustraciones originales, jerarquía, animación, tipografía)

Se hizo un pase completo para que la app se sienta más premium/cálida (pedido explícito de Maria: NO material de marketing, sino las pantallas reales de la app). Sin poder correr un renderizador de SVG ni Flutter en este entorno, **lo siguiente no se pudo confirmar visualmente y depende de que tú lo corras**:

- Que las 7 ilustraciones nuevas (`assets/illustrations/*.svg`) se vean correctamente proporcionadas y centradas dentro de sus contenedores en cada pantalla (el `viewBox`/aspect ratio de cada una se calculó a mano, ver sección de verificación manual arriba, pero un error de proporción visual sutil no se puede detectar sin ver el render real).  
- Que `flutter_svg: ^2.0.10+1` sea la versión correcta/vigente en pub.dev y compatible con el resto de dependencias (escrita de memoria como el resto de la lista de versiones, ver abajo).  
- Las animaciones nuevas (entrada escalonada de las tarjetas del inicio, transición de etapa del Árbol de fe, rebote de la celebración de hito, entrada del hero del onboarding): se revisaron a mano los `AnimationController`/`CurvedAnimation`/`Interval` uno por uno para que los rangos sean válidos (0.0–1.0, `start <= end`) y que las curvas con "overshoot" (`Curves.easeOutBack`, `Curves.elasticOut`) solo se apliquen a valores que toleran exceder el rango 0–1 (`Offset` de un `SlideTransition`, `double` de un `ScaleTransition`), nunca a una opacidad de `FadeTransition` (que sí exige 0.0–1.0 y usa `Curves.easeOutCubic` en su lugar). Pero el *look and feel* real del timing/rebote solo se puede juzgar viéndolo correr en un dispositivo/emulador.  
- El nuevo refinamiento de `AppTypography` (tamaños/pesos/`letterSpacing`) no se probó contra ningún tamaño de pantalla real ni con "Modo Simple" activado (que además escala todo el texto 1.2x vía `TextScaler`, ver `main.dart`) — verificar que no se corte ningún texto en pantallas pequeñas.

## Versiones de paquetes usadas (verificar contra pub.dev)

Escritas de memoria (sin acceso a internet), como vigentes a mediados de 2025\. Confírmalas en pub.dev antes de confiar en ellas:

- `provider: ^6.1.2`  
- `shared_preferences: ^2.2.3`  
- `flutter_local_notifications: ^17.2.2`  
- `timezone: ^0.9.4`  
- `flutter_timezone: ^1.1.0`  
- `path_provider: ^2.1.4`  
- `intl: ^0.19.0`  
- `device_apps: ^2.2.0`  
- `uuid: ^4.4.0`  
- `speech_to_text: ^7.0.0` (nuevo, para la detección de oración por voz; verificar version exacta y compatibilidad con `minSdk 23` en pub.dev)  
- `flutter_svg: ^2.0.10+1` (nuevo, para renderizar las ilustraciones originales de `assets/illustrations/*.svg`; escrito de memoria como cualquier otra version de esta lista, verificar en pub.dev antes de confiar en ella)  
- `cupertino_icons: ^1.0.8`  
- `flutter_lints: ^4.0.0` (dev dependency)

Gradle/AGP/Kotlin usados en `android/`: Android Gradle Plugin 8.3.2, Kotlin 1.9.22, Gradle wrapper 8.6, `compileSdk`/`targetSdk` heredados de Flutter (`flutter.compileSdkVersion` / `flutter.targetSdkVersion`), `minSdk` fijado en 23\.

## Pase de diseño visual, segunda parte (pantallas restantes)

Continuación del pase de diseño visual anterior, esta vez sobre las pantallas que no se habían tocado todavía, para que la sensación "premium" no se quede solo en el inicio:

- **`PrayerDetailScreen`** (`lib/screens/prayer_detail/prayer_detail_screen.dart`): el título, el texto completo, la duración y la referencia bíblica ahora viven dentro de una tarjeta "sagrada" (`_PrayerHeroCard`) con fondo tonal propio (`primaryContainer`/`onPrimaryContainer`/`secondaryContainer` del `ColorScheme` activo, igual que la sección hero del inicio), en vez de texto suelto sobre el fondo blanco de la pantalla. Se agregó una entrada de fundido (`FadeTransition` \+ `Curves.easeOutCubic`, mismo patrón que `home_screen.dart`) sobre toda la pantalla. La sección de detección de oración por voz (`_VoicePrayerSection`) y el botón manual "Marcar como orada hoy" no se modificaron en su lógica, solo se reordenó el espaciado alrededor de la nueva tarjeta. El `State` pasó de `SingleTickerProviderStateMixin` a `TickerProviderStateMixin` porque ahora coexisten dos `AnimationController` (el pulso del micrófono y la entrada nueva).  
- **Ajustes** (`lib/screens/settings/settings_screen.dart`, `appearance_screen.dart`, `gated_apps_screen.dart`): cada fila de `_SettingsTile`/`_VoiceDetectionTile` ahora envuelve su ícono en un círculo tonal (`color.withValues(alpha: 0.12)`) en vez de un ícono suelto, para una fila consistente en toda la pantalla. En Ajustes \> Apariencia, cada tarjeta de paleta (`_PaletteTile`) ahora muestra una franja de vista previa a todo el ancho (los 4 colores de la paleta en cuartos iguales) en vez de los antiguos círculos pequeños tipo chip, para dar una idea más fiel del resultado antes de elegirla. `GatedAppsScreen` ganó un estado vacío mínimo (ícono \+ texto centrado) para el caso extremo de que no se detecten apps instaladas.  
- **`PrayerGateActivity` (nativa, sin Flutter)**: se agregó `android/app/src/main/res/drawable/breathing_glow.xml`, un **vector drawable** de Android (no SVG) escrito a mano con varios círculos concéntricos (`<path>` con arcos, patrón estándar de "dos arcos de 180°" para trazar un círculo completo) en `@color/gate_accent` con opacidad creciente hacia el centro más un núcleo tibio, para dar una sensación de luz suave en vez del óvalo plano anterior (`breathing_circle.xml`, que se dejó intacto pero ya no se referencia). Se actualizó `activity_prayer_gate.xml` para que la `View` de `breathingCircle` use `@drawable/breathing_glow`; la animación de escala en `PrayerGateActivity.kt` (`ObjectAnimator` sobre `SCALE_X`/`SCALE_Y` de la `View`) no cambió, sigue funcionando igual sobre cualquier fondo.  
- **Estados vacíos**: se confirmó que `journal_empty.svg` ya estaba correctamente conectado en `JournalScreen` (pase anterior). Se agregó el estado vacío de `GatedAppsScreen` mencionado arriba (sin ilustración nueva, solo ícono \+ texto, tal como se pidió).

Qué se verificó en este pase (sin compilador disponible, igual que el resto del proyecto):

- Los 9 archivos `.xml` de `android/` (incluyendo el nuevo `breathing_glow.xml`) se volvieron a parsear con `xml.etree.ElementTree` tras los cambios: todos bien formados. Se encontraron y corrigieron 2 bytes nulos (`\x00`) al final de `activity_prayer_gate.xml` que impedían el parseo (probablemente un artefacto de una edición previa, no relacionado con el contenido en sí).  
- Cada referencia `@drawable`/`@color` nueva o modificada (`@drawable/breathing_glow`, `@color/gate_accent` dentro de ese drawable) coincide con un recurso real definido en `res/values/colors.xml` / `res/drawable/`.  
- Los 4 archivos `.dart` tocados se releyeron completos de punta a punta para confirmar balance de llaves/paréntesis, que ningún import quedó sin usar y que ninguna lógica existente (voz, racha, gate, apariencia) se modificó, solo la presentación visual.  
- Se repitió la búsqueda de "orapausa" (nombre antiguo de la app) en todo el proyecto tras estos cambios: sin resultados.

Qué NO se pudo verificar (requiere Flutter/Android Studio real):

- Que la nueva tarjeta `_PrayerHeroCard` se vea bien proporcionada en las 4 paletas de color (`primaryContainer`/`secondaryContainer` cambian de paleta a paleta) y con "Modo Simple" activado (texto 1.2x más grande).  
- El resultado visual real del vector `breathing_glow.xml` (los radios de los círculos concéntricos y el color del núcleo se calcularon a mano, pero un vector drawable solo se puede juzgar viéndolo renderizado en un emulador/dispositivo).  
- Que la franja de vista previa de cada paleta en Ajustes \> Apariencia se vea bien con esquinas redondeadas (`clipBehavior: Clip.hardEdge` en el `Container` exterior) en distintos tamaños de pantalla.

## Estructura del proyecto

ora\_ahora/

  pubspec.yaml

  lib/

    main.dart

    models/            Prayer, JournalEntry, StreakState

    services/          PrefsService, PrayerRepository, StreakService,

                        JournalRepository, NotificationService,

                        PurchaseService, GateService, VoicePrayerService

    screens/           onboarding/, home/, prayer\_detail/, journal/,

                        settings/, paywall/, gate\_explainer/,

                        voice\_explainer/

    widgets/           PrayerCard, StreakBadge, CategoryChip

    theme/             AppColors, AppTypography, AppTheme

  assets/data/prayers\_es.json   (42 oraciones originales, 10 categorías)

  assets/illustrations/          7 ilustraciones SVG originales (dibujadas a

                                 mano): onboarding\_hero, tree\_semilla/brote/

                                 planta\_joven/arbol, journal\_empty, paywall\_hero

  android/

    app/src/main/

      AndroidManifest.xml

      kotlin/com/proqube/oraahora/

        MainActivity.kt

        PrayerGateAccessibilityService.kt

        PrayerGateActivity.kt

      res/xml/accessibility\_service\_config.xml

      res/layout/activity\_prayer\_gate.xml

      res/values/{strings,styles,colors}.xml  
