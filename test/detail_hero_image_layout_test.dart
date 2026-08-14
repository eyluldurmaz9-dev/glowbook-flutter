import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/widgets/glow_widgets.dart';
import 'package:glowbook_flutter/features/package/package_detail_page.dart';
import 'package:glowbook_flutter/features/service/service_detail_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Regression coverage for the half-cropped hero image defect. A fixed
/// `height: 220` on a `width: double.infinity` container forced BoxFit.cover
/// into an extreme panoramic crop on wide viewports (desktop web content is
/// up to 1100px, giving a ~5:1 aspect ratio for what are square or mildly
/// landscape source photos) — showing only a narrow strip of the subject.
void main() {
  group('GlowDetailHeroImage boyutlandırması', () {
    testWidgets('mobilde ekran genişliğini panoramik bir bant yapmadan doldurur',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ListView(
              children: [
                GlowDetailHeroImage(
                  key: key,
                  semanticLabel: 'test',
                  image: null,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = _visibleImageSize(tester, find.byKey(key));
      final ratio = size.width / size.height;

      // A short, wide band (the old bug) reads as ratio >> 2. The fixed hero
      // must stay close to a square, whatever the exact source crop is.
      expect(ratio, closeTo(1, 0.05));
      expect(size.height, greaterThan(200));
    });

    testWidgets(
        'geniş masaüstü görünümünde tüm içerik genişliğine yayılmaz (sınırlı genişlik)',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: GlowResponsivePage(
              child: ListView(
                children: [
                  GlowDetailHeroImage(
                    key: key,
                    semanticLabel: 'test',
                    image: null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = _visibleImageSize(tester, find.byKey(key));
      final pageWidth = tester.getSize(find.byType(GlowResponsivePage)).width;

      // The old bug stretched the image across the entire (up to 1100px)
      // content column. The hero must stay well short of that, and square.
      expect(size.width, lessThan(pageWidth * 0.6));
      expect(size.width / size.height, closeTo(1, 0.05));
    });

    testWidgets('paket detayı gerçek sayfada kare hero kullanır', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => _SignedOutController(),
            ),
            servicePackagesProvider.overrideWith(
              (ref, serviceId) async => const [
                {
                  'packageId': 9,
                  'serviceId': 4,
                  'serviceName': 'Kaş ve Kirpik',
                  'packageName': 'Kaş Kirpik Bakım Paketi',
                  'totalSession': 4,
                  'active': true,
                },
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PackageDetailPage(serviceId: 4, packageId: 9),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final heroFinder = find.byKey(const Key('package_detail_hero_9'));
      expect(heroFinder, findsOneWidget);
      expect(tester.widget(heroFinder), isA<GlowDetailHeroImage>());

      final size = _visibleImageSize(tester, heroFinder);
      expect(size.width / size.height, closeTo(1, 0.05));
    });

    testWidgets('hizmet detayı gerçek sayfada kare hero kullanır', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            servicesProvider.overrideWith(
              (ref) async => const [
                {
                  'serviceId': 3,
                  'serviceName': 'Masaj ve Spa',
                  'description': 'Bakım',
                },
              ],
            ),
            serviceOptionsProvider.overrideWith((ref, id) async => const []),
            servicePackagesProvider.overrideWith((ref, id) async => const []),
            employeesByServiceProvider.overrideWith((ref, id) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ServiceDetailPage(serviceId: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final heroFinder = find.byKey(const Key('service_detail_hero_3'));
      expect(heroFinder, findsOneWidget);
      expect(tester.widget(heroFinder), isA<GlowDetailHeroImage>());

      final size = _visibleImageSize(tester, heroFinder);
      expect(size.width / size.height, closeTo(1, 0.05));
    });
  });

  group('Kaynak paket/hizmet görselleri (dosya)', () {
    // Confirms the crop was purely a layout bug, not a mismatched/odd source
    // asset: every image the resolvers can hand a detail hero is close
    // enough to square/landscape that a 1:1 hero frame is a sensible,
    // intentional-looking crop rather than an arbitrary one.
    test('paket/hizmet görsel varlıkları aşırı panoramik değildir', () {
      const assets = [
        'assets/images/glowbook-lashes.jpg',
        'assets/images/glowbook-spa.png',
        'assets/images/glowbook-hero.jpg',
        'assets/images/packages/package-laser-3-region.png',
        'assets/images/packages/package-laser-5-region.png',
        'assets/images/packages/package-laser-full-body.png',
        'assets/images/packages/package-skin-anti-aging.png',
        'assets/images/packages/package-skin-hydrafacial.png',
        'assets/images/packages/package-skin-medical.png',
      ];

      for (final path in assets) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path bulunamadı');
        final bytes = file.readAsBytesSync();
        final size = _decodePngOrJpegSize(bytes, path);
        expect(size, isNotNull, reason: '$path için boyut okunamadı');
        final ratio = size!.width / size.height;
        expect(
          ratio,
          inClosedOpenRange(0.5, 2.0),
          reason: '$path aşırı panoramik bir kaynak görsel ($ratio oranı)',
        );
      }
    });
  });
}

/// `GlowDetailHeroImage`'s own element is the outer `Center`, which — inside
/// a `ListView`'s tightly cross-axis-constrained slot — reports the full
/// slot width even though its child is narrower and centered within it. The
/// actual visible image bounds are the inner `ClipRRect` from
/// `GlowCatalogImage`, so measure that instead.
Size _visibleImageSize(WidgetTester tester, Finder heroFinder) {
  final clip = find.descendant(
    of: heroFinder,
    matching: find.byType(ClipRRect),
  );
  expect(clip, findsOneWidget);
  return tester.getSize(clip);
}

class _ImageSize {
  const _ImageSize(this.width, this.height);
  final int width;
  final int height;
}

/// Minimal PNG/JPEG dimension reader — enough to sanity-check aspect ratio
/// without pulling in an image-decoding package just for a test.
_ImageSize? _decodePngOrJpegSize(List<int> bytes, String path) {
  if (bytes.length > 24 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    return _ImageSize(width, height);
  }
  if (bytes.length > 4 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    var offset = 2;
    while (offset + 9 < bytes.length) {
      if (bytes[offset] != 0xFF) {
        offset++;
        continue;
      }
      final marker = bytes[offset + 1];
      if (marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8) {
        final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
        final width = (bytes[offset + 7] << 8) | bytes[offset + 8];
        return _ImageSize(width, height);
      }
      final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
      offset += 2 + length;
    }
  }
  return null;
}

class _SignedOutController extends AuthController {
  _SignedOutController() : super(_UnusedBackend()) {
    state = const AsyncValue.data(null);
  }
}

class _UnusedBackend implements AuthBackend {
  @override
  Future<AuthSession?> currentSession() async => null;
  @override
  Future<void> logout() async {}
  @override
  Future<AuthSession> login({
    required String username,
    required String password,
    String role = 'CUSTOMER',
  }) =>
      throw UnimplementedError();
  @override
  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) =>
      throw UnimplementedError();
}
