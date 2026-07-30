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
}
