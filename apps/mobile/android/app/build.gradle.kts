import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.plugin.compose")
}

val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.isFile) {
        file.reader(Charsets.UTF_8).use { load(it) }
    }
}

fun signingProp(propKey: String, envKey: String): String? =
    System.getenv(envKey)?.takeIf { it.isNotBlank() }
        ?: keystoreProperties.getProperty(propKey)?.takeIf { it.isNotBlank() }

android {
    namespace = "com.hofang42.ourney"
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (desugaring must be enabled even without scheduled notifications).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.hofang42.ourney"
        // minSdk 26 (Android 8.0): proposed in docs/05 §5.1; no listed plugin requires higher.
        // Sources: see docs/platform/android.md.
        minSdk = 26
        multiDexEnabled = true
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        val storePath = signingProp("storeFile", "ANDROID_KEYSTORE_PATH")
        val storePass = signingProp("storePassword", "ANDROID_KEYSTORE_PASSWORD")
        val alias = signingProp("keyAlias", "ANDROID_KEY_ALIAS")
        val keyPass = signingProp("keyPassword", "ANDROID_KEY_PASSWORD")
        if (storePath != null && storePass != null && alias != null && keyPass != null) {
            val keystoreFile = file(storePath).takeIf { it.isFile } ?: rootProject.file(storePath)
            if (keystoreFile.isFile) {
                create("release") {
                    storeFile = keystoreFile
                    storePassword = storePass
                    keyAlias = alias
                    keyPassword = keyPass
                }
            }
        }
        val isReleaseTag = System.getenv("GITHUB_REF")?.startsWith("refs/tags/v") == true
        val anySigningInput = listOf(storePath, storePass, alias, keyPass).any { it != null }
        if (isReleaseTag && findByName("release") == null) {
            throw GradleException(
                "Release tag build requires a valid release signingConfig (keystore file missing or credentials blank).",
            )
        }
        if (anySigningInput && findByName("release") == null) {
            logger.warn(
                "WARNING: Partial or invalid Android release signing credentials; falling back to debug keystore.",
            )
        }
    }

    buildTypes {
        release {
            // Uses release signing from key.properties / env when configured;
            // falls back to debug signing only for local `flutter run --release`.
            // Note: FlutterPlugin.kt already enables R8 (proguard-android-optimize.txt +
            // flutter_proguard_rules.pro) and auto-loads app/proguard-rules.pro when present.
            signingConfig =
                signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
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

dependencies {
    // flutter_local_notifications 22.x: https://pub.dev/packages/flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.glance:glance:1.2.0")
    implementation("androidx.glance:glance-appwidget:1.2.0")
    implementation("androidx.datastore:datastore-preferences:1.1.2")
    implementation("androidx.core:core-ktx:1.16.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
}
