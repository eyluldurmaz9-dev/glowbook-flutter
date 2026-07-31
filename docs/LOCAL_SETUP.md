# GlowBook Flutter Local Setup

## On Kosullar

- Flutter stable SDK
- Android SDK
- Chrome veya uyumlu web runtime
- Backend API'nin lokal veya uzak ortamda calisiyor olmasi

## Kurulum

```powershell
cd flutter_app
flutter pub get
```

Android emulator icin:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Web icin:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

## Test ve Build

```powershell
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com --base-href=/
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
```

## Windows Notu

Bu calisma ortaminda Flutter komutlari OneDrive altindaki `ios/Flutter/ephemeral` generated klasorunde erisim/silme hatasina takilabilir. Boyle bir durumda projeyi OneDrive disinda kisa bir path'e tasiyip `flutter clean` ve `flutter pub get` sonrasinda komutlari tekrar calistirin.
