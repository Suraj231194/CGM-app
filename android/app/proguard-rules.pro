# Flutter & Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# BLE / CGM SDK
-keep class com.biogenix.optimus.** { *; }
-keep class com.stayoncgm.** { *; }
-keep class com.eaglenos.** { *; }
-keep class android.bluetooth.** { *; }

# The CGM AAR also ships obfuscated package roots without consumer rules.
-keep class a.** { *; }
-keep class b.** { *; }
-keep class c.** { *; }
-keep class d.** { *; }
-dontwarn com.eaglenos.**

# Gson (if used by SDK)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# Prevent stripping of model classes used via reflection
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Dio
-keep class retrofit2.** { *; }
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations

# Suppress warnings
-dontwarn com.google.android.play.core.**
-dontwarn kotlin.**
