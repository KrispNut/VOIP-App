## --- FLUTTER & GOOGLE PLAY FIXES ---

# Fixes the "Missing classes" error for Play Store/Deferred components
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Standard Flutter keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## --- VOIP & WEBRTC SPECIFIC RULES ---

# Essential for flutter_webrtc and native WebRTC signaling
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class org.webrtc.** { *; }

# Prevent R8 from stripping native methods (crucial for VOIP audio/video)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Ignore warnings for WebRTC (sometimes it references missing optional libraries)
-dontwarn org.webrtc.**

## --- ADDITIONAL PRODUCTION SAFETY ---

# If you use any JSON serialization (like GSON or BuiltValue), add those here.
# For example, if you use GSON:
# -keep class com.google.gson.** { *; }