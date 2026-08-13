# Public Web Landing

GlowBook web ziyaretçileri oturum açmadan Ana Sayfa, Hakkımızda, Hizmetler,
Paketler, Randevu Al ve İletişim bölümlerini görebilir.

## Veri kaynağı

Hizmetler `servicesProvider`, paketler `allServicePackagesProvider` üzerinden
üretim backend'inin public katalog uçlarından yüklenir. Yalnızca aktif kayıtlar
gösterilir. Hizmet görselleri `ServiceImageResolver`, paket görselleri
`PackageImageResolver` tarafından belirlenir; web için ayrı sabit katalog yoktur.

## Kimlik doğrulama sınırı

Katalog görüntülemek için giriş gerekmez. “Randevu Al” mevcut misafir giriş
akışını açar. Paket ayrıntıları public görüntülenebilir; satın alma sırasında
mevcut iş kuralı gerekiyorsa giriş sayfasına yönlendirir.

## İletişim yapılandırması

Depoda doğrulanmış üretim telefonu, e-postası veya adresi bulunmadığı için sahte
bilgi gösterilmez. Bu alanlar işletmenin onayladığı değerler sağlandığında merkezi
bir yapılandırmadan doldurulmalıdır.

## Platform sınırı

Landing yalnızca Flutter web'de karşılama ekranının yerine kullanılır. Android ve
iOS uygulama navigasyonu uygulama tarzında kalır.
