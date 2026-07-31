# GlowBook Flutter Architecture

## Genel Yapi

Flutter uygulamasi mevcut klasor mimarisi korunarak gelistirilmistir. Uygulama katmanlari ekranlar, ortak UI widget'lari, state/controller yapilari, modeller ve API servisleri olarak ayrilir.

## Istemci Katmanlari

- UI: Material Design 3 tabanli responsive Flutter widget'lari.
- State management: Mevcut Riverpod/provider yapisi.
- API client: Dio uzerinden backend REST endpointleri.
- Storage: JWT ve refresh token icin secure storage.
- Routing: Mevcut route yapisi ve rol guard mekanizmalari.

## Backend Baglantisi

Flutter, uygunluk ve randevu is kurallarini kendisi tahmin etmez. Appointment availability, conflict, waiting list, status ve rol yetkileri backend sozlesmesi uzerinden dogrulanir.

## Responsive Davranis

- Mobil: bottom navigation, kaydirilabilir formlar ve safe area uyumu.
- Tablet: daha genis grid/list duzenleri.
- Web: admin ve personel panellerinde sidebar/icerik alani odakli layout.

## Guvenlik

- Token ve kisisel veriler loglanmaz.
- Role guard UI tarafinda kullanilir; asil yetki dogrulamasi backend tarafindan yapilir.
- Production API URL degeri repository yerine runtime config olarak verilir.
