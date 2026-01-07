// plugins {
//     id("com.android.application")
//     id("kotlin-android")
//     // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
//     id("dev.flutter.flutter-gradle-plugin")
// }

// android {
//     namespace = "com.HTCL.asia_fibernet"
//     compileSdk = flutter.compileSdkVersion
//     ndkVersion = "27.0.12077973"//flutter.ndkVersion

//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_11
//         targetCompatibility = JavaVersion.VERSION_11

//          // ✅ Enable desugaring
//         isCoreLibraryDesugaringEnabled = true
//     }

//     kotlinOptions {
//         jvmTarget = JavaVersion.VERSION_11.toString()
//     }

//     defaultConfig {
//         // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
//         applicationId = "com.HTCL.asia_fibernet"
//         // You can update the following values to match your application needs.
//         // For more information, see: https://flutter.dev/to/review-gradle-config.
//         minSdk = flutter.minSdkVersion
//         targetSdk = flutter.targetSdkVersion
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//     }

//     buildTypes {
//         release {
//             // TODO: Add your own signing config for the release build.
//             // Signing with the debug keys for now, so `flutter run --release` works.
//             signingConfig = signingConfigs.getByName("debug")
//         }
//     }
// }

// flutter {
//     source = "../.."
// }

// dependencies {
//     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
// }


// plugins {
//     id("com.android.application")
//     id("org.jetbrains.kotlin.android") // updated plugin id
//     // Flutter plugin must be applied last
//     id("dev.flutter.flutter-gradle-plugin")
// }

// android {
//     namespace = "com.HTCL.asia_fibernet"
//     compileSdk = flutter.compileSdkVersion
//     ndkVersion = flutter.ndkVersion // safer to use flutter.ndkVersion unless you must lock to 27

//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_17
//         targetCompatibility = JavaVersion.VERSION_17
//         // ✅ Enable desugaring
//         isCoreLibraryDesugaringEnabled = true
//     }

//     kotlinOptions {
//         jvmTarget = "17"//JavaVersion.VERSION_17.toString()
//     }

//     defaultConfig {
//         applicationId = "com.HTCL.asia_fibernet"
//         minSdk = flutter.minSdkVersion
//         targetSdk = flutter.targetSdkVersion
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//         multiDexEnabled = true // ✅ recommended when desugaring + Flutter
//     }

//     buildTypes {
//         release {
//             signingConfig = signingConfigs.getByName("debug") // ⚠️ replace with real keystore for production
//             // minifyEnabled = false
//             // shrinkResources = false
//         }
//     }
// }

// flutter {
//     source = "../.."
// }

// dependencies {
//     implementation("androidx.multidex:multidex:2.0.1") // ✅ safer with Flutter & desugaring
//     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
// }



plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin") // must be last
}

android {
    namespace = "com.htcl.asiaFibernet"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" //flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.htcl.asiaFibernet"
        minSdk = flutter.minSdkVersion//flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = file("upload-keystore.jks")
            storePassword = "asiaFibernet"
            keyPassword = "asiaFibernet"
            keyAlias = "upload"
        }
    }

    buildTypes {
        release {  
            // signingConfig = signingConfigs.getByName("debug")
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-analytics")

    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
