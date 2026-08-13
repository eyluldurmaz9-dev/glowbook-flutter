import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/widgets/glow_widgets.dart';
import 'package:glowbook_flutter/features/catalog/service_image_resolver.dart';
import 'package:glowbook_flutter/features/package/package_detail_page.dart';
import 'package:glowbook_flutter/features/service/service_detail_page.dart';
import 'package:glowbook_flutter/features/service/services_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

void main() {
  testWidgets('Mobil Hizmetler alanı Paketleri Gör eylemini açıkça sunar',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: ServicesCatalogContent(
          services: const [],
          searchController: TextEditingController(),
          query: '',
          onQueryChanged: (_) {},
        ),
      ),
    ));

    expect(find.byKey(const Key('services_open_packages')), findsOneWidget);
    expect(find.text('Paketleri Gör'), findsOneWidget);
    expect(
        tester
            .widget<OutlinedButton>(
                find.byKey(const Key('services_open_packages')))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Hizmet detayı yalnızca ilgili paketleri ve booking linklerini gösterir',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        servicesProvider.overrideWith((ref) async => const [
              {'serviceId': 7, 'serviceName': 'Cilt Bakımı', 'active': true},
            ]),
        serviceOptionsProvider.overrideWith((ref, id) async => const []),
        servicePackagesProvider.overrideWith((ref, id) async => const [
              {
                'packageId': 70,
                'serviceId': 7,
                'serviceName': 'Cilt Bakımı',
                'packageName': 'İlgili Cilt Paketi',
                'active': true,
              },
              {
                'packageId': 99,
                'serviceId': 99,
                'serviceName': 'Başka Hizmet',
                'packageName': 'İlgisiz Paket',
                'active': true,
              },
            ]),
        employeesByServiceProvider.overrideWith((ref, id) async => const []),
      ],
      child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ServiceDetailPage(serviceId: 7)),
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Bu hizmet için paketler'), 320);
    await tester.pumpAndSettle();

    expect(find.text('Bu hizmet için paketler'), findsOneWidget);
    expect(find.text('İlgili Cilt Paketi'), findsOneWidget);
    expect(find.text('İlgisiz Paket'), findsNothing);
    expect(find.byKey(const Key('service_detail_packages')), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const Key('service_detail_book')), 420);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('service_detail_book')), findsOneWidget);
    expect(find.text('Randevu Al'), findsOneWidget);
    expect(
        tester
            .widget<GlowButton>(find.byKey(const Key('service_detail_book')))
            .onPressed,
        isNotNull);
  });

  testWidgets('Paket detayı ilgili hizmete geri dönüş bağlantısı gösterir',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authControllerProvider
            .overrideWith((ref) => _SignedOutController(_FakeAuthBackend())),
        servicePackagesProvider.overrideWith((ref, id) async => const [
              {
                'packageId': 3,
                'serviceId': 3,
                'serviceName': 'Masaj ve Spa',
                'packageName': 'Spa Yenilenme Paketi',
                'totalSession': 6,
                'active': true,
              },
            ]),
      ],
      child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PackageDetailPage(serviceId: 3, packageId: 3)),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('package_detail_service')), findsOneWidget);
    expect(find.text('Masaj ve Spa hizmetini gör'), findsOneWidget);
    final hero = find.descendant(
      of: find.byKey(const Key('package_detail_hero_3')),
      matching: find.byType(Image),
    );
    expect(hero, findsOneWidget);
    expect(
      (tester.widget<Image>(hero).image as AssetImage).assetName,
      GlowBookAssets.spa,
    );
    expect(
        tester
            .widget<OutlinedButton>(
                find.byKey(const Key('package_detail_service')))
            .onPressed,
        isNotNull);
  });
}

class _FakeAuthBackend implements AuthBackend {
  @override
  Future<AuthSession?> currentSession() async => null;
  @override
  Future<void> logout() async {}
  @override
  Future<AuthSession> login(
          {required String username,
          required String password,
          String role = 'CUSTOMER'}) async =>
      const AuthSession(token: 'token', role: 'CUSTOMER');
  @override
  Future<AuthSession> register(
          {required String firstName,
          required String lastName,
          required String phone,
          required String password,
          String? email}) async =>
      const AuthSession(token: 'token', role: 'CUSTOMER');
}

class _SignedOutController extends AuthController {
  _SignedOutController(super.backend) {
    state = const AsyncValue.data(null);
  }
}
