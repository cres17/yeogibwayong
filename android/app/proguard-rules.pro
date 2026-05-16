# Flutter engine + plugin registrant
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_background_service
-keep class id.flutter.flutter_background_service.** { *; }

# flutter_overlay_window
-keep class com.example.flutter_overlay_window.** { *; }

# WorkManager (androidx.work)
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# sqflite — uses reflection to load the SQLite native library
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# usage_stats
-keep class com.example.usage_stats.** { *; }
-dontwarn com.example.usage_stats.**

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# workmanager
-keep class be.tramckrijte.workmanager.** { *; }
-dontwarn be.tramckrijte.workmanager.**

# image_picker / image_cropper
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Kotlin coroutines (used by several plugins internally)
-dontwarn kotlinx.coroutines.**

# Keep all native entry points used by the Dart VM
-keep @interface dart.annotation.** { *; }
