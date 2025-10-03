# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Stripe Android SDK
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.** { *; }

# Keep Stripe classes that might be missing
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivity** { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivityStarter** { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all classes with @Keep annotation
-keep @androidx.annotation.Keep class * {*;}

# Keep all classes in the main package
-keep class com.example.vegnbio_front.** { *; }
