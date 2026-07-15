#!/usr/bin/env bash
# apply_v9.sh — ORA AHORA v9: firma de release para Play Store.
# Escribe archivos completos; idempotente. Uso: bash apply_v9.sh
set -euo pipefail
test -f pubspec.yaml || { echo "Corre desde la raíz del repo"; exit 1; }

cat > 'android/app/build.gradle' <<'EOF_V9_0'
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

// Firma de release (v9): si existe android/key.properties (creado por
// crear_llave_release.sh, NUNCA subido a git), se firma con el keystore
// propio; si no existe, se usa la clave de debug para no romper builds
// de prueba. Play Store exige la firma propia.
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.withReader('UTF-8') { reader ->
        keystoreProperties.load(reader)
    }
}

android {
    namespace "com.proqube.oraahora"
    compileSdk flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId "com.proqube.oraahora"
        // flutter_local_notifications y device_apps funcionan desde API 21,
        // pero se fija 23 para simplificar el manejo de permisos en tiempo
        // de ejecucion (Android 6.0+) usados por "Pausa y Ora".
        minSdkVersion flutter.minSdkVersion
        targetSdk flutter.targetSdkVersion
        versionCode flutter.versionCode
        versionName flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            release {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            signingConfig(keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug)
        }
    }
}

flutter {
    source "../.."
}

dependencies {
    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.4"
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.22"
}
EOF_V9_0

cat > 'crear_llave_release.sh' <<'EOF_V9_1'
#!/usr/bin/env bash
# =====================================================================
# crear_llave_release.sh — Crea la llave de firma de Ora Ahora.
# LA CORRE MARIA (una sola vez). La contraseña la escribes TÚ y debes
# guardarla en un lugar seguro PARA SIEMPRE: sin ella no se puede
# actualizar la app en Play Store nunca más.
# Uso: bash crear_llave_release.sh   (desde la raíz del repo)
# =====================================================================
set -euo pipefail
test -f pubspec.yaml || { echo "Corre esto desde la raíz del repo"; exit 1; }
KS=android/keystore-ora-ahora.jks
if [ -f "$KS" ]; then
  echo "✅ La llave ya existe ($KS). No hay que hacer nada."
  exit 0
fi
echo "Vas a crear la llave de firma de Ora Ahora."
echo "⚠️  Elige una contraseña y GUÁRDALA (papel seguro o gestor de contraseñas)."
echo "    Si se pierde, NO podrás actualizar la app en Play Store."
echo ""
read -r -s -p "Contraseña (mínimo 6 caracteres): " P1; echo ""
read -r -s -p "Repítela: " P2; echo ""
if [ "$P1" != "$P2" ]; then echo "❌ No coinciden. Vuelve a correr el script."; exit 1; fi
if [ "${#P1}" -lt 6 ]; then echo "❌ Muy corta (mínimo 6). Vuelve a correr el script."; exit 1; fi
keytool -genkeypair -v -keystore "$KS" -alias oraahora \
  -keyalg RSA -keysize 2048 -validity 10950 \
  -storepass "$P1" -keypass "$P1" \
  -dname "CN=Ora Ahora, O=Ora Ahora, C=CO"
cat > android/key.properties <<KP
storePassword=$P1
keyPassword=$P1
keyAlias=oraahora
storeFile=../keystore-ora-ahora.jks
KP
echo ""
echo "✅ Llave creada y configurada. (keystore y key.properties están en"
echo "   .gitignore: NUNCA se suben a GitHub.)"
echo "Siguiente paso: avísale a Claude para compilar el .aab de release."
EOF_V9_1

cat > '.gitignore' <<'EOF_V9_2'
.dart_tool/
.packages
.pub-cache/
.pub/
build/
.flutter-plugins
.flutter-plugins-dependencies
.metadata
*.iml
*.g.dart
.idea/
android/.gradle/
android/captures/
android/gradlew
android/gradlew.bat
android/local.properties
android/**/GeneratedPluginRegistrant.java
android/key.properties
*.jks
*.keystore
android/key.properties
android/keystore-ora-ahora.jks
*.jks
EOF_V9_2

cat > 'PROYECTO_ORA_AHORA.md' <<'EOF_V9_3'
# ORA AHORA — Documento maestro del proyecto
*(Para retomar este proyecto en cualquier conversación nueva con Claude: lee este documento completo ANTES de tocar nada.)*

## 1. Qué es
App Android en **Flutter** de oración **cristiana (NO católica: sin santos, sin María, sin rosario)** en español, de Maria (mariarodriguez8). Objetivo: publicarla en Play Store y que sea la mejor app cristiana — "obsesiva" (uso diario), con interfaz "hiper grabable" para UGC/TikTok.

