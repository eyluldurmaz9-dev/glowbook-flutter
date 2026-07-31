# iOS Release

## Gereksinimler

- macOS
- Xcode
- CocoaPods
- Apple Developer account
- App Store Connect kaydi

Windows ortaminda gercek iOS release build calistirilamaz.

## Bundle Bilgileri

- Display name: `Glowbook Flutter` mevcut Info.plist degeridir; release oncesi Xcode'da `GlowBook` olarak netlestirilmelidir.
- Bundle identifier Xcode build settings uzerinden `PRODUCT_BUNDLE_IDENTIFIER` ile gelir.
- Onerilen bundle identifier: `com.glowbook.app`

## Build

```bash
flutter build ios --release --no-codesign --dart-define=API_BASE_URL=https://api.example.com
```

Codesign/App Store arsiv icin:

```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://api.example.com
```

## Signing

- Certificate, provisioning profile, API key ve password commit edilmez.
- CI kullanilacaksa signing degerleri platform secret olarak tutulmalidir.

## Privacy

Bu uygulamada su an kamera, konum, mikrofon veya foto galeri gibi privacy-sensitive izinler tanimli degil. Yeni native izin eklendiginde `Info.plist` aciklama metinleri release oncesi eklenmelidir.
