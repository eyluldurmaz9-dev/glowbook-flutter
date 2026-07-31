# GlowBook Project Overview

GlowBook; musterilerin hizmet ve paket kesfedebildigi, randevu olusturabildigi, personelin takvimini yonetebildigi ve admin kullanicilarin katalog ile operasyonlari web uzerinden takip edebildigi bir randevu yonetim sistemidir.

## Repository Ayrimi

- `glowbook-flutter`: Android, iOS ve Flutter Web istemcisi.
- `glowbook-backend`: Spring Boot REST API ve is kurallari.
- `glowbook-visualAssentManager-ui`: yalnizca UI/UX tasarim referansi.

Tasarim deposu uygulama kodu kaynagi degildir. Flutter arayuzu, tasarim dilini mevcut Flutter mimarisi icinde yeniden olusturur.

## Teslim Kapsami

- Authentication ve rol bazli yonlendirme.
- Musteri katalog, randevu, bildirim, paket ve profil ekranlari.
- Personel takvim ve randevu ekranlari.
- Admin web yonetim paneli.
- Ortak GlowBook design system ve responsive widget altyapisi.
- Deployment, build, test ve release dokumantasyonu.

## Sinirlar

- Backend tarafindan desteklenmeyen alanlar UI'da tamamlanmis gibi gosterilmez.
- SMS, production database ve iOS signing gibi dis sistemler manuel dogrulama ister.
- iOS build Windows ortaminda gercek olarak calistirilamamistir.
