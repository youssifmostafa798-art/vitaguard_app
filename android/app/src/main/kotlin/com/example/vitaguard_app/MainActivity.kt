package com.example.vitaguard_app

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val alertChannelName = "vitaguard/alerts"
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        vibrator =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = getSystemService(VIBRATOR_MANAGER_SERVICE) as VibratorManager
                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(VIBRATOR_SERVICE) as Vibrator
            }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            alertChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCriticalAlert" -> {
                    startCriticalAlert()
                    result.success(null)
                }

                "stopCriticalAlert" -> {
                    stopCriticalAlert()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        stopCriticalAlert()
        super.onDestroy()
    }

    private fun startCriticalAlert() {
        if (mediaPlayer == null) {
            mediaPlayer = MediaPlayer.create(this, R.raw.critical_siren)?.apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                isLooping = true
                setVolume(1.0f, 1.0f)
            }
        }

        mediaPlayer?.takeIf { !it.isPlaying }?.start()
        startVibrationPattern()
    }

    private fun stopCriticalAlert() {
        mediaPlayer?.apply {
            if (isPlaying) {
                stop()
            }
            release()
        }
        mediaPlayer = null
        vibrator?.cancel()
    }

    private fun startVibrationPattern() {
        val deviceVibrator = vibrator ?: return
        if (!deviceVibrator.hasVibrator()) return

        val pattern = longArrayOf(0, 750, 400, 750)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            deviceVibrator.vibrate(VibrationEffect.createWaveform(pattern, 0))
        } else {
            @Suppress("DEPRECATION")
            deviceVibrator.vibrate(pattern, 0)
        }
    }
}