Funciones: oración del día · 152 oraciones locales en 14 categorías · racha + árbol de fe que crece con minutos acumulados · diario · orar en voz alta con verificación real (compara lo dicho contra el texto) · **"Pausa y Ora"** (única en el mercado: intercepta apps distractoras vía servicio de Accesibilidad nativo Kotlin y propone orar antes de abrirlas) · paywall suave "Plus".

## 2. Dónde vive todo
- **Repo:** `github.com/mariarodriguez8/ora-ahora` (a veces público temporalmente; debe volver a privado).
- **Compilación:** GitHub Codespace "expert dollop" del repo (Flutter 3.44 ya configurado y parchado). Maria NO programa: todo se hace por ella.
- **Estado actual: v8 — migración Play Store** ("Pausa y Ora" ya NO usa Accesibilidad: ahora usa Acceso de uso + overlay, ver sección 6). v7 y v8 fueron probadas y aprobadas por Maria. v9: firma de release configurada (build.gradle lee android/key.properties si existe; si no, debug). La llave la crea Maria con `bash crear_llave_release.sh` (contraseña SOLO de Maria, keystore y key.properties en .gitignore). Con la llave creada: `flutter build appbundle --release` para el .aab de Play Store. Los scripts `apply_*.sh` en la raíz son históricos; el código fuente en `lib/` ya los tiene todo aplicado. Logo nuevo YA aplicado en mipmaps + store icon.

### Estructura del código
```
lib/
  main.dart                    # MultiProvider + MaterialApp (locale es, delegates)
  models/prayer.dart           # Prayer + PrayerCategories (14 claves ASCII)
  services/                    # prefs, streak (racha+minutos), prayer_repository,
                               # notification, gate (MethodChannel permisos v8),
                               # voice_prayer (speech_to_text on-device), purchase (stub)
  screens/onboarding/          # 11 pantallas: welcome→name→categories→times→plan→
                               # social→first_prayer→commitment→reminders→gate→done
  screens/home/                # saludo con nombre + mini-semilla + oración del día +
                               # feed "Para ti" (2 gratis, resto candado 🔒→paywall)
  screens/prayer_detail/       # página devocional serif + orar en voz alta
  screens/{journal,settings,paywall,gate_explainer,voice_explainer}/
  widgets/                     # prayer_card, faith_tree, streak_badge,
                               # time_wheel_picker, amen_celebration (overlay dorado)
  theme/                       # app_colors, app_typography, app_theme, app_palettes
assets/data/prayers_es.json    # 152 oraciones (ids categoria_NN)
assets/fonts/                  # Fraunces (serif títulos/oraciones) + Figtree (UI), OFL
android/.../oraahora/          # MainActivity + PrayerGate{AccessibilityService,
                               # Activity,ForegroundService}.kt (nativo)
store_assets/icon_512.png      # ícono tienda
```

### Diseño "Santuario"
Papel marfil `#F7F3EA` · verde abeto `#16342B` · dorado `#8A5F27/#D9B37C` · serif Fraunces + sans Figtree · 4 paletas en Ajustes (Bosque y Lino default, Amanecer, Oliva y Salvia, Vigilia oscura), contrastes WCAG AA verificados. Copy humano, cálido, apto para personas mayores, con emojis moderados. **Cuidado doctrinal:** nada litúrgico-católico (se eliminó "la paz sea contigo"); cruz VACÍA sí es símbolo evangélico.

## 3. Cómo compilar y entregar (flujo probado)
1. Cambios → commit/push al repo (o script `apply_vN.sh` subido por github.com/upload).
2. En el Codespace: `git pull && flutter analyze && flutter build apk --debug`
   (solo son aceptables avisos *info*; hoy ~66).
3. `cp build/app/outputs/flutter-apk/app-debug.apk .../ora-ahora.apk.zip`
4. Descarga: el download de VS Code web falla con archivos grandes → levantar
   `python3 -m http.server 9200` en la carpeta del APK y bajar desde
   `https://<codespace>-9200.app.github.dev/` en el navegador de Maria.
5. El Codespace se duerme por inactividad cada pocos minutos: reiniciar y reintentar.

### Parches de entorno YA aplicados (no repetir, pero saber que existen)
Gradle wrapper 8.9 · AGP 8.7.3 · coreLibraryDesugaring 2.1.4 · gradle.properties con -Xmx2G y workers.max=2 (la máquina tiene 7.8GB y el daemon moría) · Kotlin `setPriority(...)` en ForegroundService · `intl: ^0.20.2` · **device_apps 2.2.0 necesita namespace inyectado en el pub-cache tras cada `flutter pub get` limpio:**
`sed -i "s/android {/android {\n    namespace 'fr.g123k.deviceapps'/" /root/.pub-cache/hosted/pub.dev/device_apps-2.2.0/android/build.gradle`

