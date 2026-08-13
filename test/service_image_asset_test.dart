import 'dart:convert';
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

  test('İçerik resolverları logo veya platform ikonunu döndürmez', () {
    const brandingFragments = <String>[
      '/branding/',
      'glowbook-official-logo',
      'glowbook-platform-icon',
    ];
    final contentAssets = <String>{
      ...GlowBookAssets.approved,
      ...PackageImageResolver.approved,
    };
    for (final asset in contentAssets) {
      for (final fragment in brandingFragments) {
        expect(asset, isNot(contains(fragment)), reason: asset);
      }
    }
  });

  test('Lazer, spa ve vücut görselleri farklı dosya içeriğine sahiptir', () {
    final hashes = <String>{};
    for (final asset in const [
      GlowBookAssets.laser,
      GlowBookAssets.spa,
      GlowBookAssets.bodyTreatment,
    ]) {
      hashes.add(base64Encode(File(asset).readAsBytesSync()));
    }
    expect(hashes, hasLength(3));
  });

  test('Web hero görseli aynı ekranda büyük içerik olarak tekrarlanmaz', () {
    final source =
        File('lib/features/web/web_landing_page.dart').readAsStringSync();
    expect(
        RegExp("Image\\.asset\\('assets/images/glowbook-hero.jpg'")
            .allMatches(source),
        hasLength(1));
  });
}
