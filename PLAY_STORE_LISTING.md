# Ficha de Google Play — Ora Ahora

Este documento reúne el texto de la ficha de Play Store (ASO) y un
checklist de assets gráficos requeridos. Los límites de caracteres de cada
campo se respetan según las reglas de Google Play Console (verificados con
un conteo de caracteres real, ver nota al final del documento).

## Título de la app (máximo 30 caracteres)

```
Ora Ahora
```

Longitud real: 9 caracteres. Decisión del cliente: el título es solo
"Ora Ahora", sin subtítulo/descriptor adicional. Como el nombre por sí
solo no comunica la mecánica de "pausa antes de abrir redes sociales", la
descripción breve y la descripción completa se escribieron para dejarla
clara desde la primera línea.

## Descripción breve (máximo 80 caracteres)

```
Pausa y ora antes de abrir redes sociales. Devocional diario en español.
```

Longitud real: 72 caracteres.

## Descripción completa (máximo 4000 caracteres)

```
Ora Ahora es tu compañero diario de oración cristiana interdenominacional,
pensado para ayudarte a construir un hábito saludable de fe y a recuperar
el control de tu tiempo frente a la pantalla.

¿QUÉ ES ORA AHORA?

Antes de abrir Instagram, TikTok u otras apps que te distraen, Ora Ahora
te invita a una breve pausa de oración. Además, incluye un devocional
diario en español con oraciones breves para cada momento de tu día:
mañana, noche, ansiedad, gratitud, familia, trabajo, sanidad, perdón y
duelo. Cada oración incluye una referencia bíblica y toma solo unos
minutos, para que puedas volver a Dios sin importar cuán ocupado esté tu
día.

PAUSA Y ORA: BLOQUEAR REDES SOCIALES DE FORMA CRISTIANA

La función que nos hace diferentes: en vez de solo bloquear redes
sociales, Ora Ahora te invita a una breve pausa de oración justo antes de
abrir las apps que más te distraen (Instagram, TikTok, juegos y más). Es
una forma de bloquear redes sociales cristianos con propósito: no se
trata solo de prohibir, sino de elegir con libertad y calma qué haces con
tu tiempo y tu atención. Ideal si buscas una app de enfoque cristiano que
te ayude a soltar el scroll infinito sin sentirte culpable.

UN RASTREADOR DE HÁBITOS DE FE, NO UNA RACHA QUE CASTIGA

Lleva tu racha de días orando con un sistema justo: si un día se te pasa,
tienes un día libre a la semana que no rompe tu racha (a diferencia de
otras apps que castigan con dureza el primer descuido). Mira también tu
"Semilla" crecer hasta convertirse en un Árbol de fe a medida que
acumulas minutos de oración: un rastreador de hábitos de fe visual,
sencillo y alentador, no punitivo.

ORACIÓN ANTES DE DORMIR Y EN CUALQUIER MOMENTO DEL DÍA

Elige entre 4 estilos visuales, incluida una paleta oscura pensada
especialmente para tu oración antes de dormir, y otras 3 paletas claras
para el resto del día. Incluye "Modo Simple": texto y botones más
grandes, ideal para adultos mayores o cualquier persona que prefiera una
interfaz más cómoda de usar.

DIARIO DE ORACIÓN PERSONAL

Escribe tus intenciones y peticiones, márcalas como respondidas cuando
Dios actúe, y vuelve a leerlas cuando necesites recordar Su fidelidad.

RECORDATORIOS SUAVES, NO INVASIVOS

Programa hasta 3 recordatorios diarios con mensajes rotativos que te
invitan a hacer una pausa y orar, sin sentirse repetitivos ni
mecánicos.

CONFIRMACIÓN POR VOZ, 100% EN TU TELÉFONO (OPCIONAL)

A diferencia de otras apps de oración, que solo confían en un toque de
botón, Ora Ahora puede confirmar con tu propia voz que terminaste de
orar. Es opcional (apagada por defecto): el micrófono solo se activa si
tocas "Escuchar mi oración", funciona 100% en tu teléfono, nunca graba ni
envía audio a un servidor, y solo detecta si dijiste "amén" o si hablaste
de forma continua un buen rato. Siempre puedes usar el botón manual en su
lugar.

PRIVACIDAD PRIMERO

Todo tu diario, tu racha y tus preferencias se guardan localmente en tu
teléfono. Ora Ahora no lee el contenido de tus otras apps: el permiso de
Accesibilidad usado por "Pausa y Ora" solo detecta qué app está al
frente, para saber cuándo mostrarte la pausa, y nunca se envía a ningún
servidor. Lo mismo aplica a la confirmación por voz: 100% local, nunca se
sube a un servidor.

PARA TODAS LAS DENOMINACIONES

Ora Ahora es interdenominacional: no pertenece a ninguna iglesia o
denominación en particular, para que cualquier cristiano de habla
hispana se sienta como en casa.

Ora Ahora Plus (opcional) desbloquea apps ilimitadas en "Pausa y Ora",
fichas de congelación de racha adicionales y paquetes de oración
exclusivos — pero el plan gratuito de Ora Ahora siempre incluye acceso
completo al devocional diario, 1 app bloqueada en "Pausa y Ora" y tu
racha básica, sin fecha de vencimiento.

Descarga Ora Ahora hoy y convierte cada pausa del día en un momento de
oración.
```

