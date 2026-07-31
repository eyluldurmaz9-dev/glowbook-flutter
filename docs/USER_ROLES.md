# GlowBook User Roles

## Customer

Customer kullanicisi hizmet ve paketleri gorur, randevu olusturur, kendi randevularini ve bildirimlerini takip eder, profilini gunceller ve oturumunu kapatir.

## Employee

Employee kullanicisi yetkili oldugu randevulari, gunluk listeyi, haftalik takvimi, durum guncelleme islemlerini, bildirimlerini ve profilini gorur.

## Admin

Admin kullanicisi web odakli panelden hizmetleri, kategorileri, paketleri, personelleri, calisma saatlerini, izin/tatil gunlerini ve randevu operasyonlarini backend destekledigi olcude yonetir.

## Guest

Guest akisi backend sozlesmesiyle kalici oturum gerektirmeyen kisimlarla sinirlidir. Backend dogrulamasi gerektiren islemler icin login gerekir.

## Yetki Prensibi

Flutter route guard kullanir, ancak yetki guvenligi backend kontrollerine dayanir. Admin veya employee ekranina erismeye calisan yetkisiz kullanici uygun ekrana yonlendirilir ve API 401/403 cevaplari guvenli Turkce hata mesajina cevrilir.
