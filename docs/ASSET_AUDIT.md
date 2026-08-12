# Asset Denetimi

## Onaylı görseller

| Asset | Konu | Kullanım |
|---|---|---|
| `glowbook-hero.jpg` | Aydınlık salon iç mekânı | Hero ve nötr kategori fallback |
| `glowbook-hydrafacial.jpg` | Hydrafacial yüz bakımı | Cilt bakımı hizmet/paketleri |
| `glowbook-lashes.jpg` | Kaş/kirpik portresi | Kaş ve kirpik hizmet/paketleri |
| `glowbook-nails.jpg` | Manikürlü eller | Tırnak/manikür kategorisi |
| `glowbook-portrait-derya.jpg` | Personel/müşteri portresi | Referans portre |
| `glowbook-portrait-elif.jpg` | Personel/müşteri portresi | Referans portre |

Flutter'daki bu altı dosyanın SHA-256 değerleri Visual Asset Manager dosyalarıyla birebir aynıdır.

## Aktif katalog

- Hizmetler: Cilt Bakımı, Lazer Epilasyon, Masaj ve Spa, Kaş ve Kirpik, Bölgesel İncelme.
- Alt hizmetler: 20 adet; tam eşleme `SERVICE_IMAGE_MAPPING.md` içindedir.
- Paketler: 10 adet; her paket servis kategorisinin görselini devralır.
- Personel: GlowBook Admin, Defne Yılmaz, Mina Kaya, Selin Aydın. Referans depoda bu adlara doğrulanmış portre eşlemesi bulunmadığından yanlış portre atanmaz; baş harf avatarı korunur.
- Logo: ayrı raster logo yoktur; referanstaki pembe yuvarlatılmış `Sparkles` marka işareti Flutter `GlowBrand/GlowMark` bileşenleriyle sürdürülür.
- İllüstrasyon: yoktur.
- İkonlar: referansta Lucide; Flutter'da anlam eşdeğeri Material ikonları merkezi bileşenlerde kullanılır.

## Görsel kullanan ekranlar

Ana sayfa, karşılama/landing, hizmet listesi, hizmet detayı, randevu hizmet seçimi, paket listesi, paket detayı, hizmet detayındaki paketler ve admin hizmet önizlemesi denetlendi. Müşteri/çalışan dashboard kartları hizmet fotoğrafı göstermediği için yanlış eşleme yoktur.

## Eksik onaylı kategoriler

Lazer, masaj/spa, bölgesel incelme, pedikür, saç ve makyaj. Bu kategorilerde konu dışı fotoğraf yerine nötr salon fallback kullanılır.
