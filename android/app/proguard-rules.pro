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

# ML Kit / Mobile Scanner barcode scanning.
# Release minification can otherwise damage bundled barcode internals and
# surface obfuscated null-reference errors from packages such as u4/q4.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode_bundled.** { *; }
-keep class com.google.android.libraries.barhopper.** { *; }
-keep class u4.** { *; }
-keep class q4.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_vision_barcode.**
-dontwarn com.google.android.gms.internal.mlkit_vision_barcode_bundled.**
-dontwarn com.google.android.libraries.barhopper.**

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
