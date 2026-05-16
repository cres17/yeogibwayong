package com.cres.yeogibwayong

import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val oemChannel = "com.cres.yeogibwayong/oem_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            oemChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBrand" -> result.success(Build.BRAND)

                "openSamsungAutostart" -> {
                    // Samsung One UI: Device care → Battery → App power management
                    val launched = tryStartActivity(
                        Intent().setClassName(
                            "com.samsung.android.lool",
                            "com.samsung.android.sm.battery.ui.BatteryActivity",
                        )
                    ) || tryStartActivity(
                        // Fallback for older One UI versions
                        Intent().setClassName(
                            "com.samsung.android.sm",
                            "com.samsung.android.sm.ui.battery.BatteryActivity",
                        )
                    ) || tryStartActivity(
                        Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                    )
                    if (launched) result.success(null) else result.error("LAUNCH_FAILED", null, null)
                }

                "openMiuiAutostart" -> {
                    // MIUI: Security → Permissions → Autostart
                    val launched = tryStartActivity(
                        Intent().apply {
                            setClassName(
                                "com.miui.securitycenter",
                                "com.miui.permcenter.autostart.AutoStartManagementActivity",
                            )
                        }
                    ) || tryStartActivity(
                        // HyperOS / MIUI 14+ fallback
                        Intent().apply {
                            setClassName(
                                "com.miui.powerkeeper",
                                "com.miui.powerkeeper.ui.HiddenAppsContainerManagementActivity",
                            )
                        }
                    ) || tryStartActivity(
                        Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                    )
                    if (launched) result.success(null) else result.error("LAUNCH_FAILED", null, null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun tryStartActivity(intent: Intent): Boolean {
        return try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
