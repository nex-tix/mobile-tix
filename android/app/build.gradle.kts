plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mobile_tix"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mobile_tix"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

tasks.matching { it.name == "assembleRelease" || it.name == "assembleDebug" }.configureEach {
    doLast {
        val isRelease = name.contains("Release")
        val variantName = if (isRelease) "release" else "debug"
        val outputDir = layout.buildDirectory.dir("outputs/apk/$variantName").get().asFile
        val defaultApk = File(outputDir, "app-$variantName.apk")
        if (defaultApk.exists()) {
            val version = android.defaultConfig.versionName ?: "1.0.0"
            val suffix = if (isRelease) "" else "-debug"
            val plainApk = File(outputDir, "Nextix$suffix.apk")
            val versionedApk = File(outputDir, "Nextix-v${version}$suffix.apk")
            defaultApk.copyTo(plainApk, overwrite = true)
            defaultApk.copyTo(versionedApk, overwrite = true)

            val flutterApkDir = File(outputDir.parentFile?.parentFile, "flutter-apk")
            if (flutterApkDir.exists() || flutterApkDir.mkdirs()) {
                defaultApk.copyTo(File(flutterApkDir, "Nextix$suffix.apk"), overwrite = true)
                defaultApk.copyTo(File(flutterApkDir, "Nextix-v${version}$suffix.apk"), overwrite = true)
            }
        }
    }
}

