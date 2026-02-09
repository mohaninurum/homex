
package com.example.whatsapp_chat_direct
import android.media.audiofx.BassBoost
import android.media.audiofx.DynamicsProcessing
import android.media.audiofx.Equalizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {

    private val CHANNEL = "real_equalizer"

    private var equalizer: Equalizer? = null
    private var bassBoost: BassBoost? = null
    private var dynamicsProcessing: DynamicsProcessing? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // 🔹 PLAYER AUDIO
                "init" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0

                    equalizer?.release()
                    bassBoost?.release()

                    equalizer = Equalizer(0, sessionId).apply {
                        enabled = true
                    }

                    bassBoost = BassBoost(0, sessionId).apply {
                        setStrength(800)
                        enabled = true
                    }

                    createDynamicsProcessing(sessionId)
                    result.success(null)
                }

                "setBand" -> {
                    val band = call.argument<Int>("band") ?: 0
                    val level = call.argument<Int>("level") ?: 0
                    equalizer?.setBandLevel(band.toShort(), level.toShort())
                    result.success(null)
                }

                "setBassBoost" -> {
                    val strength = call.argument<Int>("strength") ?: 0
                    bassBoost?.setStrength(strength.toShort())
                    result.success(null)
                }

                // 🔹 SYSTEM AUDIO (GLOBAL)
                "initSystem" -> {

                    equalizer?.release()
                    bassBoost?.release()

                    equalizer = Equalizer(0, 0).apply {
                        enabled = true
                    }

                    bassBoost = BassBoost(0, 0).apply {
                        setStrength(900)
                        enabled = true
                    }

                    createDynamicsProcessing(0)

                    result.success(null)
                }

                // 🔹 CLEANUP
                "disableSystem" -> {

                    bassBoost?.setStrength(0)
                    bassBoost?.enabled = false
                    bassBoost?.release()
                    bassBoost = null

                    equalizer?.enabled = false
                    equalizer?.release()
                    equalizer = null

                    dynamicsProcessing?.release()
                    dynamicsProcessing = null

                    result.success(null)
                }
                "enableBoomSurround" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0

                    // Equalizer
                    equalizer?.release()
                    equalizer = Equalizer(0, sessionId)
                    equalizer?.enabled = true

                    // 🎧 EQ tuning (boomy + surround)
                    equalizer?.setBandLevel(0, 7)   // 60 Hz
                    equalizer?.setBandLevel(1, 4)   // 120 Hz
                    equalizer?.setBandLevel(2, (-2).toShort()) // mid cut
                    equalizer?.setBandLevel(4, 2)   // highs

                    // BassBoost
                    bassBoost?.release()
                    bassBoost = BassBoost(0, sessionId)
                    bassBoost?.setStrength(850)
                    bassBoost?.enabled = true

                    // DynamicsProcessing (deep bass + limiter)
                    createDynamicsProcessing(sessionId)

                    result.success(true)
                }
                "disableBoomSurround" -> {

                    bassBoost?.enabled = false
                    bassBoost?.release()
                    bassBoost = null

                    equalizer?.enabled = false
                    equalizer?.release()
                    equalizer = null

                    dynamicsProcessing?.release()
                    dynamicsProcessing = null

                    result.success(true)
                }

                "enableBassEnhancement" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0

                    // Release old effects
                    equalizer?.release()
                    bassBoost?.release()
                    dynamicsProcessing?.release()

                    // 🎚 Equalizer (Low freq boost)
                    equalizer = Equalizer(0, sessionId)
                    equalizer?.enabled = true

                    // Boost first 2 bands (deep bass)
                    equalizer?.setBandLevel(0, 800)   // ~60Hz
                    equalizer?.setBandLevel(1, 500)   // ~120Hz

                    // 🔊 BassBoost (controlled)
                    bassBoost = BassBoost(0, sessionId)
                    bassBoost?.setStrength(600) // not max → clean bass
                    bassBoost?.enabled = true

                    // 🔥 Advanced Bass Enhancement
                    createDynamicsProcessing(sessionId)

                    result.success(null)
                }
                "disableBassEnhancement" -> {

                    bassBoost?.enabled = false
                    bassBoost?.release()
                    bassBoost = null

                    equalizer?.enabled = false
                    equalizer?.release()
                    equalizer = null

                    dynamicsProcessing?.release()
                    dynamicsProcessing = null

                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    // ✅ SAFE & SIMPLE (NO CONFIG / NO BUILDER)
    private fun createDynamicsProcessing(sessionId: Int) {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.P) return

        dynamicsProcessing?.release()
        dynamicsProcessing = null

        dynamicsProcessing = DynamicsProcessing(0)
        dynamicsProcessing?.enabled = true
        applyBassEnhancement()
    }

    private fun applyBassEnhancement() {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.P) return

        dynamicsProcessing?.let { dp ->

            // 🔥 Multi Band Compressor (SUB BASS)
            val mbc = dp.getMbcByChannelIndex(0)
            val band = mbc.getBand(0)

            band.isEnabled = true
            band.cutoffFrequency = 120f   // deep bass range
            band.threshold = -30f         // strong bass
            band.ratio = 5.0f             // punch
            band.attackTime = 5f
            band.releaseTime = 150f

            // 🛑 Limiter (speaker / ear protection)
            val limiter = dp.getLimiterByChannelIndex(0)
            limiter.isEnabled = true
        }
    }


}
