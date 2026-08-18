import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/widgets/glow_widgets.dart';
import 'package:glowbook_flutter/features/home/home_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Regression guard for the crop fix: GlowCatalogImage sized as
/// `width: double.infinity` with a short fixed height forces BoxFit.cover
/// into an extreme aspect ratio, cropping a photo down to a thin sliver.
/// The home hero and GlowPackageCard must keep their image inside an
/// AspectRatio(16/9) instead of a bare fixed height — this is pure layout
/// math with no platform branch anywhere in the code, so proving it once
/// here holds for web and mobile alike (both run the exact same widget
/// tree). The admin service-card equivalent is covered by
/// admin_dashboard_test.dart, which already has the fixture for it.
void main() {
  testWidgets('Ana sayfa hero görseli 16/9 AspectRatio içinde render edilir',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          servicesProvider.overrideWith((ref) async => const []),
          authControllerProvider.overrideWith((ref) => _NoSessionAuthController()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<GlowCatalogImage>(find.byWidgetPredicate(
        (widget) =>
            widget is GlowCatalogImage &&
            widget.image != null &&
            widget.image!.contains('glowbook-hero')));
    final aspectRatio = tester.widget<AspectRatio>(find.ancestor(
      of: find.byWidget(image),
      matching: find.byType(AspectRatio),
    ));
    expect(aspectRatio.aspectRatio, 16 / 9);
  });

  testWidgets('GlowPackageCard görseli 16/9 AspectRatio içinde render edilir',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: GlowPackageCard(
            title: '10 Seans Lazer',
            description: 'Paket açıklaması',
            image: 'https://example.test/paket.jpg',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<GlowCatalogImage>(find.byType(GlowCatalogImage));
    final aspectRatio = tester.widget<AspectRatio>(find.ancestor(
      of: find.byWidget(image),
      matching: find.byType(AspectRatio),
    ));
    expect(aspectRatio.aspectRatio, 16 / 9);
  });
}

class _NoSessionAuthController extends AuthController {
  _NoSessionAuthController() : super(_NoopBackend()) {
    state = const AsyncValue.data(null);
  }
}

class _NoopBackend extends GlowBackendService {
  _NoopBackend()
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );
}
