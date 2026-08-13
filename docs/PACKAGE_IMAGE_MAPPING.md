# GlowBook Paket Görsel Eşlemesi

Kaynak: 13 Ağustos 2026 üretim servislerinin paket endpointleri. Çözümleme sırası kesin `packageId` → kesin paket adı → hizmet kategorisi fallbackidir. Paket detay hero'su doğrudan seçili `CatalogPackage.image` değerini kullanır.

| ID | Paket | Kategori | Önceki görüntü | Yeni asset | Duplicate? | Semantik doğruluk / gerekçe |
|---:|---|---|---|---|---|---|
| 1 | Glow Cilt Paketi | Cilt | Harici cilt URL | `package-skin-anti-aging.png` | Hayır | Yenileyici cilt paketi için ayrı cilt varyantı |
| 2 | Lazer Devam Paketi | Lazer | Genel/boş | `package-laser-3-region.png` | Yüz Bölgesi ile tema ortak | Genel lazer seansı, lazer konusu doğru |
| 3 | Spa Yenilenme Paketi | Spa | Harici spa URL / önce hero fallback | `glowbook-spa.png` | Hayır | Paket detayında gerçek spa görseli zorunluluğu sağlandı |
| 4 | İncelme Programı | Bölgesel | Boş | `glowbook-body-treatment.png` | Aynı kategori | Vücut bakım cihazı |
| 5 | Hydrafacial Bakım Paketi | Cilt | Boş | `package-skin-hydrafacial.png` | Hayır | Hydrafacial'a özel |
| 6 | 5 Bölge Lazer Paketi | Lazer | Boş | `package-laser-5-region.png` | Hayır | 5 bölgeye özel lazer varyantı |
| 7 | Tüm Vücut Lazer Paketi | Lazer | Boş | `package-laser-full-body.png` | Hayır | Full-body lazer varyantı |
| 8 | Yüz Bölgesi Lazer Paketi | Lazer | Harici URL | `package-laser-3-region.png` | ID 2 ile tema ortak | Lazer konusu doğru; ilgisiz varyant kullanılmadı |
| 9 | Kaş Kirpik Bakım Paketi | Kaş/Kirpik | Harici URL | `glowbook-lashes.jpg` | ID 13 ile bilinçli aynı | Yinelenen hizmet kategorisi |
| 10 | Sıkılaşma Paketi | Bölgesel | Boş | `glowbook-body-treatment.png` | Aynı kategori | Vücut/sıkılaşma konusu doğru |
| 11 | Kalıcı Oje | Tırnak | Boş | `glowbook-nails.jpg` | ID 12 ile kategori ortak | Tırnak konusu doğru |
| 12 | Protez Tırnak + nail art | Tırnak | Boş | `glowbook-nails.jpg` | ID 11 ile kategori ortak | Tırnak konusu doğru |
| 13 | Kaş Kirpik Bakım Paketi | Kaş/Kirpik | Boş | `glowbook-lashes.jpg` | ID 9 ile bilinçli aynı | Yinelenen hizmet kategorisi |
| 14 | İncelme Programı | Bölgesel | Boş | `glowbook-body-treatment.png` | ID 4 ile bilinçli aynı | Yinelenen hizmet kategorisi |
| 15 | Sıkılaşma Paketi | Bölgesel | Boş | `glowbook-body-treatment.png` | ID 10 ile bilinçli aynı | Yinelenen hizmet kategorisi |

Ayrı ve semantik açıdan doğru onaylı alternatifler bulunan 5 Bölge, Tüm Vücut, Hydrafacial ve Glow/Anti-aging paketleri farklı görseller kullanır. Aynı üretim kategorisinin yinelenen kayıtlarında sırf farklı görünmek için ilgisiz fotoğraf atanmaz.