# GlowBook Design System

Bu doküman `.design-reference/glowbook-visualAssentManager-ui/artifacts/mockup-sandbox/src/components/mockups/glowbook/_shared/glowbook.css` ve ilgili React mockup dosyalarından çıkarılmıştır.

## Teknoloji Kaynağı

Tasarım deposu:

- pnpm workspace
- Vite
- React
- TypeScript
- Tailwind CSS
- Radix UI component primitives
- lucide-react ikonları
- Recharts, Framer Motion, Sonner gibi web/prototip bağımlılıkları

Flutter tarafı:

- Flutter Material Design 3
- Riverpod
- GoRouter
- Dio
- Google Fonts

React/Tailwind kodu Flutter'a doğrudan kopyalanmamalıdır. Tasarım tokenları ve layout davranışı Flutter widget'larına çevrilmelidir.

## Renkler

| Token | Hex | Kullanım |
|---|---:|---|
| `gb-ink` | `#30292D` | Ana metin |
| `gb-muted` | `#82757B` | İkincil metin |
| `gb-rose` | `#EC5A8C` | Primary aksiyon, aktif tab, seçili kart, progress |
| `gb-blush` | `#FFD1DC` | Marka işareti, soft ikon yüzeyleri |
| `gb-petal` | `#FFF8FB` | Soft card, hero yüzeyi, auth gradient |
| `gb-gold` | `#D4AF37` | Premium/aktif paket/puan vurgusu |
| `gb-line` | `#F1E8EC` | Border |
| `gb-green` | `#4E8A71` | Onaylandı/başarılı badge |
| White | `#FFFFFF` | Ana zemin |
| Error | `#D32F2F` | Flutter hata state'i |

Flutter'daki mevcut karşılıklar:

- `AppColors.primary = #EC5A8C`
- `AppColors.blush = #FFD1DC`
- `AppColors.petal = #FFF8FB`
- `AppColors.primaryText = #30292D`
- `AppColors.secondaryText = #82757B`
- `AppColors.border = #F1E8EC`
- `AppColors.goldAccent = #D4AF37`

## Tipografi

Tasarım:

- Body: `DM Sans`
- Serif/display başlık: `Playfair Display`
- Büyük hero başlıkları: 52-84px desktop, 50-55px tablet/mobile landing
- Mobil sayfa başlığı: 25px, line-height 1.08
- Auth başlığı: 34px
- Card/list başlıkları: 12-16px
- Body metinleri: 10-16px
- Eyebrow: 10px, uppercase, letter-spacing `.18em`, font-weight 700

Flutter mevcut:

- `GoogleFonts.dmSansTextTheme(base)` tabanı var.
- Bazı özel stiller hâlâ `Poppins` kullanıyor. Uygulama aşamasında DM Sans/Playfair hissi tekilleştirilmeli.
- Flutter'da Playfair Display kullanılacaksa `google_fonts` zaten mevcut; ekstra paket gerekmiyor.

## Spacing

Tasarım değerleri:

- Mobil shell iç boşluk: `25px 20px 106px`
- Auth ekranı dış padding: `28px 20px 22px`
- Auth kart padding: `27px 24px 23px`
- Button padding: `13px 19px`
- Search padding: `13px 14px`
- Service row padding: `10px`
- Selection row padding: `14px`
- Admin main padding: `30px 34px 40px`
- Desktop shell padding: `0 48px`
- Tablet shell padding: `0 24px`
- Mobile landing shell padding: `0 18px`

Flutter karşılığı:

- `AppSpacing` şu anda `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=20`, `xxl=24`.
- Tasarım ile uyum için 8px grid korunmalı; özel bileşenlerde 9/10/13/14/17/18/20/21/24 değerleri kullanılabilir.

## Radius

| Eleman | Radius |
|---|---:|
| Primary button | 14px |
| Input | 13px |
| Icon button | 13px |
| Brand mark | `13 13 13 4` |
| Card | 22px |
| Soft card | 22px |
| Auth card | 28px |
| Auth mark | `17 17 17 5` |
| Service tile | 24px |
| Home hero | 25px |
| Service detail bottom sheet | `26 26 0 0` |
| Success mark | `30 30 30 8` |
| Large hero photo | `34 34 100 34` |
| CTA photo | `30 30 30 110` |
| Pills | 100px |

