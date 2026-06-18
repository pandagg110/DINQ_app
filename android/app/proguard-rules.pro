# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep OkHttp3 classes to fix R8 compilation issues
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class okio.** { *; }
-dontwarn okio.**

# Keep EFS SDK classes
-keep class com.efs.sdk.** { *; }
-dontwarn com.efs.sdk.**

# General rules for all native libraries
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Flutter related classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# pdfx (Pigeon + native PDF renderer)
-keep class io.scer.pdfx.** { *; }
-keep class dev.flutter.pigeon.** { *; }
-dontwarn io.scer.pdfx.**