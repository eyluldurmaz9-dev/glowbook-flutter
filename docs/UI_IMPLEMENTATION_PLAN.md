# UI Implementation Plan

Bu plan yalnızca analiz çıktısıdır. Bu aşamada kodlama yapılmamalıdır.

## Hedef

`glowbook-visualAssentManager-ui` içindeki Replit mockup tasarımını, mevcut `glowbook-flutter` mimarisini ve çalışan Spring Boot API entegrasyonlarını bozmadan Flutter widget'larıyla yeniden oluşturmak.

## Korunacak Mimari

- `lib/main.dart -> lib/app.dart -> lib/core/routes/app_router.dart`
- Riverpod provider yapısı: `lib/providers/app_providers.dart`
- API istemcisi: `lib/core/api/api_client.dart`
- Backend servis yüzeyi: `lib/core/services/glow_backend_service.dart`
- Storage: `lib/core/storage/secure_storage_service.dart`
- Mevcut endpoint path'leri ve DTO beklentileri.

## Uygulama Sırası

### 1. Asset hazırlığı

- Tasarım repo'daki kullanılabilir JPG'leri Flutter `assets/images/` altına kopyala.
- `pubspec.yaml` içinde asset path'lerini tanımla.
- Web/Android/iOS için asset render kontrolü yap.
- Eksik `glowbook-salon.jpg` gibi referansları ya yeni asset ile tamamla ya da fallback gradient/icon tasarla.

Bağımlılık: `ASSET_INVENTORY.md`.

### 2. Design token temizliği

- `AppColors` değerlerini tasarım tokenlarıyla birebir tut.
- `AppTypography` içinde DM Sans body ve Playfair Display benzeri display stili için helper oluştur.
- `AppSpacing` değerlerini 4/8/12/16/20/24 yanında tasarım özel değerleriyle belge bazlı kullan.
- `GlowCard`, `GlowButton`, `GlowPill`, `GlowMark`, `GlowPageTop`, `GlowSoftNotice` gibi ortak widgetları varyant destekli hale getir.

Risk: Mevcut UI'da bazı Türkçe metinlerde encoding bozukluğu var; UI uygulaması sırasında UTF-8 olarak temizlenmeli.

### 3. Auth ekranları

- `MemberLogin`, `EmployeeLogin`, `GuestLogin` tasarımını Flutter'da tek route mu, ayrı route mu olacağına karar ver.
- Minimum riskli seçenek: mevcut `/login` route'unda rol segmenti kalır; tasarım varyantları aynı ekran içinde gösterilir.
- Register ekranı auth card sistemine bağlanır.

Backend bağımlılığı:

- `/api/auth/login` role istiyor.
- `/api/auth/register` sadece customer registration sağlıyor.
- Personel/admin register backend'de yok.

### 4. Landing / Welcome

- `Landing.tsx` desktop web düzeni Flutter `WelcomePage` içine responsive olarak taşınır.
- Hero, trust strip, hizmet mozaik, quote, CTA, footer bölümleri eklenir.
- Mobile için current welcome sade kalabilir; desktop web'de daha zengin landing önerilir.

Risk: Tasarım gerçek fotoğraf kullanıyor; assetler olmadan hero aynı etkiyi vermez.

### 5. Home

- `Home.tsx` sıralaması korunur:
- PageTop
- home hero
- location row
- popular services
- nearby salon card
- promo notice

Backend:

- Services `/api/catalog/services` ile gelir.
- Salon/lokasyon endpointi yok; bu alan statik veya ileride backend gerektirir.

### 6. Services ve Service Detail

- `Services.tsx` list layout'u korunur.
- Kategoriler backend'de yok; kategori mapping'i service name üzerinden geçici yapılabilir veya tümü gösterilir.
- Service detail için tasarımdaki bottom sheet iki seçeneğe ayrılır:
- Mobile: modal bottom sheet.
- Web/tablet: `/services/:serviceId` detay route.

Backend:

- Options: `/api/catalog/services/{serviceId}/options`
- Packages: `/api/catalog/services/{serviceId}/packages`
- Employees by service: `/api/admin/employees/services/{serviceId}` admin yetkili olabilir; public personel seçimi için backend yetki uyumsuzluğu riski var.

### 7. Appointment Booking

