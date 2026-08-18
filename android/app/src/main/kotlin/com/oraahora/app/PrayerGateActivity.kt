package com.oraahora.app

import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.animation.ValueAnimator
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.util.Log
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import org.json.JSONArray
import kotlin.random.Random

/**
 * La Puerta del Redil (rediseño 2026). Pantalla nativa que se muestra
 * encima de una app "gateada" cuando la persona intenta abrirla.
 *
 * Sin encuesta de ánimo (se eliminó por decisión de producto). Muestra:
 * la ovejita, un saludo con el nombre, UNA oración corta rotada del
 * repertorio exclusivo `assets/data/puerta_es.json` (60 oraciones), un
 * contador de 10 s y un botón de victoria ("Mejor lo dejo").
 */
class PrayerGateActivity : Activity() {

    companion object {
        private const val TAG = "PrayerGateActivity"
        const val EXTRA_TARGET_PACKAGE = "extra_target_package"

        private const val MIN_DWELL_MILLIS = 10_000L
        private const val TICK_MILLIS = 1_000L
        private const val PUERTA_ASSET = "flutter_assets/assets/data/puerta_es.json"

        // SharedPreferences de Flutter (plugin shared_preferences): las
        // claves llevan el prefijo "flutter.".
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val KEY_USER_NAME = "flutter.user_name"
        private const val KEY_PUERTA_INDEX = "flutter.puerta_prayer_index"
        private const val KEY_GATE_PRAYERS = "flutter.gate_prayers"

        private val FALLBACK = listOf(
            "Señor, antes de entrar, quédate conmigo. Que no se me vaya el rato sin darme cuenta. Amén.",
            "Dios, dame un minuto contigo antes que a la pantalla. Solo un minuto. Amén.",
        "Padre, sé que vine por costumbre. Ayúdame a decidir con calma. Amén.",
        "Señor, calma mi prisa. No necesito llenar cada silencio con el celular. Amén.",
        "Dios, gracias por este alto. Respiro, y me acuerdo de que estás aquí. Amén.",
        "Padre, que este momento sea mío otra vez, y no de la pantalla. Amén.",
        "Jesús, antes de scrollear, quiero mirarte a ti primero. Amén.",
        "Señor, cuida mi mente de lo que estoy por ver. Guárdame. Amén.",
        "Dios, si abro esto, que sea con paz y no por ansiedad. Amén.",
        "Padre, un respiro contigo vale más que mil videos. Gracias. Amén.",
        "Señor, ayúdame a soltar el teléfono cuando toque soltarlo. Amén.",
        "Jesús, ocupa tú el lugar que le doy a esta pantalla. Amén.",
        )
    }

