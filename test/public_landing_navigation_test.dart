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
import 'package:glowbook_flutter/features/appointment/appointment_page.dart';
import 'package:glowbook_flutter/features/auth/login_page.dart';
import 'package:glowbook_flutter/features/package/packages_page.dart';
import 'package:glowbook_flutter/features/service/services_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// "Ana Sayfaya Dön" is a distinct control from the booking wizard's own
/// step-back "Geri": it always leaves for the real public landing route
/// (AppRoutes.welcome — WelcomePage in production, the "Güzelliği
/// planlamanın en kolay yolu." screen; its own rendering, hero image
/// included, is covered separately by widget_test.dart) regardless of step,
/// Navigator history, or auth state — and never touches the session, unlike
/// "Çıkış Yap". The route itself, not WelcomePage's heavy image widget
/// tree, is what these tests need to prove, so /welcome resolves to a
/// lightweight marker here — the same technique booking_flow_test.dart uses
/// for its own Home-fallback assertion.
void main() {
  Finder publicLandingMarker() => find.text('PUBLIC_LANDING_MARKER');

  testWidgets('Hizmetler ekranı → Ana Sayfaya Dön → Public Landing',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          servicesProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: _routerStartingAt(AppRoutes.services),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('services_public_home')), findsOneWidget);
    await tester.tap(find.byKey(const Key('services_public_home')));
    await tester.pumpAndSettle();

    expect(publicLandingMarker(), findsOneWidget);
  });

  testWidgets('Paketler ekranı → Ana Sayfaya Dön → Public Landing',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allServicePackagesProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: _routerStartingAt(AppRoutes.packages),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('packages_public_home')), findsOneWidget);
    await tester.tap(find.byKey(const Key('packages_public_home')));
    await tester.pumpAndSettle();

    expect(publicLandingMarker(), findsOneWidget);
  });

  testWidgets('Misafir erişimi ekranı → Ana Sayfaya Dön → Public Landing',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: _routerStartingAt(
            '${AppRoutes.login}?mode=guest',
            loginRoute: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('guest_access_public_home')), findsOneWidget);
    await tester.tap(find.byKey(const Key('guest_access_public_home')));
    await tester.pumpAndSettle();

    expect(publicLandingMarker(), findsOneWidget);
  });

  group('Randevu sihirbazı', () {
    late ProviderContainer container;
    late GoRouter router;

    Future<void> pumpBookingWithSession(WidgetTester tester) async {
      final backend = _FakeBackend();
      container = ProviderContainer(overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith((ref) => _ReadyAuthController(backend)),
        servicesProvider.overrideWith((ref) async => const [
              {'serviceId': 1, 'serviceName': 'Hydrafacial', 'description': 'Bakım'},
            ]),
        serviceOptionsProvider.overrideWith((ref, id) async => const []),
        servicePackagesProvider.overrideWith((ref, id) async => const []),
        customerPackagesProvider.overrideWith((ref, id) async => const []),
        customerUpcomingAppointmentsProvider
            .overrideWith((ref, id) async => const []),
      ]);
      addTearDown(container.dispose);
      router = _routerStartingAt(AppRoutes.appointment);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'Geri (adım) ve Ana Sayfaya Dön aynı ekranda iki ayrı kontroldür',
        (tester) async {
      await pumpBookingWithSession(tester);

      expect(find.byKey(const Key('booking_top_back')), findsOneWidget);
      expect(find.byKey(const Key('booking_public_home')), findsOneWidget);
    });

    testWidgets('Ana Sayfaya Dön → Public Landing (history yokken de)',
        (tester) async {
      await pumpBookingWithSession(tester);

      await tester.tap(find.byKey(const Key('booking_public_home')));
      await tester.pumpAndSettle();

      expect(publicLandingMarker(), findsOneWidget);
    });

    testWidgets('Ana Sayfaya Dön oturumu/token\'ı silmez', (tester) async {
      await pumpBookingWithSession(tester);

      final sessionBefore =
          container.read(authControllerProvider).asData?.value;
      expect(sessionBefore?.customerId, 12);

      await tester.tap(find.byKey(const Key('booking_public_home')));
      await tester.pumpAndSettle();

      final sessionAfter =
          container.read(authControllerProvider).asData?.value;
      expect(sessionAfter?.customerId, 12,
          reason: 'Ana Sayfaya Dön oturumu sonlandırmamalı');
    });
  });
}

GoRouter _routerStartingAt(String initialLocation, {bool loginRoute = false}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('PUBLIC_LANDING_MARKER')),
        ),
      ),
      GoRoute(
        path: AppRoutes.services,
        builder: (context, state) => const ServicesPage(),
      ),
      GoRoute(
        path: AppRoutes.packages,
        builder: (context, state) => const PackagesPage(),
      ),
      GoRoute(
        path: AppRoutes.appointment,
        builder: (context, state) => const AppointmentPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginPage(
          guestMode: state.queryParameters['mode'] == 'guest',
        ),
      ),
    ],
  );
}

class _FakeBackend extends GlowBackendService {
  _FakeBackend()
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );
}

class _ReadyAuthController extends AuthController {
  _ReadyAuthController(super.backend) {
    state = const AsyncValue.data(
      AuthSession(token: 'token', role: 'CUSTOMER', customerId: 12),
    );
  }
}
