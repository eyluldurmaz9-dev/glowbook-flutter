# GlowBook Hizmet Görsel Eşlemesi

Kaynak: `Visual-Asset-Manager/artifacts/mockup-sandbox/public/images`. Yalnızca bu depoda onaylanmış görseller kullanılır. Onaylı kategori görseli olmayan hizmetlerde ilgisiz uygulama fotoğrafı yerine nötr GlowBook salon görseli gösterilir.

| Hizmet | Alt hizmet / paket | Eski görsel | Yeni görsel | Görsel konusu | Gerekçe |
|---|---|---|---|---|---|
| Cilt Bakımı | Klasik Cilt Bakımı | Unsplash URL | `assets/images/glowbook-hydrafacial.jpg` | Yüz cilt bakımı | Doğrudan kategori eşleşmesi |
| Cilt Bakımı | Hydrafacial Bakım | Unsplash URL | `assets/images/glowbook-hydrafacial.jpg` | Hydrafacial uygulaması | Referansta onaylı |
| Cilt Bakımı | Anti Aging Bakım | Unsplash URL | `assets/images/glowbook-hydrafacial.jpg` | Yüz cilt bakımı | Aynı cilt bakımı kategorisi |
| Cilt Bakımı | Leke Bakımı | Unsplash URL | `assets/images/glowbook-hydrafacial.jpg` | Yüz cilt bakımı | Aynı cilt bakımı kategorisi |
| Cilt Bakımı | Akne Bakımı | Unsplash URL | `assets/images/glowbook-hydrafacial.jpg` | Yüz cilt bakımı | Aynı cilt bakımı kategorisi |
| Cilt Bakımı | Glow Cilt Paketi | Boş/servis URL'si | `assets/images/glowbook-hydrafacial.jpg` | Yüz cilt bakımı | Paket servis kategorisini devralır |
| Cilt Bakımı | Hydrafacial Bakım Paketi | Boş/servis URL'si | `assets/images/glowbook-hydrafacial.jpg` | Hydrafacial | Paket servis kategorisini devralır |
| Lazer Epilasyon | Tek Bölge, 3 Bölge, 5 Bölge, Yüz Bölgesi, Tüm Vücut | Unsplash/üretilmiş cihaz görseli | `assets/images/glowbook-hero.jpg` | Salon iç mekânı | Referansta kategori görseli yok; nötr fallback |
| Lazer Epilasyon | 5 Bölge, Tüm Vücut, Yüz Bölgesi paketleri | Boş/servis URL'si | `assets/images/glowbook-hero.jpg` | Salon iç mekânı | İlgisiz görsel kullanmayan nötr fallback |
| Masaj ve Spa | Aromaterapi Masajı, Medikal Masaj | Unsplash/üretilmiş spa görseli | `assets/images/glowbook-hero.jpg` | Salon iç mekânı | Referansta masaj görseli yok; nötr fallback |
| Masaj ve Spa | Spa Yenilenme Paketi | Boş/servis URL'si | `assets/images/glowbook-hero.jpg` | Salon iç mekânı | Nötr fallback |
| Kaş ve Kirpik | Kaş Alımı, Kaş Tasarımı, Kaş Laminasyonu, Kirpik Lifting | Unsplash URL | `assets/images/glowbook-lashes.jpg` | Kaş/kirpik ve göz çevresi | Doğrudan kategori eşleşmesi |
| Kaş ve Kirpik | Kaş Kirpik Bakım Paketi | Boş/servis URL'si | `assets/images/glowbook-lashes.jpg` | Kaş/kirpik | Paket servis kategorisini devralır |
| Bölgesel İncelme | Karın, Bacak, Kol, Selülit Bakımı | Unsplash/üretilmiş cihaz görseli | `assets/images/glowbook-hero.jpg` | Salon iç mekânı | Referansta kategori görseli yok; nötr fallback |
| Bölgesel İncelme | İncelme Programı, Sıkılaşma Paketi | Boş/servis URL'si | `assets/images/glowbook-hero.jpg` | Salon iç mekânı | Nötr fallback |

Gelecekte katalogda tırnak/manikür hizmeti açılırsa `glowbook-nails.jpg`; saç, pedikür ve makyaj için onaylı özel asset eklenene kadar `glowbook-hero.jpg` kullanılır.
