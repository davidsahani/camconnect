# CamConnect Mobile

This project is mobile implementation of the CamConnect project.

## Project Configurations to Consider

### For Android:

**Important Note:** This project requires app signing for proper functioning. Below are the configurations you need to consider for successful deployment.

#### If You Prefer Not to Configure App Signing:

If you choose not to configure app signing and want the release build to function, follow these steps:

1. Open `android/app/build.gradle` and Modify the file as follows:

```gradle
android {
    namespace "com.example.camconnect"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.project.camconnect"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}
```

#### If You Want to Configure App Signing:

If you decide to configure app signing for this project, follow these steps:

1. **App Signing Properties:**
   - Create a file named `key.properties` inside `android/`.

   ```properties
    storePassword=<your-password>
    keyPassword=<your-password>
    keyAlias=upload
    storeFile=../app/upload-keystore.jks
    ```

    - Place your app signing properties within this file.


2. **App Signing Keystore:**
   - Prepare a keystore file for app signing (`upload-keystore.jks`) and store it in `android/app/`.

3. **Application ID:**
   - Open `android/app/build.gradle`.
   - Configure the application ID in the `defaultConfig` section of the file.

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace "com.example.camconnect"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.project.camconnect"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        // minSdkVersion flutter.minSdkVersion
        minSdkVersion 21
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

For more detailed information on app deployment related configurations, refer to the [Flutter documentation](https://docs.flutter.dev/deployment/android).