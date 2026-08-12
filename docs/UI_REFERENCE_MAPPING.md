# UI Referans Eşlemesi

Onaylı kaynak: Visual Asset Manager ZIP içindeki GlowBook mockup'ları.

| Referans ilkesi | Flutter karşılığı |
|---|---|
| Beyaz zemin | `AppColors.background` |
| Dusty/baby pink | `blush`, `action`, `petal`, `roseTint` |
| Premium tipografi | DM Sans + Playfair Display |
| 22–28 px yuvarlak kartlar | `GlowCard`, auth/dialog radius değerleri |
| İnce pembe sınır ve yumuşak gölge | `AppColors.border`, `softShadow` |
| 430 px mobil içerik yaklaşımı | `GlowResponsivePage` ve mobil alt navigasyon |
| Pembe seçim/step durumu | Randevu seçim kartları ve adım göstergesi |
| Türkçe metin ve mevcut navigasyon | Flutter rotaları ve ekran metinleri korunur |

Merkezi `ServiceImageResolver`, tüm görünür katalog ekranlarının onaylı asset kararını tek noktadan verir. API görsel URL'si yönetim verisi olarak kalabilir ancak görünür katalogda onaylı tasarım kaynağının önüne geçmez.
