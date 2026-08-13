import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/features/catalog/catalog_models.dart';
import 'package:glowbook_flutter/features/catalog/service_image_resolver.dart';

void main() {
  test('Mantıksal olarak aynı hizmet adları katalogda tekilleştirilir', () {
    final services = mapCatalogServices([
      {'serviceId': 1, 'serviceName': 'Bölgesel İncelme', 'active': true},
      {'serviceId': 2, 'serviceName': 'bolgesel incelme', 'active': true},
      {'serviceId': 3, 'serviceName': 'Kaş ve Kirpik', 'active': true},
    ]);
    expect(services, hasLength(2));
  });
  test('Service API modeli güvenli UI modeline eşlenir', () {
    final service = CatalogService.fromJson({
      'serviceId': '12',
      'serviceName': ' Hydrafacial ',
      'description': '',
      'serviceImage': 'https://cdn.example.com/unapproved.jpg',
      'active': 'true',
    });

    expect(service.id, 12);
    expect(service.name, 'Hydrafacial');
    expect(service.description, isNull);
    expect(service.image, GlowBookAssets.hydrafacial);
    expect(service.active, isTrue);
  });

  test('Her bilinen servis onaylı ve deterministik bir asset döndürür', () {
    for (final service in ServiceImageResolver.knownServices) {
      final first = ServiceImageResolver.resolve(service);
      final second = ServiceImageResolver.resolve(service);
      expect(first.asset, second.asset, reason: service);
      expect(GlowBookAssets.approved, contains(first.asset), reason: service);
    }
  });

  test('İlgili kategoriler birbirine karıştırılmaz', () {
    expect(
      ServiceImageResolver.imageFor('Cilt Bakımı'),
      GlowBookAssets.hydrafacial,
    );
    expect(
      ServiceImageResolver.imageFor('Kaş Alımı ve Kirpik Lifting'),
      GlowBookAssets.lashes,
    );
    expect(
      ServiceImageResolver.imageFor('Kalıcı Oje ve Manikür'),
      GlowBookAssets.nails,
    );
  });

  test('Onaylı kategorisi olmayan servis nötr salon fallback kullanır', () {
    for (final service in const [
      'Lazer Epilasyon',
      'Masaj ve Spa',
      'Bölgesel İncelme',
      'Pedikür',
      'Saç Kesimi',
      'Makyaj',
    ]) {
      final resolution = ServiceImageResolver.resolve(service);
      expect(resolution.asset, GlowBookAssets.hero, reason: service);
      expect(resolution.neutralFallback, isTrue, reason: service);
    }
  });

  test('Paket API modeli servis görselini merkezi resolverdan alır', () {
    final package = CatalogPackage.fromJson({
      'packageId': 4,
      'serviceId': 2,
      'serviceName': 'Cilt Bakımı',
      'packageName': '6 Seans',
      'packageImage': 'https://cdn.example.com/unapproved.jpg',
      'totalSession': 6,
      'price': 1200.5,
    });

    expect(package.priceText, '1200.5');
    expect(package.totalSession, 6);
    expect(package.image, GlowBookAssets.hydrafacial);
  });
}
