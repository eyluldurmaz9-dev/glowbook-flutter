# Rol Bazlı Çıkış Akışı

Müşteri, personel ve admin çıkışları ortak `AuthController.logout()` akışını
kullanır. Bu akış backend servisindeki logout işlemini çağırır, güvenli depolamayı
temizler, oturum state'ini `null` yapar ve karşılama rotasına döner.

Admin masaüstünde sidebar çıkışı, mobilde ise üst çubuktaki
`admin_mobile_logout` düğmesi kullanılır. Mobil düğmenin görünürlüğü widget testiyle;
oturum temizleme davranışı `auth_controller_test.dart` ile doğrulanır.