    private lateinit var buttonContinue: Button
    private lateinit var imageSheep: ImageView
    private var targetPackage: String? = null
    private var dwellFinished = false
    private var breathingAnimator: ValueAnimator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_prayer_gate)

        targetPackage = intent.getStringExtra(EXTRA_TARGET_PACKAGE)

        val textTargetApp = findViewById<TextView>(R.id.textTargetApp)
        val textGreeting = findViewById<TextView>(R.id.textGreeting)
        val textPrayerBody = findViewById<TextView>(R.id.textPrayerBody)
        val buttonSnooze = findViewById<TextView>(R.id.buttonSnooze)
        buttonContinue = findViewById(R.id.buttonContinue)
        imageSheep = findViewById(R.id.imageSheep)

        textTargetApp.text = "UN MOMENTO ANTES DE " +
            appLabelFor(targetPackage).uppercase()

        val nombre = readUserName()
        textGreeting.text = if (nombre.isNullOrBlank())
            "Espera un momento" else "Espera, $nombre"

        textPrayerBody.text = nextPrayer()

        startBreathingAnimation()
        startDwellTimer()

        buttonContinue.setOnClickListener {
            if (!dwellFinished) return@setOnClickListener
            targetPackage?.let { PrayerGateForegroundService.markUnlockedNow(this, it) }
            continueToTargetApp()
        }

        // Victoria: la persona decide NO entrar. Se cuenta como cuidado.
        buttonSnooze.setOnClickListener {
            targetPackage?.let { PrayerGateForegroundService.markVictoryCooldown(this, it) }
            Toast.makeText(this, "Bien hecho 🕊️ El Pastor te cuidó", Toast.LENGTH_SHORT).show()
            salirAlInicio()
        }
    }

    /**
     * Saca a la persona de la app vigilada y la deja en la pantalla de inicio.
     * Con finish() solo se cerraba la pausa y quedaba la app abierta debajo.
     */
    private fun salirAlInicio() {
        val home = Intent(Intent.ACTION_MAIN)
        home.addCategory(Intent.CATEGORY_HOME)
        home.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(home)
        finishAndRemoveTask()
    }

    /** Lee el nombre guardado por Flutter (shared_preferences). */
    private fun readUserName(): String? {
        return try {
            val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            prefs.getString(KEY_USER_NAME, null)
        } catch (e: Exception) {
            null
        }
    }

    /** Devuelve la siguiente oración del repertorio, rotando el índice y
     * guardándolo, para que casi nunca se repita el mismo día. */
    private fun nextPrayer(): String {
        val lista = loadPrayers()
        if (lista.isEmpty()) return FALLBACK[Random.nextInt(FALLBACK.size)]
        val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        // AL AZAR: la pausa sale varias veces al dia, por eso se elige una
        // oracion aleatoria y solo se evita repetir la ultima mostrada.
        val last = prefs.getInt(KEY_PUERTA_INDEX, -1)
        var next = Random.nextInt(lista.size)
        if (lista.size > 1 && next == last) {
            next = (next + 1 + Random.nextInt(lista.size - 1)) % lista.size
        }
        prefs.edit().putInt(KEY_PUERTA_INDEX, next).apply()
        return lista[next]
    }

    private fun loadPrayers(): List<String> {
        // 1) Lista PERSONALIZADA segun las necesidades que la persona eligio
        //    (ansiedad, familia, etc.). Flutter la escribe en SharedPreferences
        //    como un JSON array de textos.
        try {
            val prefs = getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_GATE_PRAYERS, null)
            if (!raw.isNullOrBlank()) {
                val array = JSONArray(raw)
                val out = ArrayList<String>(array.length())
                for (i in 0 until array.length()) out.add(array.getString(i))
                if (out.isNotEmpty()) return out
            }
        } catch (e: Exception) {
            Log.w(TAG, "gate_prayers personalizadas invalidas: ${e.message}")
        }
        // 2) Fallback: repertorio generico del asset.
        return try {
            assets.open(PUERTA_ASSET).use { input ->
                val json = input.bufferedReader(Charsets.UTF_8).readText()
                val array = JSONArray(json)
                val out = ArrayList<String>(array.length())
                for (i in 0 until array.length()) {
                    out.add(array.getJSONObject(i).getString("texto"))
                }
                out
            }
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo leer puerta_es.json: ${e.message}")
            FALLBACK
        }
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

    private fun startBreathingAnimation() {
        val scaleUp = PropertyValuesHolder.ofFloat(android.view.View.SCALE_X, 1f, 1.06f)
        val scaleUpY = PropertyValuesHolder.ofFloat(android.view.View.SCALE_Y, 1f, 1.06f)
        val animator = ObjectAnimator.ofPropertyValuesHolder(imageSheep, scaleUp, scaleUpY)
        animator.duration = 2600
        animator.repeatMode = ValueAnimator.REVERSE
        animator.repeatCount = ValueAnimator.INFINITE
        animator.start()
        breathingAnimator = animator
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
                buttonContinue.text = "Ve tranquila 🐑"
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
        if (!dwellFinished) {
            Toast.makeText(this, "Respira unos segundos 🕊️", Toast.LENGTH_SHORT).show()
            return
        }
        super.onBackPressed()
    }

    override fun onDestroy() {
        super.onDestroy()
        breathingAnimator?.cancel()
    }
}
