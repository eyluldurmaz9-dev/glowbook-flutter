# GlowBook Flutter

GlowBook Flutter uygulamasi Android, iOS ve Flutter Web hedefleri icin hazirlanmis frontend uygulamasidir. Uygulama Spring Boot backend ile Dio, secure storage ve Riverpod tabanli state management uzerinden konusur.

## Gereksinimler

- Flutter stable SDK
- Dart SDK, Flutter ile birlikte gelir
- Android Studio ve Android SDK
- iOS build icin macOS ve Xcode

Windows uzerinde Flutter plugin symlinkleri icin Developer Mode acik olmalidir. Projeyi OneDrive disinda bir klasorde calistirmak release build icin daha guvenilirdir.

## Ortam Ayarlari

Gercek secret veya production URL commit edilmez. Lokal degerler icin `.env.example` dosyasini referans alin ve degerleri shell, CI secret veya Vercel environment variables icinde tutun.

Development:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Staging:

```powershell
flutter run --dart-define=API_BASE_URL=https://staging-api.example.com
```

Production web build:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com --base-href=/
```

## Kalite Kontrolleri

```powershell
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com --base-href=/
```

Android release build:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
```

## Deployment

- Vercel web deployment: `vercel.json`
- Flutter deployment rehberi: `docs/DEPLOYMENT_FLUTTER.md`
- Android release rehberi: `docs/ANDROID_RELEASE.md`
- iOS release rehberi: `docs/IOS_RELEASE.md`

## Guvenlik

- Token, JWT, SMS credential, database password ve production URL commit etmeyin.
- `.env` dosyalari `.gitignore` icindedir.
- Production backend URL degeri `--dart-define=API_BASE_URL=...` ile verilmelidir.
- Debug loglarda token veya kullanici verisi yazdirilmamalidir.