- `Booking.tsx` flow state modeli Flutter'da gerçek state ile kurulmalı:
- serviceId
- optionId
- packageId/customerPackageId
- employeeId
- appointmentDate
- appointmentTime
- guest/customer info

Backend:

- Create appointment `/api/appointments`
- Available slots `/api/appointments/available-slots?serviceId=&date=`

Eksik:

- Booking success screen ayrı widget/dialog yapılmalı.
- İlk müsait zaman toggle algoritması UI'da var, backend'de doğrudan ayrı endpoint yok; available-slots listesinden ilk saat seçilebilir.

### 8. Customer Dashboard

- `Customer.tsx` kartları gerçek veriye bağla:
- upcoming appointments
- past appointments
- customer packages
- package progress
- cancel appointment

Backend:

- Upcoming/past appointments var.
- Customer packages var.
- Cancel endpoint var.

Risk:

- Paket progress için `totalSession` ve `remainingSession` farklı endpointlerden gelebilir.

### 9. Notifications

- `Notifications.tsx` tasarımı mevcut endpointlere bağlanabilir.
- Mark as read için swipe/tap action eklenebilir.

Backend:

- list, unread, mark read endpointleri var.

### 10. Employee Dashboard

- Tasarım repo'da ayrı employee dashboard dosyası yok; prompt tarifinden türetilmeli.
- Mevcut Flutter employee dashboard backend employee schedule endpointine bağlı kalmalı.
- Leave requests için endpoint var ama Flutter servis yüzeyi sınırlı; UI eklenmeden önce servis kapsamı kontrol edilmeli.

### 11. Admin Dashboard

- `Admin.tsx` sidebar ve dashboard panelleri Flutter'a responsive aktarılır.
- Gerçek backend'de bazı metrikler yok; placeholder/statik değerler açıkça ayrılmalı.
- CRUD ekranları küçük adımlarla eklenmeli:
- Services
- Packages
- Employees
- Working hours
- Holidays
- Notifications/reports

Risk:

- Revenue, occupancy, employee performance ve popular services için backend aggregate endpoint yok.

## Eksikler

- Asset bundle tanımı tamamlandı.
- Salon/lokasyon/harita backend sözleşmesi yok.
- Admin rapor/ciro endpointleri yok.
- Separate guest login route yok.
- Separate employee login route yok.
- Waiting list servis/provider bağlantısı hazır; tam UI sonraki ekran uygulama aşamasında yapılmalı.
- Working hours/holidays servis/provider bağlantısı hazır; tam UI sonraki ekran uygulama aşamasında yapılmalı.
- Service category modeli yok.
- Employee image/rating backend alanları yok.

## Önemli Riskler

- `lib/src` altında ikinci/pasif Flutter uygulama hattı bulunuyor. Yanlış import edilirse aktif `lib/core/features` yapısını gölgeleyebilir.
- Tasarım repo prototype kodu statik state ve mock veriler kullanıyor; gerçek API ile aynı davranışı garanti etmiyor.
- `EmployeeController` sınıfında class-level `@PreAuthorize("hasRole('ADMIN')")` var; personel seçimi için `/api/admin/employees/services/{serviceId}` endpointi public booking akışında yetki sorunu çıkarabilir.
- Tasarımdaki görseller Flutter'a taşınmadan görsel kalite hedefi yakalanamaz.
- Backend logout/revoke endpointi yok; güvenli logout yalnızca local token temizleme seviyesinde.
- Tasarım tüm UI metinlerini Türkçe istiyor; mevcut bazı Flutter dosyalarında ASCII/Türkçe ve bozuk encoding karışımı var.

## Doğrulama Planı

- `dart format lib docs`
- `dart analyze lib`
- Flutter web için responsive smoke test
- Android emulator: login, services, booking, notification
- iOS simulator veya macOS yoksa en azından Flutter analyze/build koşulları
- Backend sözleşme için `mvnw test`

## Varsayımlar

- UI implementasyonu yapılırken backend DTO'ları değiştirilmeyecek.
- Tasarım repo mockup dosyaları görsel referans kabul edilecek; Replit API/server/db dosyaları ürün backend'i sayılmayacak.
- Asset lisansları repo içi kullanım için uygun kabul edildi, yayın öncesi ayrıca doğrulanmalı.
