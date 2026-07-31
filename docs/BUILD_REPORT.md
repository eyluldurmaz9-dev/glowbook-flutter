# GlowBook Flutter Build Report

Tarih: 2026-07-31

## Android

| Komut | Sonuc | Not |
| --- | --- | --- |
| `flutter build apk --release --no-pub` | Basarisiz | Ilk denemelerde Gradle/OneDrive dosya kilidi nedeniyle zaman asimi ve generated build klasoru silme hatalari goruldu. |
| `flutter build appbundle --release --no-pub` | Basarisiz, duzeltme uygulandi | `connectivity_plus` AAR metadata kontrolu, plugin tarafinda `compileSdk 33` ile AndroidX bagimliliklarinin `compileSdk >= 34` istemesi nedeniyle dustu. `android/app/build.gradle.kts` icinde app `compileSdk` degeri 36 olarak sabitlendi. |
| `flutter build apk --release` | Basarisiz | `flutter clean` sonrasinda Windows Developer Mode/symlink destegi eksikligi ve OneDrive reparse point kilidi nedeniyle Flutter tool baslayamadi. |
| `flutter build appbundle --release` | Basarisiz | Ayni Flutter tool/ephemeral izin engeli. |

## Flutter Web

| Komut | Sonuc | Not |
| --- | --- | --- |
| `flutter build web --release --no-pub` | Basarili | `build/web` olustu. Wasm dry-run uyarilari `flutter_secure_storage_web` ve `connectivity_plus` paketlerinin web implementasyonlarindan kaynaklandi; klasik Flutter Web release build basariliydi. |
| `flutter build web --release` | Basarisiz | Clean sonrasinda Flutter plugin symlink kurulumu yapilamadigi icin tekrar calistirilamadi. |

Web build buyuk dosyalar:

- `build/web/canvaskit/canvaskit.wasm`: yaklasik 6.9 MB.
- `build/web/main.dart.js`: yaklasik 3.2 MB.
- CanvasKit/Wasm runtime dosyalari web bundle boyutunun ana parcasini olusturuyor.

## iOS

- Ortam Windows oldugu icin gercek iOS release build calistirilmadi.
- `ios/Runner.xcodeproj`, `ios/Runner.xcworkspace`, `ios/Runner/` ve `ios/RunnerTests/` dizinleri mevcut.
- Gercek iOS dogrulamasi icin macOS, Xcode, CocoaPods ve uygun signing/codesign ayarlari gerekir.
- Windows ortaminda `flutter build ios --release --no-codesign` calistirildigi iddia edilmedi.

## Release Notlari

- Android release signing su an proje varsayilanlarina bagli. Play Store icin gercek release keystore/signing configuration gereklidir.
- `applicationId` release oncesi marka alan adina gore netlestirilmelidir; mevcut deger proje iskeletinden gelebilir.
- Flutter build zincirinin tekrar calismasi icin Windows Developer Mode acilmali veya proje OneDrive disinda, symlink destekleyen bir klasore tasinmalidir.