## Elevation ve Shadow

Tasarım:

- Global rich shadow: `0 20px 60px rgba(104,65,78,.10)`
- Card shadow: `0 10px 34px rgba(72,40,55,.05)`
- Auth card: `0 24px 70px rgba(104,65,78,.11)`
- Primary button: `0 12px 24px rgba(236,90,140,.22)`
- Success mark: `0 18px 30px rgba(236,90,140,.25)`

Flutter:

- Material elevation yerine çoğu premium yüzey için `BoxShadow` önerilir.
- Cards `elevation: 0` kalmalı, shadow `Container` dekorasyonunda verilmeli.

## Componentler

### Brand

- `Brand`: sparkle icon + GlowBook text.
- Flutter karşılığı: `GlowBrand`, `GlowMark`.

### Buttons

- Primary: rose background, white text, 14px radius, bold.
- Soft: petal background, rose text.
- Ghost: transparent/white, line border.
- Flutter: `GlowButton` primary için; soft/ghost için `OutlinedButton` veya özel varyant gerekir.

### Cards

- White surface, `gb-line` border, 22px radius, soft shadow.
- Soft card: petal background, 22px radius, `#F9E8EF` border.
- Flutter: `GlowCard`, `GlowSoftNotice`.

### Forms

- Input: white background, line border, 13px radius, icon trailing/leading.
- Focus: rose border + subtle rose focus ring.
- Auth card içinde label font 10px bold.

### Navigation

- Mobile bottom nav: max width 430px, fixed bottom, white rgba/backdrop blur, active rose.
- Items: Ana Sayfa, Keşfet/Hizmetler, Randevular, Bildirimler, Profil.
- Flutter: `GlowBottomNavigationBar` Material `NavigationBar` ile uyarlanmış.

### Badges / Pills

- Rose: `#FFF0F5` + `#EC5A8C`
- Green: `#EDF7F1` + `#4E8A71`
- Gold: `#FFF7DF` + `#96751F`

### Appointment Flow

- 6 adım: Hizmet, Alt hizmet, Paket, Personel, Tarih, Saat.
- Step circle: 21px.
- Date chip: min width 55px, radius 15px.
- Time grid: 3 kolon, gap 8px, selected rose.
- Sticky action: mobile bottom, width `min(430px,100%)`.

### Admin Dashboard

- Desktop layout: 240px sidebar + content.
- Tablet: sidebar 72px, labels hidden.
- Mobile: compact content, stats 2 kolon, panels 1 kolon.
- Chart: 200px high bar chart, selected bar rose, inactive blush.

## Responsive Breakpointler

Tasarım CSS:

- `max-width: 900px`: desktop admin sidebar daralır, hero iki kolon kalır ama sıkışır.
- `max-width: 640px`: landing tek kolon, nav linkleri gizlenir, service grid 2 kolon, admin grid 2/1 kolon.

Flutter mevcut:

- `AppResponsive.isMobile`: `<700`
- `isTablet`: `700-1099`
- `isDesktop`: `>=1100`
- `GlowResponsivePage`: `<600` ise maxWidth 430, aksi halde maxWidth parametresi.

Öneri:

- Tasarım referansına yaklaşmak için Flutter breakpointlerini aşamada şöyle kullan:
- Mobile: `<640`
- Tablet: `640-899`
- Desktop: `>=900`
- Wide desktop content max: 1100-1440 arası, ekrana göre.

## Varsayımlar

- Tasarımdaki negatif letter spacing Flutter'da birebir kullanılmamalı; mevcut proje talimatları letter spacing'i sınırlıyor. Serif/display hissi font weight ve line-height ile yaklaştırılmalı.
- Fotoğraf tabanlı zenginlik için tasarım repo'daki JPG'ler kullanılabilir; telif/kullanım izinleri repo kapsamına ait kabul edilmiştir, ancak yayın öncesi lisans doğrulanmalıdır.
