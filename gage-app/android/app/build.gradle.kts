plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.gage.gage_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.gage.customer"
        manifestPlaceholders["appName"] = "GAGE Delivery"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"
    productFlavors {
        create("customer") {
            dimension = "app"
            applicationId = "com.gage.customer"
            manifestPlaceholders["appName"] = "Gage Pracimantoro"
        }
        create("merchant") {
            dimension = "app"
            applicationId = "com.gage.merchant"
            manifestPlaceholders["appName"] = "GAGE Merchant"
        }
        create("driver") {
            dimension = "app"
            applicationId = "com.gage.driver"
            manifestPlaceholders["appName"] = "GAGE Driver"
        }
        create("admin") {
            dimension = "app"
            applicationId = "com.gage.admin"
            manifestPlaceholders["appName"] = "GAGE Admin"
        }
    }

    buildTypes {
        release {
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
