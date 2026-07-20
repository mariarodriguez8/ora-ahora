# ORA AHORA — Documento maestro del proyecto
*(Para retomar este proyecto en cualquier conversación nueva con Claude: lee este documento completo ANTES de tocar nada.)*

## 1. Qué es
App Android en **Flutter** de oración **cristiana (NO católica: sin santos, sin María, sin rosario)** en español, de Maria (mariarodriguez8). Objetivo: publicarla en Play Store y que sea la mejor app cristiana — "obsesiva" (uso diario), con interfaz "hiper grabable" para UGC/TikTok.

Funciones: oración del día · 152 oraciones locales en 14 categorías · racha + árbol de fe que crece con minutos acumulados · diario · orar en voz alta con verificación real (compara lo dicho contra el texto) · **"Pausa y Ora"** (única en el mercado: intercepta apps distractoras vía servicio de Accesibilidad nativo Kotlin y propone orar antes de abrirlas) · paywall suave "Plus".

## 2. Dónde vive todo
- **Repo:** `github.com/mariarodriguez8/ora-ahora` (a veces público temporalmente; debe volver a privado).
- **Compilación:** GitHub Codespace "expert dollop" del repo (Flutter 3.44 ya configurado y parchado). Maria NO programa: todo se hace por ella.
- **Estado actual: v13 pendiente de compilar** (v12 = AAB firmado 1.0.3+4 ya en prueba cerrada de Play). Antes: v8 — migración Play Store ("Pausa y Ora" ya NO usa Accesibilidad: ahora usa Acceso de uso + overlay, ver sección 6). v7 y v8 fueron probadas y aprobadas por Maria. v9: firma de release configurada (build.gradle lee android/key.properties si existe; si no, debug). La llave la crea Maria con `bash crear_llave_release.sh` (contraseña SOLO de Maria, keystore y key.properties en .gitignore). Con la llave creada: `flutter build appbundle --release` para el .aab de Play Store. Los scripts `apply_*.sh` en la raíz son históricos; el código fuente en `lib/` ya los tiene todo aplicado. Logo nuevo YA aplicado en mipmaps + store icon.

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
AJUSTES v11 (Maria, 16-jul): en la burbuja de scroll, "Orar 30 segundos" es SIEMPRE el boton dorado protagonista; "10 min mas" va en gris pequeno y discreto (texto plano, no boton) — la prioridad del producto es que la persona ORE. El tiempo de aparicion de la burbuja es CONFIGURABLE por el usuario en Ajustes > Pausa y Ora: chips 10/15/20/30 min + Personalizado (default 15 min); tambien exponer alli el periodo de gracia de la Puerta (default 20 min, ya existe la pref gate_grace_minutes).
NOTIFICACIONES v11 (rediseno aprobado, estilo top-apps 2026 tipo Duolingo): la ovejita habla en PRIMERA PERSONA, minusculas casual, max 2 lineas, una idea por notificacion, dato personal en el titulo (hora habitual, dias de racha). Carita de la ovejita como LargeIcon con expresion acorde (guino/expectante/esperanzada). Accion directa en la notificacion ("Orar 1 min") via notification action + deep link; una sola accion dorada. Ejemplos aprobados: pre-habito "tu scroll de las 9 p.m. [ojos]" / "llegue primero. 1 minuto y entras, prometido."; racha "12 dias [fuego] y hoy no ha pasado nada" / "30 segundos antes de dormir y seguimos."; oveja perdida "te guarde tu lugar en la pradera" / "sin sermones. volver toma 1 minuto." PROHIBIDO tono corporativo/folleto.
MASCOTA OFICIAL v11 (elegida por Maria, 16-jul): store_assets/ovejita_oficial.jpg — oveja joven caminando con flow relajado, ojos entrecerrados con sonrisa sutil, lana crema con textura granulada, cara/patas carbon, AUDIFONOS dorados al cuello y DIJE DE CRUZ VACIA dorada (reemplaza a la campana). Estilo flat con grano, juvenil 25-35, ni bebe ni corporativa. Todas las expresiones/estados (celebrando, escuchando -solo cabeza en pantalla de voz-, esperando, oveja perdida) se derivan de ESTE personaje usando la imagen como referencia. MONETIZACION: usuarios Plus eligen el COLOR DE LA LANA. MICROFONO v11: boton circular limpio 2026 con ONDA DE AUDIO horizontal animada al ritmo de la voz (referencia apps de traduccion top), no ondas concentricas.

