import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/features/catalog/catalog_models.dart';

void main() {
  test('Service API modeli güvenli UI modeline eşlenir', () {
    final services = mapCatalogServices([
      {
        'serviceId': '12',
        'serviceName': ' Hydrafacial ',
        'description': '',
        'serviceImage': 'https://cdn.example.com/service.jpg',
        'active': 'true',
      },
    ]);

    expect(services.single.id, 12);
    expect(services.single.name, 'Hydrafacial');
    expect(services.single.description, isNull);
    expect(services.single.image, 'https://cdn.example.com/service.jpg');
    expect(services.single.active, isTrue);
  });

  test('Legacy servis görselleri doğru yerel kategori görseline eşlenir', () {
    final services = mapCatalogServices([
      {
        'serviceId': 2,
        'serviceName': 'Lazer Epilasyon',
        'serviceImage': 'https://images.unsplash.com/photo-legacy',
      },
      {'serviceId': 3, 'serviceName': 'Masaj ve Spa'},
      {'serviceId': 5, 'serviceName': 'Bölgesel İncelme'},
    ]);

    expect(services[0].image, 'assets/images/glowbook-laser.jpg');
    expect(services[1].image, 'assets/images/glowbook-spa.jpg');
    expect(
      services[2].image,
      'assets/images/glowbook-body-contouring.jpg',
    );
  });

  test('Özel servis görseli kategori varsayılanından önce gelir', () {
    final service = CatalogService.fromJson({
      'serviceName': 'Masaj ve Spa',
      'serviceImage': 'https://cdn.example.com/custom-spa.jpg',
    });

    expect(service.image, 'https://cdn.example.com/custom-spa.jpg');
  });

  test('Package API modeli fiyatı değiştirmeden gösterir', () {
    final packages = mapCatalogPackages([
      {
        'packageId': 4,
        'serviceId': 2,
        'serviceName': 'Cilt Bakımı',
        'packageName': '6 Seans',
        'totalSession': 6,
        'price': 1200.5,
      },
    ]);

    expect(packages.single.priceText, '1200.5');
    expect(packages.single.totalSession, 6);
  });

  test('Görselsiz paket servis kategorisinin görselini devralır', () {
    final package = CatalogPackage.fromJson({
      'packageId': 4,
      'serviceId': 3,
      'serviceName': 'Masaj ve Spa',
      'packageName': 'Spa Paketi',
      'packageImage': ' ',
    });

    expect(package.image, 'assets/images/glowbook-spa.jpg');
  });

  test('Legacy paket görseli servis kategorisiyle düzeltilir', () {
    final package = CatalogPackage.fromJson({
      'serviceName': 'Kaş ve Kirpik',
      'packageName': 'Kirpik Paketi',
      'packageImage': 'https://images.unsplash.com/photo-legacy-package',
    });

    expect(package.image, 'assets/images/glowbook-lashes.jpg');
  });
}
