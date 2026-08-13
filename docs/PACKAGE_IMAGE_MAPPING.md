# Paket Görsel Eşlemesi

Paket görselleri artık hizmet görselinden doğrudan miras alınmıyor.
`PackageImageResolver`, önce paket adını, sonra bilinen paket kimliğini, son olarak
hizmet kategorisini değerlendirir.

| Paket | Asset |
|---|---|
| 3 Bölge Lazer | `package-laser-3-region.png` |
| 5 Bölge Lazer | `package-laser-5-region.png` |
| Tüm Vücut Lazer | `package-laser-full-body.png` |
| Hydrafacial | `package-skin-hydrafacial.png` |
| Anti-Aging | `package-skin-anti-aging.png` |
| Medikal/Akne/Leke | `package-skin-medical.png` |

Ad eşleşmesi bilinmeyen paketlerde kategoriye uygun güvenli fallback uygulanır.
Altı ana paket görselinin farklı olduğu testle doğrulanır.
