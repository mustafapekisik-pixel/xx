$ErrorActionPreference = 'Stop'

$KeyStorePath = Join-Path $PSScriptRoot '..\iskora-upload.jks'
$Alias = 'iskora-upload'

if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    throw 'keytool bulunamadı. Android Studio JBR veya JDK 17 kurup terminali yeniden aç.'
}

$StorePassword = Read-Host 'Keystore password' -AsSecureString
$KeyPassword = Read-Host 'Key password (aynı olabilir)' -AsSecureString

$BSTR1 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($StorePassword)
$BSTR2 = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($KeyPassword)
try {
    $StorePlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR1)
    $KeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR2)

    & keytool -genkeypair `
        -v `
        -keystore $KeyStorePath `
        -alias $Alias `
        -keyalg RSA `
        -keysize 4096 `
        -validity 10000 `
        -storepass $StorePlain `
        -keypass $KeyPlain `
        -dname 'CN=ISKORA TECHNOLOGIES, OU=Software, O=ISKORA TECHNOLOGIES, L=Istanbul, ST=Istanbul, C=TR'

    if ($LASTEXITCODE -ne 0) { throw 'keytool başarısız oldu.' }

    $Base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($KeyStorePath))
    $Base64Path = Join-Path $PSScriptRoot '..\iskora-upload.base64.txt'
    Set-Content -Path $Base64Path -Value $Base64 -NoNewline

    Write-Host ''
    Write-Host 'Oluşturuldu:'
    Write-Host "  $KeyStorePath"
    Write-Host "  $Base64Path"
    Write-Host ''
    Write-Host 'GitHub Secrets:'
    Write-Host '  ISKORA_KEYSTORE_B64 = base64 txt içeriği'
    Write-Host "  ISKORA_KEY_ALIAS = $Alias"
    Write-Host '  ISKORA_STORE_PASSWORD = girdiğin keystore parolası'
    Write-Host '  ISKORA_KEY_PASSWORD = girdiğin key parolası'
    Write-Host ''
    Write-Host 'JKS dosyasını kaybetme. Sonraki Play Store güncellemeleri için gereklidir.'
}
finally {
    if ($BSTR1 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR1) }
    if ($BSTR2 -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR2) }
}
