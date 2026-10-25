# Flutter's own consumer rules and @Keep registrant retain runtime entrypoints.
# Do not keep every embedding class: this app does not use Play deferred modules.
# Optional Play Store classes referenced only by that unused embedding path:
# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# flutter_background_service
-keep class id.flutter.flutter_background_service.** { *; }

# flutter_overlay_window
-keep class flutter.overlay.window.flutter_overlay_window.** { *; }

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

# flutter_local_notifications 18 uses Gson 2.8.9 to restore scheduled alarms.
# R8 full mode must retain TypeToken's generic superclass information.
# Rules follow this plugin version's example/android/app/proguard-rules.pro.
-keepattributes Signature
-keepattributes *Annotation*
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Kotlin coroutines (used by several plugins internally)
-dontwarn kotlinx.coroutines.**

# Keep all native entry points used by the Dart VM
-keep @interface dart.annotation.** { *; }
