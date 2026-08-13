import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/features/catalog/service_image_resolver.dart';
import 'package:glowbook_flutter/features/catalog/package_image_resolver.dart';

void main() {
  test('Merkezi resolverdaki her onaylı asset diskte bulunur', () {
    for (final asset in GlowBookAssets.approved) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test('Her paket görseli diskte bulunur ve dosyalar birbirinden farklıdır',
      () {
    final sizes = <int>{};
    for (final asset in PackageImageResolver.approved) {
      final file = File(asset);
      expect(file.existsSync(), isTrue, reason: asset);
      sizes.add(file.lengthSync());
    }
    expect(sizes, hasLength(PackageImageResolver.approved.length));
  });

  test('Resmî logo ve web ikonları üretilmiştir', () {
    for (final path in const [
      'assets/images/branding/glowbook-official-logo.png',
      'web/favicon.png',
      'web/icons/Icon-192.png',
      'web/icons/Icon-512.png',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('Pubspec onaylı görsel klasörünü bildirir', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/images/'));
  });
}
