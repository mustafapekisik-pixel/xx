# ISKORA Fermata Build

Bu depo, resmî açık kaynak [AndreyPavlenko/Fermata](https://github.com/AndreyPavlenko/Fermata) kaynağını indirip **benzersiz paket kimliğiyle** AAB üretmek için hazırlanmıştır.

## Sabit kimlikler

- Geliştirici markası: **ISKORA TECHNOLOGIES**
- Uygulama adı: **ISKORA Fermata Test**
- Temel application ID: `com.iskora.fermata`
- Auto sürümünün nihai paket kimliği: `com.iskora.fermata.auto`

Fermata'nın `auto` flavor'ı temel kimliğe `.auto` eklediği için Play Console'da oluşturulacak uygulamanın paket adı tam olarak `com.iskora.fermata.auto` olmalıdır.

## GitHub Actions ile AAB üretme

1. Depoda **Actions** sekmesine gir.
2. **Build ISKORA Fermata AAB** iş akışını aç.
3. **Run workflow** seçeneğine bas.
4. İlk yüklemede varsayılan `versionCode` ve `versionName` değerlerini kullanabilirsin.
5. İş bitince **Artifacts** bölümünden `iskora-fermata-play-upload` dosyasını indir.

İlk çalıştırmada iş akışı yeni bir upload key üretir. Artifact içinde şunlar bulunur:

- Google Play'e yüklenecek `.aab`
- `iskora-upload.jks`
- `upload-key-info.txt`
- `build-info.txt`

**JKS dosyasını ve şifre dosyasını güvenli yerde sakla.** Aynı Play Console uygulamasının sonraki sürümlerini yüklemek için aynı upload key gerekir.

## Sonraki derlemelerde aynı imzayı kullanma

İlk artifact'tan aldığın JKS dosyasını Base64'e çevirip repo secrets olarak ekle:

- `ISKORA_KEYSTORE_B64`
- `ISKORA_STORE_PASSWORD`
- `ISKORA_KEY_ALIAS`
- `ISKORA_KEY_PASSWORD`

Windows PowerShell'de Base64 üretme:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\iskora-upload.jks")) | Set-Clipboard
```

GitHub'da: **Settings → Secrets and variables → Actions → New repository secret**.

## Play Console

Internal test uygulaması oluştururken paket adı:

```text
com.iskora.fermata.auto
```

Yeni sürüm yüklerken `versionCode` değerini mutlaka artır.

## Güvenlik ve politika sınırı

Bu yapı yalnızca benzersiz paket kimliği, adlandırma, sürümleme ve imzalı AAB üretimini otomatikleştirir. Android Auto'nun hareket hâlindeki güvenlik kısıtlamalarını kaldırmaz ve uygulamayı yanlış bir kategori altında yayımlamak için değişiklik yapmaz. Araç ekranındaki video özellikleri yalnızca güvenli biçimde park hâlindeyken test edilmelidir.

## Lisans ve atıf

Fermata GPL-3.0 lisanslıdır. Değiştirilmiş ikili dosyayı başkalarına dağıtırsan ilgili kaynak kodunu ve GPL-3.0 lisans bildirimini erişilebilir tutman gerekir. Bu depo Fermata'nın resmî geliştiricisiyle bağlantılı değildir.
