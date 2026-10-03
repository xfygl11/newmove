# Flutter 默认混淆规则由 proguard-android-optimize.txt 与 Flutter 插件自带规则覆盖。
# 这里补充本项目依赖所需的 keep 规则。

# video_player（ExoPlayer/媒体栈）经 JNI 反射访问，保留其内部类。
-keep class androidx.media3.** { *; }
-keep class android.support.v4.media.** { *; }

# flutter_secure_storage：JNI 与 Java 反射交互。
-keep class com.it_nomads1.fluttersecurestorage.** { *; }

# sqlite3（drift 底层）JNI 绑定按类名查找。
-keep class org.sqlite.** { *; }
