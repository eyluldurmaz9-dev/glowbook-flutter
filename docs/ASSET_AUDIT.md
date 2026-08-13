# GlowBook Görsel ve Asset Denetimi

## Aktif kaynaklar

- Marka: `assets/images/branding/glowbook-official-logo.png` ve platform için yazısız `glowbook-platform-icon.png`.
- Marka varlıkları yalnızca logo, favicon ve işletim sistemi ikonlarında kullanılır.
- Hizmet/paket içeriği `ServiceImageResolver` ve `PackageImageResolver` üzerinden çözülür.
- `pubspec.yaml` bütün `assets/images/` ağacını bildirir; dosya adlarının büyük/küçük harfi diskteki yollarla aynıdır.

## Düzeltilen kusurlar

1. Lazer, Masaj/Spa ve Bölgesel İncelme aynı genel salon görseline düşüyordu; üç ayrı semantik asset eklendi.
2. Tırnak hizmet/paket kayıtlarının üretimde boş görüntüsü vardı; nail assetine bağlandı.
3. Saç ve Makyaj için genel salon yerine kategori fallbackleri eklendi.
4. Landing hero fotoğrafı Hakkımızda bölümünde ikinci kez büyük boy gösteriliyordu; Hakkımızda görseli cilt bakımı fotoğrafıyla ayrıştırıldı.
5. Paket resolver'ı eski örnek ID'leri varsayıyordu; 1–15 üretim paket ID'leri kesin eşlemeye alındı.
6. Paket detay ekranı seçilen paketin `package.image` alanını zaten kullanıyordu; bu davranış regresyon testleriyle korunur.

## Android ikon kök nedeni

Depodaki `main` kaynak seti `@mipmap/ic_launcher` ve `@mipmap/ic_launcher_round` kullanır; legacy PNG'ler ile Android 8+ adaptive foreground GlowBook işaretidir. Başka flavor/source setinde launcher override bulunmamıştır ve `flutter_launcher_icons` yapılandırması yoktur. Bu nedenle fiziksel cihazdaki mavi Flutter logosu mevcut kaynak koddan değil, cihazda önceki APK'nın kurulu kalmasından veya launcher önbelleğinden gelir. Yeni release APK kaldırma/yeniden kurma sonrasında doğrulanmalıdır.

## Üretilen kategori assetleri

Built-in image generation kullanıldı. İnsan bedeni göstermeyen, ürün/ortam odaklı son istemler; lazer cihazı, spa odası, vücut bakım cihazı, saç ekipmanı ve makyaj setini GlowBook'un blush/cream/rose-gold estetiğinde, logosuz ve yazısız üretir. Son dosyalar:

- `assets/images/glowbook-laser.png`
- `assets/images/glowbook-spa.png`
- `assets/images/glowbook-body-treatment.png`
- `assets/images/glowbook-hair.png`
- `assets/images/glowbook-makeup.png`

Tam üretim eşlemeleri `SERVICE_IMAGE_MAPPING.md` ve `PACKAGE_IMAGE_MAPPING.md` içindedir.