v11a APLICADA (16-jul): LOGO OFICIAL = ovejita asomada sosteniendo el movil con cruz dorada fina brillando (movil_3 con esquinas extendidas a verde full-bleed, store_assets/logo_oficial_fullbleed.png). icon_512.png y los 5 mipmaps ic_launcher REEMPLAZADOS con el logo nuevo. MASCOTA EN LA APP (assets/mascot/ovejita.png, recorte sin fondo): (1) onboarding welcome: ovejita dentro del halo + copy Juan 10:27 "esta ovejita eres tu"; (2) home: avatar circular de la ovejita junto al saludo; (3) gate explainer: la ovejita presenta los 2 permisos. Resto de integraciones (pradera, voz, Puerta, burbuja, notificaciones, expresiones, colores Plus) quedan para la v11 completa.
COLORES PLUS v11 (confirmado): paleta PREDEFINIDA de lanas (crema default, rosada, celeste, lavanda, dorada, carbon) con variantes de la mascota identicas en cada color. EL ICONO DE LA APP CAMBIA con el color elegido via activity-alias de Android (un alias por color con su set de mipmaps; enable/disable con PackageManager.setComponentEnabledSetting; advertir parpadeo breve en algunos launchers). Beneficio Plus visible hacia afuera.


## 9. PLAN MAESTRO v13-v15 (APROBADO POR MARIA 23-jul-2026 — LEY, NO REINTERPRETAR)

### Reglas de lenguaje (INQUEBRANTABLES)
ICP: cristianos evangélicos hispanohablantes, 25-35 núcleo + mayores, NO técnicos. Diccionario permitido: celular, redes, orar, Dios, el Señor, la Biblia, horas, minutos, pena, día. PROHIBIDO: scroll, desbloqueos, apps, notificaciones (en copy visible), pantalla de bloqueo, tecnicismos, lenguaje IA, poesía que necesite explicación. Prueba de fuego: si no se lo dirías a tu hermana en la cocina, NO va. El peso emocional lo pone la conciencia de la persona, no la frase. PROHIBIDO copiar a Prayer Lock (referencia estudiada, pantallas vistas): mismo peso, cero copia.

### v13 (HECHO, compilar): 1) tema SIEMPRE claro salvo elección explícita (bug Huawei textos blancos); 3) recordatorios se reprograman en cada apertura; 18) Amén → popUntil inicio (2 vías). Script: apply_v13.sh. (2: allowBackup ya estaba true; pérdida de datos de testers fue por instalar builds con firmas distintas — no repetir mezcla debug/release.)

