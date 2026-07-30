# GlowBook Design Mapping

## Kaynaklar

- Flutter uygulaması: `flutter_app` (`glowbook-flutter` remote'u: `https://github.com/eyluldurmaz9-dev/glowbook-flutter.git`)
- Tasarım referansı: `.design-reference/glowbook-visualAssentManager-ui`
- Backend sözleşmesi: `glowbook` klasörü. Kullanıcı bunu `glowbook-backend` olarak adlandırdı; çalışma alanındaki gerçek klasör adı `glowbook`.

## Tasarım Deposunun UI Dosyaları

Gerçek UI referansı şu klasördedir:

- `artifacts/mockup-sandbox/src/components/mockups/glowbook/Landing.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/Home.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/Services.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/Booking.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/Customer.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/Notifications.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/MemberLogin.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/EmployeeLogin.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/GuestLogin.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/Admin.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/_shared/GlowBookShell.tsx`
- `artifacts/mockup-sandbox/src/components/mockups/glowbook/_shared/glowbook.css`

## Flutter Giriş Noktası ve Aktif Route Yapısı

Aktif uygulama hattı:

- `lib/main.dart`
- `lib/app.dart`
- `lib/core/routes/app_router.dart`
- `lib/core/routes/app_routes.dart`

Aktif route'lar:

| Route | Flutter ekranı |
|---|---|
| `/splash` | `features/auth/splash_page.dart` |
| `/welcome` | `features/auth/welcome_page.dart` |
| `/login` | `features/auth/login_page.dart` |
| `/register` | `features/auth/register_page.dart` |
| `/forgot-password` | `features/auth/forgot_password_page.dart` |
| `/home` | `features/home/home_page.dart` |
| `/services` | `features/service/services_page.dart` |
| `/services/:serviceId` | `features/service/service_detail_page.dart` |
| `/packages` | `features/package/packages_page.dart` |
| `/packages/:serviceId/:packageId` | `features/package/package_detail_page.dart` |
| `/appointment` | `features/appointment/appointment_page.dart` |
| `/calendar` | `features/appointment/calendar_page.dart` |
| `/employees/select` | `features/employee/employee_selection_page.dart` |
| `/notification` | `features/notification/notification_page.dart` |
| `/profile` | `features/profile/profile_page.dart` |
| `/customer/dashboard` | `features/dashboard/customer_dashboard_page.dart` |
| `/employee/dashboard` | `features/dashboard/employee_dashboard_page.dart` |
| `/admin` | `features/dashboard/admin_dashboard_page.dart` |
| `/employee` | `features/employee/employee_page.dart` |
| `/admin/legacy` | `features/admin/admin_page.dart` |

## Catalog Implementation Notes

- Customer home uses real `/api/catalog/services` data for featured services.
- Services search is local over the current API response; backend category filtering is not implemented because `ServiceResponse` has no category field.
- Package list aggregates real `/api/catalog/services/{serviceId}/packages` responses for active services; backend pagination is not available and was not simulated.
- Package detail uses `/packages/:serviceId/:packageId` and selects the package from the service package list because there is no package-by-id catalog endpoint.
- Campaigns, favorites, service rating, location, duration and main-service price are not rendered from fixed UI data because the current backend contract does not expose those fields.

## Ekran Eşleştirmesi

| Tasarım ekranı | Tasarım dosyası | Flutter karşılığı | Route | Durum |
|---|---|---|---|---|
| Landing Page | `Landing.tsx` | `WelcomePage` | `/welcome` | Kısmi. Web landing bölümleri tam ayrı sayfa değil. |
| Splash | Tasarımda ayrı dosya yok; marka giriş hissi auth/landing içinde | `SplashPage` | `/splash` | Flutter işlevsel ekranı var. |
| Member Login | `MemberLogin.tsx` | `LoginPage` | `/login` | Eşleşiyor. Flutter tek formda rol seçimi kullanıyor. |
| Employee Login | `EmployeeLogin.tsx` | `LoginPage` | `/login` | Kısmi. Tasarımda ayrı personel login, Flutter'da rol segmenti. |
| Guest Login | `GuestLogin.tsx` | `LoginPage` içindeki misafir geçişi / `ServicesPage` | `/login`, `/services` | Kısmi. Backend misafir auth gerektirmez, ayrı route yok. |
| Register / Üye Ol | Prompt ve auth kart pattern'i | `RegisterPage` | `/register` | Eşleşiyor. |
| Forgot Password | Tasarım auth pattern'i | `ForgotPasswordPage` | `/forgot-password` | Backend endpoint yok; sahte başarı yerine bilgilendirme ekranı var. |
| Customer Home | `Home.tsx` | `HomePage` | `/home` | Eşleşiyor. |
| Services | `Services.tsx` | `ServicesPage` | `/services` | Eşleşiyor. |
| Service Detail bottom sheet | `Services.tsx` seçili hizmet modalı | `ServiceDetailPage` | `/services/:serviceId` | Flutter ayrı route kullanıyor. |
| Booking / Appointment | `Booking.tsx` | `AppointmentPage` | `/appointment` | Kısmi. Tasarım statik flow, Flutter backend listesiyle birlikte. |
| Available Time Slots | `Booking.tsx` time grid | `CalendarPage`, `AppointmentPage` | `/calendar`, `/appointment` | Kısmi. Backend available-slots var; UI tam seçim state'i gerektiriyor. |
| Customer Dashboard | `Customer.tsx` | `CustomerDashboardPage`, ayrıca `ProfilePage` | `/customer/dashboard`, `/profile` | Kısmi. Paket progress ve randevu kartı var; geçmiş randevu/cancel tam değil. |
| Notifications | `Notifications.tsx` | `NotificationPage` | `/notification` | Eşleşiyor. |
| Admin Dashboard | `Admin.tsx` | `AdminDashboardPage` | `/admin` | Eşleşiyor, bazı metrikler backend'den değil mock/statik. |
| Employee Dashboard | Prompt içinde var, ayrı tasarım dosyası yok; `EmployeeLogin.tsx` sadece login | `EmployeeDashboardPage` | `/employee/dashboard` | Flutter işlevsel ekranı var, tasarım referansı eksik. |

## Tasarımda Olup Flutter'da Eksik veya Kısmi Olan Ekranlar

- Ayrı `GuestLogin` route'u yok. Flutter'da `/login?mode=guest` ile misafir devam ekranı ve hizmetlere geçiş var.
- Ayrı `EmployeeLogin` route'u yok. Flutter'da `/login?role=EMPLOYEE` ve rol segmentiyle çözüyor.
- Landing Page'in tam web bölümleri eksik: desktop nav, trust strip, service mosaic, quote, CTA, footer.
- Laser Hair Removal popup detayları eksik: `2 Bölge`, `3 Bölge`, `5 Bölge`, `Tüm Vücut`, `6/8/10/12 Seans`.
- Skin Care, Nail Services, Eyebrows & Eyelashes kategori detay ekranları ayrı route olarak yok; mevcut `/services` kategori chip seviyesinde.
- Booking success screen ayrı route/dialog olarak yok; SnackBar ile kısmi başarı bildirimi var.
- Customer dashboard geçmiş randevu ve iptal aksiyonu tam bağlanmamış.
- Admin alt modülleri için ayrı ekranlar yok: çalışma saatleri, tatiller, raporlar, ayarlar, servis/paket yönetim formları.

## Flutter'da Olup Tasarım Referansında Eksik veya Ayrı Dosya Olmayan İşlevler

- `/calendar`: backend available-slots entegrasyonuna bağlı takvim ekranı.
- `/employees/select`: personel seçimi.
- `/employee`: personel listeleme.
- `/profile`: müşteri profil detay ekranı.
- `/admin/legacy`: eski admin sayfası.
- `lib/src/...`: eski/pasif görünümlü ikinci Flutter mimari hattı. Aktif giriş tarafından kullanılmıyor.

## Tasarım ile Backend İşlevleri Arasındaki Uyumsuzluklar

- Tasarım fiyat, ciro, performans, doluluk, puan ve bazı salon bilgilerini mock data ile gösteriyor; backend'de bu rapor/metrik endpointleri yok.
- Tasarım “salonlar/konum/harita” gösteriyor; backend sözleşmesinde salon veya lokasyon endpointi yok.
- Tasarım hizmet fotoğrafları kullanıyor; backend `serviceImage` ve `packageImage` alanlarını döndürebiliyor ancak Flutter asset bundle henüz bu görselleri tanımlamıyor.
- Tasarım personel puanı ve profil fotoğrafı gösteriyor; backend `EmployeeResponse` içinde rating veya image alanı yok.
- Tasarım customer package progress için kullanılan seans sayısını gösteriyor; backend `CustomerPackageResponse` sadece `remainingSession`, `totalSession` ise package endpointinden ayrı geliyor. Kullanılan seans hesaplanabilir ama doğrudan dönmüyor.
- Tasarım booking flow'da tüm seçimleri tek ekranda tutuyor; backend randevu oluşturmak için `employeeId`, `serviceId`, `optionId`, tarih, saat ve müşteri bilgilerini zorunlu kılıyor. UI state'i bu alanları eksiksiz toplamalı.
- Backend'de refresh endpoint var ancak logout/revoke endpoint yok; Flutter logout yerel token temizliği olarak çalışıyor.
- Backend'de waiting-list, working-hours, holidays endpointleri var; mevcut Flutter servis katmanında waiting-list/schedule tam kapsanmıyor.

## Varsayımlar

- `flutter_app` mevcut Flutter repo olarak kabul edildi.
- `glowbook` backend repo olarak kabul edildi.
- Tasarım repo'daki `artifacts/mockup-sandbox` dosyaları UI/UX referansı; `lib/api-*`, `lib/db`, `artifacts/api-server` dosyaları tasarım referansı değil, Replit workspace şablonu ve yardımcı API/demo yapısıdır.
- Tasarım repo'daki React kodları uygulama mantığı değil, prototip/mockup kodudur.

## İncelenemeyen veya Erişilemeyenler

- Dosya içerikleri okunabildi. `git rev-parse` tasarım repo için Windows kullanıcı sahipliği nedeniyle `dubious ownership` uyarısı verdi; commit hash `.git/refs/heads/main` dosyasından okunabildi.
