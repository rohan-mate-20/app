# Proguard rules for K MART Customer App

# Play Core & Split Compat warnings
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep Razorpay SDK
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep Supabase / Postgrest / Realtime
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Keep Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
