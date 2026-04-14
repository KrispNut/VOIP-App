package com.bootlegcorp.voip

import android.os.PowerManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bootlegcorp.voip/proximity"
    private var proximityWakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquireProximityWakeLock" -> {
                    acquireProximityWakeLock()
                    result.success(true)
                }
                "releaseProximityWakeLock" -> {
                    releaseProximityWakeLock()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun acquireProximityWakeLock() {
        if (proximityWakeLock == null) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            proximityWakeLock = powerManager.newWakeLock(
                PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                "voip_app:proximity"
            )
        }
        if (proximityWakeLock?.isHeld == false) {
            proximityWakeLock?.acquire()
        }
    }

    private fun releaseProximityWakeLock() {
        if (proximityWakeLock?.isHeld == true) {
            proximityWakeLock?.release(PowerManager.RELEASE_FLAG_WAIT_FOR_NO_PROXIMITY)
        }
    }
}
