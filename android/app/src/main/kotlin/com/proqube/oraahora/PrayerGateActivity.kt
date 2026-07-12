package com.proqube.oraahora

import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.animation.ValueAnimator
import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject
import kotlin.random.Random

/**
 * Pantalla nativa (100% Kotlin + layout XML, sin un segundo motor de
 * Flutter) que se muestra encima de una app "gateada" cuando el usuario
 * intenta abrirla.
 *
 * DECISION DE DISEÑO / TRADEOFF (ver tambien el informe final):
 * Se eligio una Activity puramente nativa en lugar de hospedar un
 * `FlutterFragment`/segundo `FlutterEngine` porque:
 *  - Arrancar un motor de Flutter adicional añade latencia perceptible
 *    justo en el momento en que el usuario espera abrir otra app (mala
 *    experiencia para una interrupcion que debe sentirse instantanea).
 *  - Evita la complejidad y el consumo de memoria de mantener un
 *    `FlutterEngineCache` vivo en segundo plano solo para esta pantalla.
 *  - Al no poder compilar/probar en este entorno, una Activity nativa
 *    simple es mas facil de verificar por lectura cuidadosa que la
 *    integracion de un segundo engine de Flutter.
 * La desventaja es duplicar un poco de UI (esta pantalla no comparte
 * widgets con el resto de la app Flutter), pero se mantiene el mismo
 * catalogo de datos: este archivo lee el mismo
 * `assets/data/prayers_es.json` que usa Flutter, directamente desde los
 * assets empaquetados de Flutter dentro del APK
 * ("flutter_assets/assets/data/prayers_es.json").
 *
 * CHECK-IN DE ANIMO (mood check-in): antes de mostrar la oracion, esta
 * pantalla ahora pregunta brevemente como se siente la persona (6 opciones
 * en espanol) y elige una oracion de la categoria mas relevante para ese
 * animo. Es una personalizacion real (no una mecanica de manipulacion): si
 * no se elige nada en unos segundos, o si se toca "Solo muéstrame algo", se
 * usa el mismo comportamiento por defecto que existia antes (una oracion
 * aleatoria de la categoria "tentacion_enfoque", ya que esta pantalla se
 * muestra para apps que distraen).
 */
class PrayerGateActivity : Activity() {

    companion object {
        private const val TAG = "PrayerGateActivity"
        const val EXTRA_TARGET_PACKAGE = "extra_target_package"

        private const val MIN_DWELL_MILLIS = 10_000L
        private const val TICK_MILLIS = 1_000L
        private const val CATEGORY_TENTACION_ENFOQUE = "tentacion_enfoque"
        private const val FLUTTER_ASSET_PATH = "flutter_assets/assets/data/prayers_es.json"

        /** Categorias por defecto (sin animo elegido): igual que antes. */
        private val DEFAULT_CATEGORIES = listOf(CATEGORY_TENTACION_ENFOQUE)

        /** Cuanto se espera antes de usar el comportamiento por defecto si
         * la persona no elige ningun animo. Corto a propósito: la pausa ya
         * es una interrupcion, no se le debe sumar una espera larga solo
         * para decidir si participa del check-in. */
        private const val MOOD_AUTO_SKIP_MILLIS = 6_000L

        // Respaldo por si el asset no se puede leer (no deberia ocurrir en
        // una build normal, pero evita dejar la pantalla vacia).
        private val FALLBACK_PRAYERS = listOf(
            Triple(
                "Antes de abrir esta app",
                "Señor, antes de perder minutos sin darme cuenta, ayúdame a " +
                    "decidir con libertad si de verdad quiero entrar ahora. " +
                    "Dame dominio propio para usar mi tiempo de forma que " +
                    "después no me arrepienta. Amén.",
                "cf. Gálatas 5:22-23"
            ),
            Triple(
                "Recupera tu atención",
                "Dios, mi atención es valiosa. Ayúdame a decidir cuándo y " +
                    "cómo uso esta app, en lugar de que ella decida por mí. " +
                    "Guía este momento. Amén.",
                "cf. Romanos 12:2"
            ),
        )
    }

