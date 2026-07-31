# Android Release

## Package Bilgileri

- App name: `GlowBook`
- `applicationId`: `com.glowbook.app`
- `namespace`: `com.glowbook.app`
- `versionName` ve `versionCode`: `pubspec.yaml` version alanindan Flutter tarafindan uretilir.

## Network

`android/app/src/main/AndroidManifest.xml` icinde internet izni vardir:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Production API URL HTTPS olmalidir. HTTP sadece lokal development icin `--dart-define` ile kullanilmalidir.

## Signing

Gercek keystore veya signing password commit edilmez. Lokal veya CI secret olarak tutulur.

Ornek dosyalar commit edilmemelidir:

- `*.jks`
- `*.keystore`
- `android/key.properties`

Build ornekleri:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
```

## Release Oncesi Kontrol

- Launcher icon Flutter varsayilan ikonundan marka ikonuna cevrilmeli.
- Play Store icin release keystore ve signing config CI secret ile baglanmali.
- `minSdk`, `targetSdk`, `compileSdk` degerleri Android SDK ve plugin gereksinimleriyle uyumlu tutulmali.
