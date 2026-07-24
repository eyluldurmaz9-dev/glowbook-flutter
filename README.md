# GlowBook Flutter Frontend

Bu repository, GlowBook servis yönetimi uygulaması için Flutter frontend iskeletini içerir. Flutter uygulaması aşağıdaki temel özelliklerle hazırlanmıştır:

- Riverpod tabanlı durum yönetimi
- GoRouter ile yönlendirme
- Dio ile API istemcisi ve JWT kimlik doğrulama desteği
- Flutter Secure Storage ile token saklama
- Pembe-beyaz bir tema ve temel yeniden kullanılabilir bileşenler
- Splash, Onboarding, Login, Register, Home, Services, Packages, Appointments, Notifications, Profile ve Settings sayfaları

## Proje yapısı

- `lib/main.dart`: Uygulama giriş noktası
- `lib/src/app.dart`: `MaterialApp.router` ve provider yapılandırması
- `lib/src/providers.dart`: uygulama genelindeki servis ve router sağlayıcıları
- `lib/src/routes/app_router.dart`: GoRouter rota tanımları
- `lib/src/services/`: API, token saklama ve kimlik doğrulama servisleri
- `lib/src/state/`: auth state yönetimi
- `lib/src/theme/`: uygulama teması
- `lib/src/widgets/`: yeniden kullanılabilir UI bileşenleri
- `lib/src/pages/`: ekran iskeletleri

## Geliştirme ortamı

1. Flutter SDK kurulu olmalı
2. `flutter_app` klasörüne git:

```powershell
cd "c:\Users\Lenovo\OneDrive\Desktop\proje\flutter_app"
```

3. Paketleri yükle:

```powershell
flutter pub get
```

4. Uygulamayı çalıştır:

```powershell
flutter run
```

## GitHub ve yapı

Bu proje `main` dalında tutulmaktadır ve Flutter uygulaması `flutter_app` klasöründe bağımsız bir repository olarak yapılandırılmıştır.

## Notlar

- Mevcut kod temel bir iskelet sağlar; gerçek backend URL ve kimlik doğrulama yanıtları backend servisleriyle uyumlu olmalıdır.
- `lib/src/services/auth_service.dart` ve `lib/src/services/api_client.dart` dosyaları JWT token yönetimi için hazırlandı.
- Mülakatlarda tercih edilen formatta proje dosya yapısı ve README temiz tutuldu.

## İleri adımlar

- Backend API endpoint’leri ile test et
- Tasarımı Figma’dan aldığın görsel stile göre geliştir
- Android / iOS native yapılandırmaları tamamla