### v14 — EMBUDO NUEVO (guion CONGELADO, una frase por pantalla, ovejita animada COHERENTE con el texto en cada una):
1. "¿te ha pasado? dices \'ahorita oro\'... y se te va el día." → todos los días 😔 / a veces / casi nunca
2. "¿cuánto tiempo pasaste ayer en el celular?" (sé honesta) → 1-2 / 3-4 / 5 o más horas
3. "¿y cuánto tiempo le diste a Dios?" → nada 💔 / unos minutitos / media hora o más
4. ESPEJO con sus respuestas: "ayer le diste **X horas** al celular... y **Y** a Dios."
5. "y no es que no ames a Dios. es que el celular siempre gana."
6. GRACIA (fondo amanece): "la buena noticia: Dios no está enojado contigo. está esperándote." (ovejita mira a la luz)
7. "¿y si empezamos con 1 minuto al día?" → botón: "sí, con 1 minuto sí puedo"
8. "¿te da pena orar en voz alta?" → un poquito 🙈 / no → "tranquila. empieza en susurro. Dios escucha igual."
9. nombre → temas → hora → PRIMERA ORACIÓN repetida EN VOZ ALTA con pradera floreciendo → "día 1 con Dios 🐑"
Luego: testimonios + vista previa de notificación → permiso notificaciones → PRUEBA GRATIS 3 días ("ningún pago hoy — te avisamos antes de que termine"; requiere in_app_purchase real + producto en Play Console; purchase_service hoy es stub) → "¿dónde nos conociste?".
PERMISOS: SOLO notificaciones antes de la prueba. Micrófono al primer uso de voz; Acceso de uso + superposición al activar la Puerta — cada uno con UNA pantalla: título claro, 3 líneas honestas, imagen de lo que verá en Ajustes.

### v14 — MODO NOCHE/DÍA como beneficio PLUS (pedido Maria 23-jul):
Botón pequeño en una esquina de la pestaña HOY (icono luna/sol 🌙/☀️). Usuario PLUS: alterna al toque entre paleta clara (Bosque y Lino) y oscura (Vigilia) vía AppearanceService.setExplicitPalette. Usuario gratis: al tocarlo ve mini-aviso "Con Plus eliges día o noche 🌙" → abre paywall. Beneficio Plus VISIBLE (misma filosofía que colores de lana). El default general sigue siendo claro (fix Huawei v13); esto es un toggle explícito, no vuelve al modo sistema.

### v14 — INTERIOR (adiós chorro):
- 3 pestañas: HOY (solo pradera + ovejita + racha gigante + UN botón "Orar ahora") · MI CAMINO (racha, minutos, mapa de calor, hitos + diario integrado como "mis notas con Dios") · LA PUERTA (apps elegidas, tiempos, marcador "hoy la Puerta te cuidó N veces" — victorias, no bloqueos). Ajustes → ícono de perfil.
- FILOSOFÍA ANTI-CATÁLOGO: nunca mostrar lista de 152 oraciones. La app pregunta "¿qué llevas en el corazón hoy?" → tema → sirve UNA oración. Consejería, no biblioteca.

### v15 — EXPERIENCIAS ESTRELLA:
- "REPITE CONMIGO" (eco): flutter_tts con voz del teléfono (es, offline) dice la oración FRASE A FRASE (partir por puntuación); la persona repite; el matching existente valida; pradera florece por frase; Amén dicho juntos. Si silencio ~8s: repetir con paciencia, nunca regañar. Voces humanas grabadas = Plus futuro ("elige quién ora contigo").
- PRADERA VIVA: el % de cobertura de voz (ya existe) anima en vivo pradera seca→verde, luz dorada sube, ovejita se acerca al arroyo. ES el momento UGC.
- LA PUERTA QUE ORA CONTIGO: al abrir app elegida → ovejita + NOMBRE + una frase para repetir + contador 10 segundos → "ve en paz 🐑". Branding completo (degradado marca), NUNCA pantalla genérica. Sin "¿cómo te sientes?".
- CELEBRACIÓN DIARIA: pantalla completa verde marca, ovejita GIGANTE centro, felicita POR NOMBRE, animación.

### Decisiones registradas: prueba gratis 3 días SÍ · voz del teléfono al lanzar · SIN cuentas ni base de datos (todo local + allowBackup; login opcional SOLO si algún día hay comunidad, estilo "continuar con Google" únicamente ahí) · Ángulo marketing bandera: "¿recuerdas cuando repetiste la oración de fe? esta app hace eso contigo cada mañana." + gancho confesión "¿te da pena orar en voz alta?" + gancho abuela.
