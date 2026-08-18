import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/routes/app_routes.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/package/package_detail_page.dart';
import 'package:glowbook_flutter/features/package/packages_page.dart';
import 'package:glowbook_flutter/features/profile/profile_page.dart';
import 'package:glowbook_flutter/features/service/service_detail_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Regression coverage: the package detail "Geri" button used to call
/// `Navigator.of(context).maybePop()` while every forward navigation in the
/// app goes through GoRouter's stack-replacing `go()` — so there was nothing
/// to pop and the button silently did nothing. `AppNavigation.back` now
/// falls back to a real destination, and it must never be the generic
/// "Bir şey ters gitti" error screen.
void main() {
  const package = {
    'packageId': 201,
    'serviceId': 2,
    'serviceName': 'Lazer Epilasyon',
    'packageName': '10 Seans Lazer',
    'totalSession': 10,
    'price': '1500',
    'active': true,
  };

  GoRouter buildRouter(String initialLocation) => GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: AppRoutes.packageDetail,
            builder: (context, state) => PackageDetailPage(
              serviceId: int.parse(state.pathParameters['serviceId']!),
              packageId: int.parse(state.pathParameters['packageId']!),
              origin: state.queryParameters['origin'],
            ),
          ),
          GoRoute(
            path: AppRoutes.serviceDetail,
            builder: (context, state) => ServiceDetailPage(
              serviceId: int.parse(state.pathParameters['serviceId']!),
            ),
          ),
          GoRoute(
            path: AppRoutes.services,
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('SERVICES_ROUTE_MARKER')),
            ),
          ),
          GoRoute(
            path: AppRoutes.packages,
            builder: (context, state) => const PackagesPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      );

  List<Override> commonOverrides() => [
        servicesProvider.overrideWith((ref) async => const [
              {
                'serviceId': 2,
                'serviceName': 'Lazer Epilasyon',
                'description': 'Bakım',
              },
            ]),
        serviceOptionsProvider.overrideWith((ref, id) async => const []),
        servicePackagesProvider.overrideWith((ref, id) async => const [package]),
        employeesByServiceProvider.overrideWith((ref, id) async => const []),
        allServicePackagesProvider.overrideWith((ref) async => const [package]),
        // Reached only by the "origin=profile" case, but harmless to mock
        // for every case: ProfilePage must never hit a real backend in tests.
        authControllerProvider.overrideWith((ref) => _ReadyAuthController()),
        profileProvider.overrideWith((ref) async => const {
              'customerId': 12,
              'firstName': 'Derya',
              'lastName': 'Yılmaz',
              'phone': '05551110000',
              'email': 'derya@glowbook.test',
            }),
        customerPackagesProvider.overrideWith((ref, id) async => const []),
        customerUpcomingAppointmentsProvider
            .overrideWith((ref, id) async => const []),
        customerPastAppointmentsProvider
            .overrideWith((ref, id) async => const []),
      ];

  Future<void> pumpAt(
    WidgetTester tester,
    GoRouter router,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: commonOverrides(),
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Kaynağı belirtilmeyen paket detayında Geri hizmet sayfasına döner',
      (tester) async {
    final router = buildRouter('/packages/2/201');
    await pumpAt(tester, router);

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();

    expect(router.location, '/services/2');
    expect(find.text('Bir şey ters gitti'), findsNothing);
  });

  testWidgets('Paketlerim üzerinden açılan paket detayında Geri profile döner',
      (tester) async {
    final router = buildRouter('/packages/2/201?origin=profile');
    await pumpAt(tester, router);

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();

    expect(router.location, AppRoutes.profile);
    expect(find.text('Bir şey ters gitti'), findsNothing);
  });

  testWidgets('Paket katalogundan açılan paket detayında Geri katalog listesine döner',
      (tester) async {
    final router = buildRouter('/packages/2/201?origin=catalog');
    await pumpAt(tester, router);

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();

    expect(router.location, AppRoutes.packages);
    expect(find.text('Bir şey ters gitti'), findsNothing);
  });

  testWidgets('Hizmet detayında Geri her zaman gerçek bir hedefe gider',
      (tester) async {
    final router = buildRouter('/services/2');
    await pumpAt(tester, router);

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();

    expect(router.location, AppRoutes.services);
    expect(find.text('Bir şey ters gitti'), findsNothing);
  });
}

class _ReadyAuthController extends AuthController {
  _ReadyAuthController()
      : super(GlowBackendService(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        )) {
    state = const AsyncValue.data(
      AuthSession(
        token: 'token',
        role: 'CUSTOMER',
        customerId: 12,
        fullName: 'Derya Yılmaz',
      ),
    );
  }
}
