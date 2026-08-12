import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/features/catalog/service_image_resolver.dart';

void main() {
  test('Merkezi resolverdaki her onaylı asset diskte bulunur', () {
    for (final asset in GlowBookAssets.approved) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test('Pubspec onaylı görsel klasörünü bildirir', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/images/'));
  });
}
