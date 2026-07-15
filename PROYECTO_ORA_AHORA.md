# ORA AHORA — Documento maestro del proyecto
*(Para retomar este proyecto en cualquier conversación nueva con Claude: lee este documento completo ANTES de tocar nada.)*

## 1. Qué es
App Android en **Flutter** de oración **cristiana (NO católica: sin santos, sin María, sin rosario)** en español, de Maria (mariarodriguez8). Objetivo: publicarla en Play Store y que sea la mejor app cristiana — "obsesiva" (uso diario), con interfaz "hiper grabable" para UGC/TikTok.

Funciones: oración del día · 152 oraciones locales en 14 categorías · racha + árbol de fe que crece con minutos acumulados · diario · orar en voz alta con verificación real (compara lo dicho contra el texto) · **"Pausa y Ora"** (única en el mercado: intercepta apps distractoras vía servicio de Accesibilidad nativo Kotlin y propone orar antes de abrirlas) · paywall suave "Plus".

## 2. Dónde vive todo
- **Repo:** `github.com/mariarodriguez8/ora-ahora` (a veces público temporalmente; debe volver a privado).
- **Compilación:** GitHub Codespace "expert dollop" del repo (Flutter 3.44 ya configurado y parchado). Maria NO programa: todo se hace por ella.
- **Estado actual: v5 compilada y pusheada** (commit "v5"). Los scripts `apply_redesign.sh`, `apply_v2..v5.sh` en la raíz son históricos (cada versión se entregó como script autocontenido); el código fuente en `lib/` ya los tiene aplicados.

### Estructura del código
```
lib/
  main.dart                    # MultiProvider + MaterialApp (locale es, delegates)
  models/prayer.dart           # Prayer + PrayerCategories (14 claves ASCII)
  services/                    # prefs, streak (racha+minutos), prayer_repository,
                               # notification, gate (MethodChannel accesibilidad),
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
APK renombrado a `.zip` para descargar → renombrar a `.apk` en el teléfono → instalar. **Android 13+ bloquea Accesibilidad a apps instaladas por APK** ("Configuración restringida"): se desbloquea en Ajustes → Aplicaciones → Ora Ahora → menú ⋮ → "Permitir configuración restringida". Esto desaparece al publicar en Play Store.

## 5. PENDIENTES INMEDIATOS (hacer en este orden)
0. **`bash apply_logo.sh`** en el Codespace (logo nuevo ya decidido, ver sección 6) y verificar que el ícono cambió en el APK.
1. **Pantalla 1 del onboarding aburrida**: rehacerla nivel "WOW" inspirada en las primeras pantallas de las apps top actuales (movimiento, emoción, no un SVG + texto).
2. **Coherencia oración↔tema elegido**: eligió "duelo/pérdida" y la primera oración salió de ansiedad. La primera oración y el feed deben respetar la PRIMERA categoría elegida (hoy `onboarding_first_prayer_screen._load()` ordena todo el pool por duración y toma la más corta).
3. **Overlay "Amén"** (le encanta): al tocarlo debe AVANZAR directo a la siguiente pantalla, sin segundo botón "Continuar".
4. **Pantalla del nombre**: "Continuar" con campo vacío NO debe avanzar — vibrar el campo; vacío solo con "Prefiero no decirlo".
5. **GateExplainer**: tras conceder Accesibilidad, el botón "Ya activé el permiso" no aparece/no refresca; toca "Volver" para salir. Arreglar detección al volver (didChangeAppLifecycleState ya existe, revisar) + CTA visible.
6. **Micrófono AÚN sin contexto**: la hoja de priming no aparece (sospecha: flags `voiceDisclosureSeen`/`micPrimingDone` persistidos por backup de instalación anterior). Basar el priming en el PERMISO REAL (checar RECORD_AUDIO/`hasPermission` de speech_to_text), no en flags guardados. Y **una sola pregunta**, no doble (hoja + explainer duplican).
7. **UI de escucha del micrófono**: grande, central, con ondas/pulso "escuchando", integrada a la pantalla (no una sección abajo). Debe ser ultra-llamativa: se grabarán TikToks con esto.
8. Añadir al GateExplainer el paso de "Configuración restringida" (sección 4).

## 6. Backlog estratégico (decidido con investigación)
- **Play Store**: migrar "Pausa y Ora" de Accesibilidad → "Acceso de uso" + overlay (Google rechaza Accesibilidad para esto) · build release firmado · política de privacidad URL · formularios Play Console · cuenta developer $25.
- **Logo: DECIDIDO** — "Halo + cruz + amanecer" estilo 2026 (aro de luz dorado con cruz luminosa pequeña y resplandor de amanecer, sobre degradado índigo→esmeralda). Los PNGs finales (5 mipmaps + icon_512) están en `apply_logo.sh` en la raíz del repo: **correrlo en el Codespace es el PRIMER paso de la próxima sesión** (`bash apply_logo.sh`), antes de compilar. También conviene rediseñar el splash/launch para que combine con el degradado nuevo.
- Investigación completa (Cal AI 33 pantallas, paywall tras quiz 5x, Coconote UGC, Hallow) ya hecha: onboarding largo ✓ (11 pantallas), falta: widget de pantalla de inicio, retos ("Ora40"), compañeros de oración, anti-churn 7 días extra, notificaciones emocionales con nombre.
- Backend futuro (cuentas/nube/comunidad): hoy TODO es local/offline (racha se pierde al desinstalar).
- Paywall se mantiene SUAVE por decisión de Maria; 2 oraciones gratis en feed + resto candado.

## 7. Cómo retomar en conversación nueva
1. Lee este documento y `PLAY_STORE_LISTING.md` del repo.
2. Clona el repo (pedir a Maria hacerlo público 2 min, o leerlo vía su Chrome logueado).
3. Trabaja los pendientes de la sección 5 en orden; empaqueta como `apply_vN.sh` (heredocs de archivos completos + binarios en base64, autocontenido e idempotente, probado contra copia limpia).
4. Sube el script por github.com/upload (file_upload del navegador), córrelo en el Codespace, compila, sirve la descarga con http.server, y commit+push al final.
5. Estilo de trabajo con Maria: español, directa, no técnica, aprecia listas claras y que se le pregunte poco pero decisiones de negocio son SUYAS (paywall, logo, precios). Verificación estática siempre antes de compilar (balance de llaves, imports, frases católicas prohibidas).