Longitud real: 3840 caracteres.

## Checklist de assets gráficos requeridos (Play Console)

Ninguna imagen fue generada en este documento; esto es solo la lista de
lo que falta producir y subir antes de publicar.

- [ ] Ícono de la app: 512 x 512 px, PNG de 32 bits (con canal alfa),
      máximo 1024 KB. Reemplaza el ícono placeholder actual en
      `android/app/src/main/res/mipmap-*/ic_launcher.png`.
- [ ] Gráfico de funciones ("feature graphic"): 1024 x 500 px, JPG o PNG
      de 24 bits (sin transparencia).
- [ ] Capturas de pantalla del teléfono: mínimo 2, máximo 8. Formato JPG
      o PNG de 24 bits, lado mínimo 320 px, lado máximo 3840 px, relación
      de aspecto entre 16:9 y 9:16. Se recomienda incluir:
      1. Inicio con la oración del día y el widget Semilla/Árbol de fe.
      2. Pantalla de "Pausa y Ora" (PrayerGateActivity) en acción.
      3. Diario de oración.
      4. Selector de paletas de color (Ajustes > Apariencia).
      5. Pantalla de paywall / Ora Ahora Plus.
- [ ] (Opcional pero recomendado) Video promocional corto de YouTube
      (enlace, no archivo subido directamente).
- [ ] Categoría de la app en Play Console: Estilo de vida o Salud y
      bienestar (evaluar cuál rinde mejor en pruebas A/B posteriores).
- [ ] Clasificación de contenido (content rating questionnaire).
- [ ] Formulario de Seguridad de Datos (Data Safety), documentando el uso
      del permiso de Accesibilidad y que todo el almacenamiento es local.
- [ ] Declarar honestamente el uso de RECORD_AUDIO/micrófono (función
      opcional de confirmación por voz): explicar que el audio se procesa
      100% en el dispositivo (reconocimiento on-device de Android), que
      nunca se sube ni comparte con terceros, y que no se graba ni se
      guarda ningún archivo de audio.

## Nota sobre keywords usadas

Se incluyeron de forma natural (sin relleno/keyword stuffing) las
siguientes frases de cola larga relevantes para búsqueda en Play Store:
"bloquear redes sociales cristianos", "devocional diario", "rastreador de
hábitos de fe", "oración antes de dormir" y "enfoque cristiano". Todas
aparecen en frases completas y naturales en español latinoamericano
neutro, no como una lista de palabras sueltas.

Como el título ya no incluye un descriptor (decisión final del cliente:
solo "Ora Ahora"), la descripción breve y el primer párrafo de la
descripción completa se reforzaron para comunicar la mecánica de "pausa
antes de abrir redes sociales" desde el primer vistazo en la ficha de
Play Store.
