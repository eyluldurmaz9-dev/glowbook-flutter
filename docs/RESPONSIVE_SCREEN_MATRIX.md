# Responsive Ekran Matrisi

| Hedef | Kontrol | Beklenen davranış |
|---|---|---|
| Küçük Android (320×568) | Liste, form, randevu adımları | Dikey kaydırma; kart içeriği kırpılmaz |
| Standart Android (360×800) | Tüm müşteri akışı | Alt navigasyon ve sabit aksiyon güvenli alanı korur |
| Büyük Android (412×915) | Görsel kartlar | `BoxFit.cover`; oran bozulmaz |
| iPhone (390×844) | Form/klavye | Scroll görünümü klavye taşmasını önler |
| Büyük iPhone (430×932) | Referans mobil genişliği | Referansın 430 px hiyerarşisi korunur |
| Tablet portre (768×1024) | Kart ve dashboard | Responsive içerik genişliği; gereksiz esneme yok |
| Tablet yatay (1024×768) | Admin/dashboard | Çok kolonlu düzen, kaydırılabilir tablolar |
| Desktop 1366 | Landing/admin | Merkezi maksimum genişlik, uygun yan boşluk |
| Geniş desktop (1920) | Landing/admin | İçerik sınırlanır; görseller gerilmez |

Ortak görsel bileşeni sabit kutu ölçüsü, `BoxFit.cover`, yuvarlatılmış kırpma, yükleme durumu ve hata placeholder'ı sağlar. Paket ve admin önizlemeleri aynı davranışı kullanır.