    private lateinit var moodContainer: View
    private lateinit var prayerContentContainer: View
    private lateinit var textPrayerTitle: TextView
    private lateinit var textPrayerBody: TextView
    private lateinit var textPrayerRef: TextView
    private lateinit var buttonContinue: Button
    private lateinit var textBreathingCue: TextView
    private lateinit var breathingCircle: View
    private var targetPackage: String? = null
    private var dwellFinished = false
    private var moodResolved = false
    private var breathingAnimator: ValueAnimator? = null
    private val handler = Handler(Looper.getMainLooper())
    private var breathingToggleRunnable: Runnable? = null
    private var moodAutoSkipRunnable: Runnable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_prayer_gate)

        targetPackage = intent.getStringExtra(EXTRA_TARGET_PACKAGE)

        val textTargetApp = findViewById<TextView>(R.id.textTargetApp)
        moodContainer = findViewById(R.id.moodContainer)
        prayerContentContainer = findViewById(R.id.prayerContentContainer)
        textPrayerTitle = findViewById(R.id.textPrayerTitle)
        textPrayerBody = findViewById(R.id.textPrayerBody)
        textPrayerRef = findViewById(R.id.textPrayerRef)
        val buttonSnooze = findViewById<TextView>(R.id.buttonSnooze)
        val buttonMoodSkip = findViewById<TextView>(R.id.buttonMoodSkip)
        buttonContinue = findViewById(R.id.buttonContinue)
        textBreathingCue = findViewById(R.id.textBreathingCue)
        breathingCircle = findViewById(R.id.breathingCircle)

        textTargetApp.text = "Pausa antes de abrir " + appLabelFor(targetPackage)

        setupMoodButton(R.id.buttonMoodAnsioso, listOf("ansiedad"))
        setupMoodButton(R.id.buttonMoodAgradecido, listOf("gratitud"))
        setupMoodButton(R.id.buttonMoodCansado, listOf("sanidad"))
        setupMoodButton(R.id.buttonMoodTriste, listOf("duelo", "perdon"))
        setupMoodButton(R.id.buttonMoodDistraido, listOf(CATEGORY_TENTACION_ENFOQUE))
        setupMoodButton(R.id.buttonMoodPaz, listOf("gratitud"))

        buttonMoodSkip.setOnClickListener { resolveMood(DEFAULT_CATEGORIES) }

        val autoSkip = Runnable { resolveMood(DEFAULT_CATEGORIES) }
        moodAutoSkipRunnable = autoSkip
        handler.postDelayed(autoSkip, MOOD_AUTO_SKIP_MILLIS)

        buttonContinue.setOnClickListener {
            if (!dwellFinished) return@setOnClickListener
            targetPackage?.let { PrayerGateAccessibilityService.markUnlockedNow(this, it) }
            continueToTargetApp()
        }

        buttonSnooze.setOnClickListener {
            targetPackage?.let { PrayerGateAccessibilityService.markSnoozedForToday(this, it) }
            continueToTargetApp()
        }
    }

    private fun setupMoodButton(viewId: Int, categories: List<String>) {
        findViewById<Button>(viewId).setOnClickListener { resolveMood(categories) }
    }

    /** Se llama una sola vez: por un toque de animo, el boton de saltar, o
     * el temporizador de auto-salto. Cualquier via posterior se ignora. */
    private fun resolveMood(categories: List<String>) {
        if (moodResolved) return
        moodResolved = true

        moodAutoSkipRunnable?.let { handler.removeCallbacks(it) }
        moodAutoSkipRunnable = null

        moodContainer.visibility = View.GONE
        prayerContentContainer.visibility = View.VISIBLE

        val (titulo, texto, referencia) = loadRandomPrayer(categories)
        textPrayerTitle.text = titulo
        textPrayerBody.text = texto
        textPrayerRef.text = referencia

        startBreathingAnimation()
        startDwellTimer()
    }

    private fun appLabelFor(packageName: String?): String {
        if (packageName == null) return "esta app"
        return try {
            val info = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    /**
     * Elige una oracion al azar de la primera categoria en [categories] que
     * tenga al menos una coincidencia en el catalogo (asi "Triste" puede
     * intentar primero "duelo" y usar "perdon" como respaldo, por ejemplo).
     * Si ninguna categoria tiene coincidencias, o el asset no se puede leer,
     * usa [FALLBACK_PRAYERS].
     */
    private fun loadRandomPrayer(categories: List<String>): Triple<String, String, String> {
        try {
            assets.open(FLUTTER_ASSET_PATH).use { input ->
                val json = input.bufferedReader(Charsets.UTF_8).readText()
                val array = JSONArray(json)
                val byCategory = mutableMapOf<String, MutableList<JSONObject>>()
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val categoria = obj.optString("categoria")
                    byCategory.getOrPut(categoria) { mutableListOf() }.add(obj)
                }
                for (categoria in categories) {
                    val matches = byCategory[categoria]
                    if (!matches.isNullOrEmpty()) {
                        val chosen = matches[Random.nextInt(matches.size)]
                        return Triple(
                            chosen.getString("titulo"),
                            chosen.getString("texto"),
                            chosen.getString("referencia_biblica"),
                        )
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo leer prayers_es.json, usando respaldo local: ${e.message}")
        }
        val fallback = FALLBACK_PRAYERS[Random.nextInt(FALLBACK_PRAYERS.size)]
        return fallback
    }

    private fun startBreathingAnimation() {
        val scaleUp = PropertyValuesHolder.ofFloat(View.SCALE_X, 1f, 1.3f)
        val scaleUpY = PropertyValuesHolder.ofFloat(View.SCALE_Y, 1f, 1.3f)
        val animator = ObjectAnimator.ofPropertyValuesHolder(breathingCircle, scaleUp, scaleUpY)
        animator.duration = 4000
        animator.repeatMode = ValueAnimator.REVERSE
        animator.repeatCount = ValueAnimator.INFINITE
        animator.start()
        breathingAnimator = animator

        var inhaling = true
        textBreathingCue.text = "Inhala..."
        val toggle = object : Runnable {
            override fun run() {
                inhaling = !inhaling
                textBreathingCue.text = if (inhaling) "Inhala..." else "Exhala..."
                handler.postDelayed(this, 4000)
            }
        }
        breathingToggleRunnable = toggle
        handler.postDelayed(toggle, 4000)
    }

    private fun startDwellTimer() {
        buttonContinue.isEnabled = false
        object : CountDownTimer(MIN_DWELL_MILLIS, TICK_MILLIS) {
            override fun onTick(millisUntilFinished: Long) {
                val seconds = (millisUntilFinished / 1000L) + 1
                buttonContinue.text = "Espera ${seconds}s..."
            }

            override fun onFinish() {
                dwellFinished = true
                buttonContinue.isEnabled = true
                buttonContinue.text = "Continuar a la app"
            }
        }.start()
    }

    private fun continueToTargetApp() {
        val pkg = targetPackage
        if (pkg == null) {
            finish()
            return
        }
        val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
        } else {
            Toast.makeText(this, "No se pudo abrir la app", Toast.LENGTH_SHORT).show()
        }
        finish()
    }

    override fun onBackPressed() {
        if (!moodResolved) {
            // Todavia en el check-in de animo: tratar "atras" como la
            // opcion de saltar, en vez de bloquear (aqui no hay una espera
            // minima que proteger todavia).
            resolveMood(DEFAULT_CATEGORIES)
            return
        }
        if (!dwellFinished) {
            Toast.makeText(this, "Espera unos segundos antes de continuar", Toast.LENGTH_SHORT).show()
            return
        }
        super.onBackPressed()
    }

    override fun onDestroy() {
        super.onDestroy()
        breathingAnimator?.cancel()
        breathingToggleRunnable?.let { handler.removeCallbacks(it) }
        moodAutoSkipRunnable?.let { handler.removeCallbacks(it) }
    }
}
