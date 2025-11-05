# Flutter's desi-outputs-to-annotations-processor.jar contains some Kotlin metadata that hasn't been
# processed by the Kotlin compiler. This file contains rules to prevent R8 from issuing
# warnings about that metadata.
-keep class kotlin.Metadata {
    <methods>;
}

# Flutter and related plugins require some exceptions to shrinking.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.ads.identifier.** { *; }
-keepattributes *Annotation*
-dontwarn com.google.android.gms.ads.internal.**

# For google_mobile_ads
-keep public class com.google.android.gms.ads.** {
   public *;
}
-keep public class com.google.android.gms.ads.identifier.AdvertisingIdClient {
   public *;
}
-keep public class com.google.android.gms.ads.identifier.AdvertisingIdClient$Info {
   public *;
}

# Keep rules for Google Play Core library, required by Flutter's deferred components.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; } 