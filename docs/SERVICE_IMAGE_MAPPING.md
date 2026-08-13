# GlowBook Hizmet Görsel Eşlemesi

Kaynak: 13 Ağustos 2026 üretim `GET /api/catalog/services` yanıtı. Çözümleme sırası: kesin `serviceId` → kategori adı → yalnızca bilinmeyen kategoride nötr hero. Backend URL'leri güvenilir içerik kaynağı sayılmaz; uygulama paketindeki doğrulanmış asset kullanılır.

| ID | Aktif hizmet | Önceki görüntü | Yeni asset | Semantik konu | Duplicate? | Gerekçe |
|---:|---|---|---|---|---|---|
| 1 | Cilt Bakımı | Harici cilt URL / hydrafacial | `assets/images/glowbook-hydrafacial.jpg` | Yüz ve cilt bakımı | Hayır | Doğrudan kategori eşleşmesi |
| 2 | Lazer Epilasyon | `glowbook-hero.jpg` genel salon | `assets/images/glowbook-laser.png` | Diode lazer cihazı | Hayır | Spa ile yanlış ortak görsel kaldırıldı |
| 3 | Masaj ve Spa | `glowbook-hero.jpg` genel salon | `assets/images/glowbook-spa.png` | Masaj yatağı, havlu, yağ ve spa taşları | Hayır | Lazerden ayrılmış gerçek spa konusu |
| 4 | Kaş ve Kirpik | Harici URL / lashes | `assets/images/glowbook-lashes.jpg` | Kaş-kirpik/göz çevresi | ID 7 ile bilinçli aynı kategori | Aynı hizmet kategorisinin yinelenen DB kaydı |
| 5 | Bölgesel İncelme | `glowbook-hero.jpg` genel salon | `assets/images/glowbook-body-treatment.png` | Vücut şekillendirme cihazı | ID 8 ile bilinçli aynı kategori | Aynı hizmet kategorisinin yinelenen DB kaydı |
| 6 | Tırnak | Boş | `assets/images/glowbook-nails.jpg` | Tırnak/manikür/pedikür | Hayır | Boş görsel düzeltildi |
| 7 | Kaş ve Kirpik | Harici URL / lashes | `assets/images/glowbook-lashes.jpg` | Kaş-kirpik/göz çevresi | ID 4 ile bilinçli aynı kategori | Üretimdeki yinelenen kategori |
| 8 | Bölgesel İncelme | Harici URL / genel fallback | `assets/images/glowbook-body-treatment.png` | Vücut şekillendirme cihazı | ID 5 ile bilinçli aynı kategori | Üretimdeki yinelenen kategori |

## Kategori fallbackleri

| Kategori | Asset |
|---|---|
| Lazer | `glowbook-laser.png` |
| Spa/masaj | `glowbook-spa.png` |
| Cilt/Hydrafacial | `glowbook-hydrafacial.jpg` |
| Tırnak/manikür/pedikür | `glowbook-nails.jpg` |
| Saç/kuaför | `glowbook-hair.png` |
| Kaş/kirpik | `glowbook-lashes.jpg` |
| Bölgesel/vücut bakımı | `glowbook-body-treatment.png` |
| Makyaj | `glowbook-makeup.png` |

Logo ve platform ikonu hiçbir hizmet eşlemesinde bulunmaz.