# ProGuard rules for QR Code SDK consumers
# These rules ensure that the SDK classes are properly preserved when the app is obfuscated

# Keep all SDK classes and their members
-keep class com.qrcodesdk.** { *; }
-keepclassmembers class com.qrcodesdk.** { *; }

# Keep public API classes
-keep public class com.qrcodesdk.QRCodeSDK { *; }
-keep public class com.qrcodesdk.models.** { *; }
-keep public class com.qrcodesdk.generator.** { *; }
-keep public class com.qrcodesdk.parser.** { *; }

# Keep enums
-keepclassmembers enum com.qrcodesdk.** {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class com.qrcodesdk.** implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class com.qrcodesdk.** implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep data classes
-keepclassmembers class com.qrcodesdk.models.** {
    <init>(...);
}

# Keep exception classes
-keep class com.qrcodesdk.** extends java.lang.Exception { *; }
-keep class com.qrcodesdk.** extends java.lang.RuntimeException { *; }

# Keep native methods
-keepclasseswithmembernames class com.qrcodesdk.** {
    native <methods>;
}

# Keep generic signatures
-keepattributes Signature

# Keep annotations
-keepattributes *Annotation*

# Keep inner classes
-keepattributes InnerClasses

# Keep synthetic methods
-keepattributes Synthetic

# Keep bridge methods
-keepattributes Bridge

# Keep exceptions
-keepattributes Exceptions

# Keep deprecation info
-keepattributes Deprecated

# Keep source file names for stack traces
-keepattributes SourceFile,LineNumberTable

# Don't warn about missing classes
-dontwarn com.qrcodesdk.**

# Keep public constructors
-keepclassmembers class com.qrcodesdk.** {
    public <init>(...);
}

# Keep public methods
-keepclassmembers class com.qrcodesdk.** {
    public *;
}

# Keep protected methods
-keepclassmembers class com.qrcodesdk.** {
    protected *;
}

# Keep package-private methods
-keepclassmembers class com.qrcodesdk.** {
    *;
} 