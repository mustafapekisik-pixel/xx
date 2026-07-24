$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $Root

try {
    Write-Host 'Checking Flutter installation...'
    flutter --version

    Write-Host 'Generating missing Flutter platform files...'
    flutter create --platforms=android --org com.iskora --project-name iskora_drive --overwrite .

    Write-Host 'Restoring ISKORA source files after scaffold generation...'
    git restore --source=HEAD -- .

    Write-Host 'Resolving packages...'
    flutter pub get

    Write-Host 'Running static analysis...'
    flutter analyze

    Write-Host 'Running tests...'
    flutter test

    Write-Host ''
    Write-Host 'ISKORA Drive is ready.' -ForegroundColor Green
    Write-Host 'Run: flutter run'
    Write-Host 'Build: flutter build appbundle --release'
}
finally {
    Pop-Location
}
