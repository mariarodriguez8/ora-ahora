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

## 8. v11 APROBADA: rediseno narrativo "Tu caminar con el Pastor" (PENDIENTE de construir)
Narrativa columna vertebral (aprobada por Maria 16-jul-2026, ICP: cristianos 25-35):
- La ovejita ERES TU (Juan 10:27), presentada DESDE EL ONBOARDING. NUNCA representa a Cristo. SIEMPRE FELIZ/sonriente (pedido explicito); ojos cerrados solo un instante al amen. En pantalla de voz: SOLO LA CABEZA asomada abajo.
- Home = pradera del Salmo 23 que florece con minutos orados (arbol de fe + arroyo + ovejita). Numero GIGANTE de racha como heroe + anillo de minutos del dia. Estilo: "Santuario energizado" (paleta intacta, tarjetas blancas limpias, gamificacion profunda, NO clonar apps genericas).
- Racha = dias caminando con el Pastor. Racha rota = oveja perdida (Lucas 15): notificacion "El deja las 99 y viene por ti", volver se CELEBRA, nunca culpa.
- Pausa y Ora = "La Puerta del Redil" (Juan 10 "Yo soy la puerta"): pantalla completa al abrir app elegida (gracia 20 min, max ~6/dia luego version mini, "hoy no" existente); boton dorado "Mejor no entro" = VICTORIA celebrada y contada ("El Pastor te cuido N veces hoy").
- NUEVO: burbuja overlay a los ~20 min de uso continuo dentro de la app (mismo detector UsageStats): ovejita "Seguimos aqui? Hay pastos mas verdes" con Orar 30 seg / 10 min mas. Invita, no bloquea.
- Notificacion inteligente pre-habito (base ya existe: usage_pattern_log) + resumen nocturno ("Hoy la Puerta te cuido 4 veces").
- Retos = senderos (Sendero de la gratitud 7 dias, Ora40) con insignias. Nueva pestana stats = mapa del camino (barras semanales + anillo).
- Bocetos aprobados en la conversacion (home, mic con cabeza de oveja, Puerta del Redil, notificaciones).
NOTA v10b: bug microfono corregido (sesion logica auto-reiniciable en voice_prayer_service.dart; Android corta su reconocedor cada 30-60s e ignora listenFor).