## 4. Instalación en el teléfono de Maria (tester)
APK renombrado a `.zip` para descargar → renombrar a `.apk` en el teléfono → instalar. Desde v8 ya no se usa Accesibilidad, así que la "Configuración restringida" de Android 13+ NO debería aparecer (aplicaba a Accesibilidad). "Acceso de uso" y "Mostrar sobre otras apps" se activan normal en Ajustes, la app te lleva directo.

## 5. HECHO EN v6/v7 (feedback de Maria ya resuelto) + PENDIENTES

### Resuelto y compilado (no rehacer):
✅ Logo "halo+cruz+amanecer" aplicado (mipmaps + store icon) · ✅ Bienvenida WOW con degradado índigo→esmeralda y halo/cruz de luz animados · ✅ Onboarding de 11 pantallas con quiz, "preparando tu plan", testimonio, primera oración, pantalla de micrófono con contexto, pacto, recordatorios, Pausa y Ora · ✅ Coherencia oración↔tema (oración del día y primera oración salen del PRIMER tema elegido; feed ordenado por temas) · ✅ Overlay "Amén" dorado a pantalla completa que avanza solo · ✅ Campo de nombre vibra/sacude si está vacío · ✅ Botón "ya activé el permiso" responde siempre (celebra y cierra, o explica qué falta) + fallback nativo por packageName + guía de "Configuración restringida" · ✅ Micrófono: permiso basado en estado REAL del sistema, una sola pregunta, motor siempre inicializado antes de escuchar (bug "no lee" corregido) · ✅ UI de escucha: mic dorado gigante con ondas y degradado, oración compactada · ✅ 2 oraciones gratis + candados → paywall personalizado con el tema del quiz · ✅ Orar varias veces al día suma minutos al árbol · ✅ Mini-semilla con progreso junto a la racha.

### Pendientes reales:
1. Maria debe PROBAR v7 en su teléfono y reportar (especialmente: voz leyendo la oración, botón de permiso, coherencia de temas).
2. ✅ HECHO EN v8: migración a "Acceso de uso" + overlay (PrayerGateForegroundService.kt ahora sondea UsageStatsManager con la pantalla encendida; PrayerGateAccessibilityService.kt eliminado; GateBootReceiver rearranca tras reinicio; MainActivity/GateService con métodos nuevos: openUsageAccessSettings, openOverlaySettings, hasUsageAccess, hasOverlayPermission, syncGateService; GateExplainerScreen rediseñada con 2 tarjetas de permiso). PROBADA Y APROBADA por Maria.
3. Ideas de retención aún no implementadas: widget de pantalla de inicio, retos "Ora40", compañeros de oración, anti-churn, notificaciones con nombre.
4. Splash/launch screen aún es marfil plano — armonizarlo con el degradado del logo.

## 6. Backlog estratégico (decidido con investigación)
- **Play Store**: ✅ migración "Pausa y Ora" Accesibilidad → "Acceso de uso" + overlay HECHA en v8. Quedan: build release firmado · política de privacidad URL · formularios Play Console · cuenta developer $25.
- **Logo: DECIDIDO** — "Halo + cruz + amanecer" estilo 2026 (aro de luz dorado con cruz luminosa pequeña y resplandor de amanecer, sobre degradado índigo→esmeralda). **YA APLICADO en v6** (mipmaps + icon_512 en el código). Solo falta armonizar el splash/launch con el degradado nuevo.
- Investigación completa (Cal AI 33 pantallas, paywall tras quiz 5x, Coconote UGC, Hallow) ya hecha: onboarding largo ✓ (11 pantallas), falta: widget de pantalla de inicio, retos ("Ora40"), compañeros de oración, anti-churn 7 días extra, notificaciones emocionales con nombre.
- Backend futuro (cuentas/nube/comunidad): hoy TODO es local/offline (racha se pierde al desinstalar).
- Paywall se mantiene SUAVE por decisión de Maria; 2 oraciones gratis en feed + resto candado.

## 7. Cómo retomar en conversación nueva
1. Lee este documento y `PLAY_STORE_LISTING.md` del repo.
2. Clona el repo (pedir a Maria hacerlo público 2 min, o leerlo vía su Chrome logueado).
3. Trabaja los pendientes de la sección 5 en orden; empaqueta como `apply_vN.sh` (heredocs de archivos completos + binarios en base64, autocontenido e idempotente, probado contra copia limpia).
4. Sube el script por github.com/upload (file_upload del navegador), córrelo en el Codespace, compila, sirve la descarga con http.server, y commit+push al final.
5. Estilo de trabajo con Maria: español, directa, no técnica, aprecia listas claras y que se le pregunte poco pero decisiones de negocio son SUYAS (paywall, logo, precios). Verificación estática siempre antes de compilar (balance de llaves, imports, frases católicas prohibidas).
EOF_V9_3

chmod +x crear_llave_release.sh
echo "v9 aplicada. Maria: corre  bash crear_llave_release.sh  y elige tu contraseña."
