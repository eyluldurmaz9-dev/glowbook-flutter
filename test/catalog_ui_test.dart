import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/widgets/glow_widgets.dart';
import 'package:glowbook_flutter/features/catalog/catalog_models.dart';
import 'package:glowbook_flutter/features/package/packages_page.dart';
import 'package:glowbook_flutter/features/service/service_detail_page.dart';
import 'package:glowbook_flutter/features/service/services_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

void main() {
  testWidgets('Hizmet listesi success state gösterir', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ServicesCatalogContent(
          services: const [
            CatalogService(id: 1, name: 'Hydrafacial', description: 'Bakım'),
          ],
          searchController: TextEditingController(),
          query: '',
          onQueryChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Hydrafacial'), findsOneWidget);
  });

  testWidgets('Hizmet listesi empty state gösterir', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ServicesCatalogContent(
          services: const [],
          searchController: TextEditingController(),
          query: '',
          onQueryChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Hizmet bulunamadı'), findsOneWidget);
  });

  testWidgets('Hizmet listesi error state gösterir', (tester) async {
    await tester.pumpWidget(
      _wrap(const ServicesCatalogError(message: 'Sunucu hatası')),
    );

    expect(find.text('Sunucu hatası'), findsOneWidget);
  });

  testWidgets('Paket listesi success state gösterir', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PackagesCatalogContent(
          packages: const [
            CatalogPackage(
              id: 3,
              serviceId: 1,
              name: '6 Seans Bakım',
              priceText: '1200.0',
            ),
          ],
          searchController: TextEditingController(),
          query: '',
          onQueryChanged: (_) {},
        ),
      ),
    );

    expect(find.text('6 Seans Bakım'), findsOneWidget);
  });

  testWidgets('Paket listesi empty state gösterir', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PackagesCatalogContent(
          packages: const [],
          searchController: TextEditingController(),
          query: '',
          onQueryChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Paket bulunamadı'), findsOneWidget);
  });

  testWidgets('Paket listesi error state gösterir', (tester) async {
    await tester.pumpWidget(
      _wrap(const PackagesCatalogError(message: 'Paket API hatası')),
    );

    expect(find.text('Paket API hatası'), findsOneWidget);
  });

  testWidgets('Hizmet detayına navigation çalışır', (tester) async {
    final router = GoRouter(
      initialLocation: '/services',
      routes: [
        GoRoute(
          path: '/services',
          builder: (context, state) => const ServicesPage(),
        ),
        GoRoute(
          path: '/services/:serviceId',
          builder: (context, state) => ServiceDetailPage(
            serviceId: int.parse(state.pathParameters['serviceId']!),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _ReadyAuthController(_FakeAuthBackend()),
          ),
          servicesProvider.overrideWith(
            (ref) async => [
              {
                'serviceId': 7,
                'serviceName': 'Hydrafacial',
                'description': 'Bakım',
              },
            ],
          ),
          serviceOptionsProvider.overrideWith(
            (ref, serviceId) async => const [],
          ),
          servicePackagesProvider.overrideWith(
            (ref, serviceId) async => const [],
          ),
          employeesByServiceProvider.overrideWith(
            (ref, serviceId) async => const [],
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    final serviceCard = find.byType(GlowServiceCard).first;
    expect(serviceCard, findsOneWidget);
    await tester.ensureVisible(serviceCard);
    await tester.tap(
      find.descendant(of: serviceCard, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();

    expect(router.location, '/services/7');
    expect(find.text('Alt hizmetler'), findsOneWidget);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.lightTheme, home: Scaffold(body: child));
}

class _FakeAuthBackend implements AuthBackend {
  @override
  Future<AuthSession?> currentSession() async => null;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
    String role = 'CUSTOMER',
  }) async {
    return AuthSession(token: 'token', role: role);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) async {
    return const AuthSession(token: 'token', role: 'CUSTOMER');
  }
}

class _ReadyAuthController extends AuthController {
  _ReadyAuthController(super.backend) {
    state = const AsyncValue.data(null);
  }
}
