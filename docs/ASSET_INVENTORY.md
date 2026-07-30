# Asset Inventory

Kaynak repo: `.design-reference/glowbook-visualAssentManager-ui`

## Doğrudan Kullanılabilecek Assetler

Bu dosyalar `artifacts/mockup-sandbox/public/images` altında mevcut JPG görsellerdir. Flutter'a alınacaksa önerilen hedef klasör `flutter_app/assets/images/` olmalıdır.

| Asset | Boyut | Tasarımda kullanım | Flutter hedef kullanımı | Durum |
|---|---:|---|---|---|
| `glowbook-hero.jpg` | 131,977 bytes | Landing hero, lazer service fallback, Home hero | Welcome/Landing hero, Home hero, service visual | Kullanılabilir |
| `glowbook-hydrafacial.jpg` | 109,801 bytes | Hydrafacial service, Booking selected service | Service card/detail, booking flow | Kullanılabilir |
| `glowbook-lashes.jpg` | 105,601 bytes | İpek Kirpik service | Service card/detail | Kullanılabilir |
| `glowbook-nails.jpg` | 109,722 bytes | Kalıcı Oje service, CTA | Service card/detail, packages | Kullanılabilir |
| `glowbook-portrait-derya.jpg` | 104,136 bytes | Quote avatar, admin staff list | Avatar/profile placeholder | Kullanılabilir |
| `glowbook-portrait-elif.jpg` | 122,069 bytes | Booking employee, admin profile, quote avatar | Employee card/profile/avatar | Kullanılabilir |

## Tasarımda Referans Verilen Ama Eksik Assetler

| Asset | Nerede referanslanıyor | Etki | Öneri |
|---|---|---|---|
| `glowbook-salon.jpg` | `Home.tsx` yakın salon kartı | Salon kartı gerçek fotoğrafsız kalır | Yeni salon görseli üret veya `glowbook-hero.jpg` fallback kullan |
| Lazer epilasyon özel görseli | Prompt ve service category beklentisi | Lazer servis kartı generic hero kullanır | Ayrı asset ekle |
| Medikal cilt bakımı özel görseli | Prompt | Hydrafacial ile karışabilir | Ayrı asset ekle |
| Kaş/laminasyon görseli | Prompt | Kaş & kirpik kategorisi eksik görünebilir | Ayrı asset ekle |
| Manikür/Pedikür ayrı görselleri | Prompt | Nail services tek görsele düşer | Ayrı asset ekle |
| Salon/harita/konum görselleri | Landing/Home | Lokasyon deneyimi sınırlı | Harita/salon assetleri veya backend salon modeli gerekir |
| Device mockup/presentation board görselleri | Prompt içinde isteniyor | Flutter uygulama için gerekli değil | Ürün dokümanı için ayrı tasarım çıktısı olabilir |

## Dönüştürülmesi Gerekenler

| Kaynak | Dönüşüm | Neden |
|---|---|---|
| JPG fotoğraflar | Flutter `assets/images/` altına kopyala ve `pubspec.yaml` içine ekle | Flutter asset bundle içinde kullanılmaları gerekir |
| React `imagePath(...)` kullanımı | Flutter `Image.asset(...)` veya network/cache abstraction | React public path Flutter'da çalışmaz |
| lucide-react ikonları | Material Icons veya Flutter ikon paketi eşlemesi | React ikonları doğrudan kullanılamaz |
| CSS gradients/shadows | `BoxDecoration`, `LinearGradient`, `BoxShadow` | CSS doğrudan taşınamaz |
| CSS media query davranışları | `LayoutBuilder`, `MediaQuery`, `AppResponsive` | Flutter responsive modeline çevrilmeli |

## Kullanılmayacak Asset/Dosyalar

Bu dosyalar görsel UI asset'i değildir veya Flutter uygulamasına doğrudan taşınmamalıdır:

- `attached_assets/Pasted-Create-a-complete-high-resolution-production-ready-visu_1784898582678.txt`: tasarım prompt/metin belgesi.
- `artifacts/mockup-sandbox/src/components/**/*.tsx`: React mockup kaynakları. Referans alınır, kopyalanmaz.
- `artifacts/mockup-sandbox/src/components/ui/*`: Radix/shadcn web componentleri. Flutter'a doğrudan taşınmaz.
- `artifacts/mockup-sandbox/src/index.css`: genel web/Tailwind CSS. Sadece token/spacing referansı.
- `lib/api-client-react/*`: OpenAPI client React yardımcıları. Mevcut Flutter Dio servislerini değiştirmemeli.
- `lib/api-zod/*`: TypeScript/Zod şema üretimleri. Flutter modellerine doğrudan kaynak değildir.
- `lib/db/*`: Drizzle/Postgres şablonu. Spring Boot backend ile ilgisiz.
- `artifacts/api-server/*`: Express demo API server. GlowBook Spring Boot backend'i değildir.
- `scripts/*`: workspace scriptleri.

## Asset Kullanım Matrisi

| Flutter ekranı | Önerilen asset |
|---|---|
| Welcome/Landing | `glowbook-hero.jpg`, `glowbook-nails.jpg` |
| Home hero | `glowbook-hero.jpg` |
| Home popular services | `glowbook-hydrafacial.jpg`, `glowbook-nails.jpg`, `glowbook-lashes.jpg` |
| Services list | Service name mapping ile mevcut JPG'ler |
| Service Detail | Seçili service image; fallback `glowbook-hero.jpg` |
| Booking | `glowbook-hydrafacial.jpg`, `glowbook-portrait-elif.jpg` |
| Customer Dashboard | `glowbook-portrait-derya.jpg` veya generic avatar |
| Employee/Admin Dashboard | `glowbook-portrait-elif.jpg`, `glowbook-portrait-derya.jpg` |
| Notifications/Profile | Genelde ikon yeterli, avatar opsiyonel |

## Eksik Metadata

- Görsel çözünürlükleri bu analizde ölçülmedi; yalnızca dosya varlığı ve byte boyutu kontrol edildi.
- Görsel lisans/provenance bilgisi repo içinde açıkça belgelenmemiş.
- Flutter `pubspec.yaml` içinde şu anda bu tasarım assetleri tanımlı değil.

## Varsayımlar

- Mevcut JPG'lerin yayın/proje içi kullanım hakkı tasarım repo sahibine aittir.
- Assetler Flutter'a kopyalanmadan önce mümkünse dosya adları korunmalı; mapping kolaylaşır.
