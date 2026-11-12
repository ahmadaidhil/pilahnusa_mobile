# Proguard rules for TensorFlow Lite and plugins
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.** { *; }
-keep interface org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

