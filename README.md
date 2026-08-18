# GlowBook Flutter

GlowBook Flutter, GlowBook randevu ve salon yonetim sisteminin Android, iOS ve Flutter Web istemcisidir. Uygulama Spring Boot backend ile mevcut REST API mimarisi, Dio client, secure storage ve Riverpod tabanli state management uzerinden haberlesir.

Tasarim dili `glowbook-visualAssentManager-ui` deposundaki UI/UX referansindan Flutter widget'lari ile yeniden olusturulmustur. Tasarim deposundaki React/web kodu bu projeye kopyalanmaz.

## Ozellikler

- Splash, tanitim, login, register, misafir devam ve rol bazli yonlendirme
- Musteri ana sayfasi, hizmetler, hizmet detaylari, paketler ve paket detaylari
- Randevu olusturma, uygun slot secimi, personel secimi, ozet ve onay akisi
- Musteri paneli: randevular, paketler, bildirimler, profil ve logout
- Personel paneli: gunluk randevular, haftalik takvim, durum guncelleme, bildirimler ve profil
- Admin web paneli: hizmet, kategori, paket, personel ve randevu yonetimi; backend'in destekledigi kapsamla sinirlidir
- Loading, empty, error, validation ve retry durumlari
- Android, iOS ve Flutter Web icin responsive Material Design 3 arayuz

## Kullanilan Teknolojiler

- Flutter ve Dart
- Material Design 3
- Dio HTTP client
- Flutter secure storage
- Riverpod state management
- Flutter test altyapisi
- Vercel Flutter Web deployment

## Gereksinimler

- Flutter stable SDK
- Dart SDK, Flutter ile birlikte gelir
- Android Studio ve Android SDK
- Web build icin Chrome veya uyumlu Flutter web toolchain
- iOS build icin macOS, Xcode ve Apple signing yetkileri

Windows uzerinde Flutter plugin symlinkleri icin Developer Mode acik olmalidir. OneDrive icindeki calisma klasorleri bazi Flutter generated dosyalarinda silme/erisim problemi olusturabilir; release build icin OneDrive disinda kisa bir path onerilir.

## Local Kurulum

```powershell
cd flutter_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Flutter Web icin:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

## Environment Yapilandirmasi

Gercek secret, token, SMS credential veya production URL commit edilmez. `.env.example` yalnizca beklenen anahtar isimlerini gosterir. Runtime API adresi `--dart-define` ile verilir.

Development:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Staging:

```powershell
flutter run --dart-define=API_BASE_URL=https://staging-api.example.com
```

Production:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com --base-href=/
```

## Backend Baglantisi

Backend reposu: `glowbook-backend` / mevcut remote adiyla `Glowbook`.

Flutter istemcisi backend'e asagidaki ana alanlarda baglanir:

- Authentication: login, register, refresh token
- Catalog: services, service options, packages
- Appointment: available slots, create, detail, cancel, update
- Waiting list
- Customer profile, customer packages
- Employee appointments
- Notifications
- Admin services, packages, employees, schedules

Endpoint sozlesmesi icin backend reposundaki `docs/API_REFERENCE.md` dosyasina bakin.

## Test Komutlari

```powershell
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Android Build

APK:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

Play Store app bundle:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
```

Signing icin `docs/ANDROID_RELEASE.md` dosyasindaki adimlari izleyin. Keystore ve sifreleri repository'ye commit etmeyin.

## Flutter Web Build

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com --base-href=/
```

SPA route rewrite ayarlari `vercel.json` icindedir.

## Vercel Deployment

Production frontend URL: `https://glowbook-flutter.vercel.app`

Vercel'de proje root'u `flutter_app` olacak sekilde ayarlanir. Repository Vercel'e baglandiginda `package.json` Vercel tarafindan algilanir ve `vercel.json` icindeki build komutu calisir.

- Install command: `npm install`
- Build command: `npm run vercel-build`
- Output directory: `build/web`
- Required environment variable: `API_BASE_URL`

`scripts/vercel-build.sh`, Vercel build ortaminda `flutter` komutu yoksa Flutter stable SDK'yi otomatik olarak `$HOME/flutter` altina kurar, web destegini acar, paketleri indirir ve production build uretir:

```bash
flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL --base-href=/
```

Vercel environment variable ornegi:

```text
API_BASE_URL=https://api.your-production-domain.com
```

Preview veya staging deployment icin Vercel'de ayni anahtari ilgili environment'a farkli degerle tanimlayabilirsiniz. `API_BASE_URL` bos ise production build bilincli olarak durdurulur.

SPA routing icin tum route'lar `index.html` dosyasina rewrite edilir; bu sayede `/login`, `/services` veya panel route'lari refresh edildiginde 404 alinmaz. Static assetler Flutter'in `build/web` cikti dizini ve root `--base-href=/` ayari ile servis edilir.

Detaylar: `docs/DEPLOYMENT_FLUTTER.md`

## iOS

iOS build Windows ortaminda dogrulanamaz. Gercek build icin macOS, Xcode, CocoaPods ve Apple Developer signing gerekir.

```bash
flutter build ios --release --no-codesign --dart-define=API_BASE_URL=https://api.example.com
```

Signing ve bundle identifier kontrol listesi: `docs/IOS_RELEASE.md`

## Proje Klasor Yapisi

- `lib/`: uygulama kodu, ekranlar, state, servisler ve ortak UI
- `test/`: unit ve widget testleri
- `assets/`: Flutter asset dosyalari
- `android/`: Android native proje dosyalari
- `ios/`: iOS native proje dosyalari
- `web/`: Flutter Web giris dosyalari
- `docs/`: mimari, release, test, deployment ve teslim belgeleri

## Guvenlik Notlari

- JWT access token ve refresh token loglanmaz.
- Kullanici profili, sifre, token ve SMS credential debug ciktilarina yazilmaz.
- `.env` dosyalari `.gitignore` icindedir.
- Production backend URL degeri repository yerine CI/Vercel environment variable olarak tutulur.
