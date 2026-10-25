package com.cres.yeogibwayong

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val appExecutor = Executors.newSingleThreadExecutor()

    private val oemChannel = "com.cres.yeogibwayong/oem_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "com.cres.yeogibwayong/apps").setMethodCallHandler { call, result ->
            if (call.method != "listLaunchableApps") {
                result.notImplemented()
            } else {
                appExecutor.execute {
                    try {
                        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                        val apps = packageManager.queryIntentActivities(intent, 0)
                            .distinctBy { it.activityInfo.packageName }
                            .filter { it.activityInfo.packageName != packageName }
                            .map { entry ->
                                val icon = try {
                                    val drawable = entry.loadIcon(packageManager)
                                    val bitmap = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
                                    drawable.setBounds(0, 0, 96, 96)
                                    drawable.draw(Canvas(bitmap))
                                    ByteArrayOutputStream().use { output ->
                                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
                                        bitmap.recycle()
                                        output.toByteArray()
                                    }
                                } catch (_: Exception) { null }
                                mapOf("packageName" to entry.activityInfo.packageName,
                                    "appName" to entry.loadLabel(packageManager).toString(), "icon" to icon)
                            }
                        runOnUiThread { result.success(apps) }
                    } catch (error: Exception) {
                        runOnUiThread { result.error("APP_LIST_FAILED", error.message, null) }
                    }
                }
            }
        }

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

    override fun onDestroy() {
        appExecutor.shutdown()
        super.onDestroy()
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
