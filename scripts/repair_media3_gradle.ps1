param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$GradleFile = Join-Path $ProjectRoot 'android\app\build.gradle.kts'
$MainActivity = Join-Path $ProjectRoot 'android\app\src\main\kotlin\com\iskora\drive\MainActivity.kt'
$PlaybackService = Join-Path $ProjectRoot 'android\app\src\main\kotlin\com\iskora\drive\media\PlaybackService.kt'

if (-not (Test-Path $GradleFile)) {
    throw "android\app\build.gradle.kts bulunamadı: $GradleFile"
}
if (-not (Test-Path $MainActivity)) {
    throw "ISKORA MainActivity bulunamadı: $MainActivity"
}
if (-not (Test-Path $PlaybackService)) {
    throw "ISKORA PlaybackService bulunamadı: $PlaybackService"
}

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Backup = "$GradleFile.backup-$Timestamp"
Copy-Item $GradleFile $Backup -Force

$Content = @'
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

android {
    namespace = "com.iskora.drive"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.iskora.drive"
        minSdk = 28
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    val media3Version = "1.10.1"

    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.media3:media3-common:$media3Version")
    implementation("androidx.media3:media3-exoplayer:$media3Version")
    implementation("androidx.media3:media3-exoplayer-hls:$media3Version")
    implementation("androidx.media3:media3-session:$media3Version")
    implementation("com.google.guava:guava:33.6.0-android")
}
'@

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($GradleFile, $Content, $Utf8NoBom)

Push-Location $ProjectRoot
try {
    Write-Host "Media3 Gradle bağımlılıkları geri yüklendi." -ForegroundColor Green
    Write-Host "Yedek: $Backup"
    Write-Host ""
    Write-Host "flutter clean çalıştırılıyor..."
    flutter clean
    if ($LASTEXITCODE -ne 0) { throw "flutter clean başarısız oldu." }

    Write-Host "flutter pub get çalıştırılıyor..."
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get başarısız oldu." }

    Write-Host ""
    Write-Host "Onarım tamamlandı." -ForegroundColor Green
    Write-Host "Şimdi çalıştır: flutter run"
}
finally {
    Pop-Location
}