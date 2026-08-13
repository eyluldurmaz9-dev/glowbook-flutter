# GlowBook Platform Marka Güncellemesi

## Resmî kaynak ve ikon ana dosyası

Resmî tam logo `assets/images/branding/glowbook-official-logo.png` olarak korunur. Küçük işletim sistemi ve tarayıcı ikonlarında yazılar okunmaz hâle gelmesin diye aynı onaylı logodaki kadın profili, `S/B`, takvim ve yapraklardan oluşan merkez işaret; yazısız ve güvenli maske boşluklu olarak `assets/images/branding/glowbook-platform-icon.png` dosyasına türetildi. Bu varlık yalnızca marka/platform ikonu içindir; hizmet, paket, personel veya müşteri görseli değildir.

## Web ve PWA

- `web/favicon.png`: 64×64 tarayıcı sekmesi ikonu.
- `web/icons/Icon-192.png` ve `Icon-512.png`: PWA kurulum ikonları.
- `web/icons/Icon-maskable-192.png` ve `Icon-maskable-512.png`: maskable PWA ikonları.
- `web/index.html`: favicon ve Apple touch icon referanslarına `v=20260813` önbellek sürümü eklendi.
- `web/manifest.json`: 192, 512 ve maskable dosyalarını aktif olarak kullanır.

## Android

- `mipmap-mdpi`–`mipmap-xxxhdpi`: standart `ic_launcher.png` ve `ic_launcher_round.png` boyutları yenilendi.
- Android 8+ için `mipmap-anydpi-v26/ic_launcher.xml` ve `ic_launcher_round.xml` adaptive icon tanımları eklendi.
- Adaptive foreground `drawable-nodpi/ic_launcher_foreground.png`, arka plan rengi `#FAE4E8` olarak tanımlandı.
- `AndroidManifest.xml`, normal ve yuvarlak launcher ikonlarını kullanır. Android recent-app/task görünümü uygulama ikonunu manifestten aldığı için ayrıca eski bir referans yoktur.
- Splash XML dosyalarında logo aktif değildir; yorum satırındaki örnek `launch_image` referansı çalışma zamanında kullanılmaz ve splash tasarımı değiştirilmedi.

## iOS, macOS ve Windows

- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` içindeki tüm `Contents.json` boyutları opak merkez işaretten yeniden üretildi. Windows ortamında fiziksel iOS cihaz/simülatör doğrulaması yapılamaz.
- Aktif eski masaüstü markası kalmaması için macOS AppIcon seti ve Windows `app_icon.ico` da aynı merkez işaretle güncellendi.

## Önbellek ve kurulum doğrulaması

### Web

1. Yeni dağıtım tamamlandıktan sonra sayfada `Ctrl+F5` ile sert yenileme yapın.
2. Eski ikon sürerse tarayıcının GlowBook site verilerini/cache'ini temizleyin.
3. Kurulu PWA eski ikonu tutarsa PWA'yı kaldırıp yeniden yükleyin.

### Android

1. Eski GlowBook uygulamasını cihazdan kaldırın; launcher bazı cihazlarda ikonu paket adına göre önbellekler.
2. Yeni release APK'yı yeniden kurun.
3. Ana ekran ve son uygulamalar görünümünde yeni merkez işareti doğrulayın.

Paket kimliği yalnızca önbelleği aşmak amacıyla değiştirilmemiştir.
## Fiziksel cihazdaki Flutter ikonu — kesin kök neden

Aktif `main` manifesti `@mipmap/ic_launcher` ve `@mipmap/ic_launcher_round` kaynaklarını kullanır. mdpi–xxxhdpi PNG'leri ve Android 8+ `@drawable/ic_launcher_foreground` dosyası GlowBook merkez işaretidir; debug/profile manifestlerinde ikon override'ı, başka flavor veya `flutter_launcher_icons` kaynağı yoktur. Dolayısıyla fiziksel cihazdaki mavi Flutter logosu güncel kaynaklardan üretilemez. Cihazda önceki APK kurulu kalmıştır veya launcher paket ikonunu önbellekte tutmaktadır. `flutter clean` sonrası üretilen yeni release APK kaldırma/yeniden kurma ile test edilmelidir.

Önce: cihazdaki eski APK → mavi varsayılan Flutter launcher ikonu.

Sonra: güncel release APK → blush/rose-gold GlowBook merkez işareti; legacy, round ve adaptive kaynakların tamamı aynı kimliği kullanır.
