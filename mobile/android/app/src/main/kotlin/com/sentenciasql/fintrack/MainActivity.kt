package com.sentenciasql.fintrack

import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fintrack/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "isEmulator") {
                    result.success(isEmulator())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun isEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val manufacturer = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        val device = Build.DEVICE.lowercase()
        val product = Build.PRODUCT.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        return fingerprint.startsWith("generic")
            || fingerprint.startsWith("unknown")
            || fingerprint.contains("emulator")
            || fingerprint.contains("sdk_gphone")
            || model.contains("google_sdk")
            || model.contains("emulator")
            || model.contains("android sdk built for x86")
            || manufacturer.contains("genymotion")
            || (brand.startsWith("generic") && device.startsWith("generic"))
            || product == "google_sdk"
            || product.contains("sdk_gphone")
            || hardware.contains("goldfish")
            || hardware.contains("ranchu")
            || hardware.contains("qemu")
    }
}
