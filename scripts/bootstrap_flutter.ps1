$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$BackupRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("iskora-drive-bootstrap-" + [guid]::NewGuid().ToString('N'))

$ProtectedPaths = @(
    'pubspec.yaml',
    'analysis_options.yaml',
    'lib',
    'test',
    'android\app',
    'android\build.gradle.kts',
    'android\settings.gradle.kts',
    'android\gradle.properties',
    'android\gradle\wrapper\gradle-wrapper.properties'
)

function Backup-ProjectPath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $Source = Join-Path $Root $RelativePath
    if (-not (Test-Path $Source)) {
        return
    }

    $Destination = Join-Path $BackupRoot $RelativePath
    $DestinationParent = Split-Path $Destination -Parent
    New-Item -ItemType Directory -Force -Path $DestinationParent | Out-Null
    Copy-Item -Path $Source -Destination $Destination -Recurse -Force
}

function Restore-ProjectPath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $Source = Join-Path $BackupRoot $RelativePath
    if (-not (Test-Path $Source)) {
        return
    }

    $Destination = Join-Path $Root $RelativePath
    if (Test-Path $Destination) {
        Remove-Item -Path $Destination -Recurse -Force
    }

    $DestinationParent = Split-Path $Destination -Parent
    New-Item -ItemType Directory -Force -Path $DestinationParent | Out-Null
    Copy-Item -Path $Source -Destination $Destination -Recurse -Force
}

Push-Location $Root

try {
    Write-Host 'Checking Flutter installation...'
    flutter --version
    if ($LASTEXITCODE -ne 0) {
        throw 'Flutter could not be started. Add Flutter to PATH and try again.'
    }

    Write-Host 'Protecting ISKORA Flutter and native Kotlin sources...'
    New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
    foreach ($Path in $ProtectedPaths) {
        Backup-ProjectPath -RelativePath $Path
    }

    Write-Host 'Generating missing Flutter/Gradle scaffold files...'
    flutter create --platforms=android --org com.iskora --project-name iskora_drive --overwrite .
    if ($LASTEXITCODE -ne 0) {
        throw 'Flutter scaffold generation failed.'
    }

    Write-Host 'Restoring ISKORA Media3, Android Auto and Flutter sources...'
    foreach ($Path in $ProtectedPaths) {
        Restore-ProjectPath -RelativePath $Path
    }

    Write-Host 'Resolving packages...'
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter pub get failed.'
    }

    Write-Host 'Running static analysis...'
    flutter analyze
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter analyze failed.'
    }

    Write-Host 'Running tests...'
    flutter test
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter test failed.'
    }

    Write-Host ''
    Write-Host 'ISKORA Drive is ready.' -ForegroundColor Green
    Write-Host 'Run: flutter run'
    Write-Host 'Build: flutter build appbundle --release'
}
finally {
    Pop-Location
    if (Test-Path $BackupRoot) {
        Remove-Item -Path $BackupRoot -Recurse -Force
    }
}