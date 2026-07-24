# ISKORA Drive

Profesyonel Flutter telefon arayüzü ile native Kotlin/Media3 oynatma çekirdeğini birleştiren hibrit Android medya uygulaması.

## Kimlik

- Uygulama adı: **ISKORA Drive**
- Geliştirici markası: **ISKORA TECHNOLOGIES**
- Application ID: `com.iskora.drive`
- Minimum Android: API 28
- Hedef Android: API 36

Kullanıcıya görünen alanlarda veya paket kimliğinde `fermata.auto` bulunmaz.

## Mimari

```text
Flutter
├── Material 3 responsive telefon arayüzü
├── Riverpod durum yönetimi
├── GoRouter navigasyon
└── MethodChannel / EventChannel

Native Android (Kotlin)
├── Media3 ExoPlayer
├── MediaLibraryService
├── MediaLibrarySession
├── Arka plan oynatma
├── Sistem medya kontrolleri
└── Android Auto'nun sürücü güvenli medya arayüzü
```

Flutter yalnızca telefon ekranını çizer. Arka plan oynatma, medya oturumu, bildirimler ve Android Auto bağlantısı Kotlin tarafında kalır.

## Windows kurulumu

Flutter SDK ve Git kurulu olmalıdır.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_flutter.ps1
```

Script eksik Flutter platform dosyalarını oluşturur, proje kaynaklarını geri yükler, paketleri indirir, analiz ve testleri çalıştırır.

Ardından:

```powershell
flutter run
```

## AAB üretme

Yerel test derlemesi:

```powershell
flutter build appbundle --release
```

Çıktı:

```text
build/app/outputs/bundle/release/app-release.aab
```

GitHub'da **Flutter Native CI** iş akışı analiz, test ve AAB üretimini otomatik yapar. CI'daki varsayılan imza yalnızca teknik doğrulama içindir; Play Console'a yüklemeden önce kendi upload key dosyanı `android/key.properties` ile bağla.

## Upload key örneği

`android/key.properties`:

```properties
storePassword=CHANGE_ME
keyPassword=CHANGE_ME
keyAlias=iskora-upload
storeFile=C:\\secure\\iskora-upload.jks
```

JKS dosyasını ve parolaları repoya ekleme.

## İlk çalışan kapsam

- Responsive Material 3 ana ekran
- Açık/koyu sistem teması
- HTTPS ses akışı açma
- Flutter ↔ Kotlin medya komutları
- Media3 arka plan servisi
- Play/pause/önceki/sonraki kontrolleri
- Android Auto medya keşif bildirimi
- Birim testi ve CI derlemesi

Sonraki katmanlar: yerel klasör tarama, kalıcı medya veritabanı, oynatma listeleri, favoriler, IPTV kaynak yönetimi, ses efektleri ve Android Auto içerik ağacı.

## Güvenlik ve araç kullanımı

Android Auto araç ekranında kendi onaylı ve sürücü güvenli medya arayüzünü kullanır. Proje hareket hâlinde video gösterme veya araç güvenlik kilitlerini kaldırma amacı taşımaz. Telefon tarafındaki görsel medya özellikleri araç güvenli biçimde park hâlindeyken kullanılmalıdır.

## Açık kaynak geçişi

Fermata'dan işlev veya kod taşınacak bölümler ayrı commitlerde incelenecek ve GPL-3.0 yükümlülükleri korunacaktır. Mevcut temel, Flutter arayüzü ve native Media3 bağlantısı için temiz bir başlangıç katmanıdır.
