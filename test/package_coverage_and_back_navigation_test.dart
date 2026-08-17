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
import 'package:glowbook_flutter/features/appointment/booking_models.dart';
import 'package:glowbook_flutter/features/package/package_detail_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Regression coverage for KOMUT 2: a Hydrafacial-only package must never
/// offer Akne Bakımı, and Back navigation (in-page button, hardware/system
/// back) must step through the wizard without ever losing the package
/// context or surfacing the generic "Bir şey ters gitti" error.
void main() {
  const hydrafacialContext = PackageBookingContext(
    packageId: 301,
    serviceId: 1,
    packageName: 'Hydrafacial Bakım Paketi',
    serviceName: 'Cilt Bakımı',
    totalSession: 5,
    // Package detail derives this silently before navigating here, since
    // Hydrafacial Bakım (id 51) is the package's only covered option — Akne
    // Bakımı (id 53) belongs to the same service but is never part of it.
    optionId: 51,
    coveredOptionIds: [51],
  );

  testWidgets(
      'Hydrafacial paketi randevu akışında Akne Bakımı asla seçilebilir olmaz',
      (tester) async {
    await _pumpPackageBooking(
      tester,
      backend: _FakeBackend(),
      packageContext: hydrafacialContext,
    );

    // A single covered option is derived silently — no option step at all,
    // straight to personel — so Akne Bakımı is never even offered.
    expect(find.text('Personel seçimi'), findsOneWidget);
    expect(find.text('Paket kapsamındaki hizmeti seç'), findsNothing);
    expect(find.text('Akne Bakımı'), findsNothing);
    expect(find.text('Hizmet seçimi'), findsNothing);
  });

  testWidgets(
      'Birden fazla seçenekli pakette kapsam dışı hizmet (Akne Bakımı) hiç listelenmez',
      (tester) async {
    await _pumpPackageBooking(
      tester,
      backend: _FakeBackend(),
      // Same "Cilt Bakımı" service, but this package covers two options —
      // Hydrafacial and Klasik Cilt Bakımı — never Akne Bakımı.
      packageContext: const PackageBookingContext(
        packageId: 302,
        serviceId: 1,
        packageName: 'Cilt Bakımı Paketi',
        serviceName: 'Cilt Bakımı',
        totalSession: 4,
        coveredOptionIds: [51, 52],
      ),
    );

    expect(find.text('Paket kapsamındaki hizmeti seç'), findsOneWidget);
    // Both covered options are offered...
    expect(find.text('Hydrafacial Bakım'), findsOneWidget);
    expect(find.text('Klasik Cilt Bakımı'), findsOneWidget);
    // ...but the uncovered sibling under the very same service never is,
    // even though the fake catalog serves it alongside the covered ones.
    expect(find.text('Akne Bakımı'), findsNothing);
  });

  testWidgets(
      'Özet adımından Personel adımına kadar Geri butonu paket bağlamını korur ve genel hata göstermez',
      (tester) async {
    await _pumpPackageBooking(
      tester,
      backend: _FakeBackend(),
      packageContext: hydrafacialContext,
    );

    // Personel → Tarih → Saat → Özet.
    await _tapText(tester, 'Eylem Ceylan');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapTextContaining(tester, '14:00');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    expect(find.text('Randevu özeti'), findsOneWidget);

    // Three rounds of Geri: Özet → Saat → Tarih → Personel. Package context
    // (the banner naming the package) must survive every single step, and
    // the generic error widget must never appear.
    for (final expectedTitle in [
      'Uygun zaman aralığı',
      'Tarih seçimi',
      'Personel seçimi',
    ]) {
      await _tapText(tester, 'Geri');
      await tester.pumpAndSettle();
      expect(find.text(expectedTitle), findsOneWidget,
          reason: 'Geri sonrası beklenen adım: $expectedTitle');
      expect(find.byKey(const Key('package_booking_context')), findsOneWidget,
          reason: 'Paket bağlamı Geri sonrası kaybolmamalı');
      expect(find.text('Hydrafacial Bakım Paketi'), findsOneWidget);
      expect(find.text('Bir şey ters gitti'), findsNothing);
    }

    // At the first step the in-page Geri button is disabled, not crashing.
    expect(find.text('Personel seçimi'), findsOneWidget);
  });

  testWidgets(
      'Personel adımındayken sistem geri hareketi sihirbazdan çıkmak yerine adımı geri alır',
      (tester) async {
    await _pumpPackageBooking(
      tester,
      backend: _FakeBackend(),
      packageContext: hydrafacialContext,
    );

    await _tapText(tester, 'Eylem Ceylan');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    expect(find.text('Tarih seçimi'), findsOneWidget);

    // Simulate Android hardware back / iOS swipe-back via the same
    // Navigator.maybePop path PopScope intercepts — must land back on the
    // previous wizard step, not leave AppointmentPage.
    final context = tester.element(find.byType(AppointmentPage));
    final popped = await Navigator.maybePop(context);
    await tester.pumpAndSettle();

    expect(popped, isTrue, reason: 'PopScope onPopInvokedWithResult tetiklenmeli');
    expect(find.byType(AppointmentPage), findsOneWidget);
    expect(find.text('Personel seçimi'), findsOneWidget);
    expect(find.byKey(const Key('package_booking_context')), findsOneWidget);
    expect(find.text('Bir şey ters gitti'), findsNothing);
  });

  testWidgets('Normal randevu akışında hizmet seçimi adımı hâlâ zorunludur',
      (tester) async {
    // Regression: package-mode changes must never bleed into the ordinary,
    // non-package booking flow — it still asks for a service explicitly.
    await _pumpPackageBooking(
      tester,
      backend: _FakeBackend(),
      packageContext: null,
    );

    expect(find.text('Hizmet seçimi'), findsOneWidget);
    expect(find.text('Personel seçimi'), findsNothing);
    expect(find.byKey(const Key('package_booking_context')), findsNothing);
  });
}

Future<void> _tapText(WidgetTester tester, String text, {bool last = false}) async {
  final matches = find.text(text);
  if (matches.evaluate().isEmpty) {
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .join(' | ');
    fail('Metin bulunamadı: $text. Ekrandaki metinler: $texts');
  }
  final finder = last ? matches.last : matches.first;
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
}

Future<void> _tapTextContaining(WidgetTester tester, String text) async {
  final finder = find.textContaining(text);
  if (finder.evaluate().isEmpty) {
    fail('Metin parçası bulunamadı: $text');
  }
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first, warnIfMissed: false);
}

Future<GoRouter> _pumpPackageBooking(
  WidgetTester tester, {
  required _FakeBackend backend,
  required PackageBookingContext? packageContext,
}) async {
  final slotDay = DateTime.now().add(const Duration(days: 1));
  final slotDate = '${slotDay.year.toString().padLeft(4, '0')}-'
      '${slotDay.month.toString().padLeft(2, '0')}-'
      '${slotDay.day.toString().padLeft(2, '0')}';

  final router = GoRouter(
    initialLocation: AppRoutes.appointment,
    routes: [
      GoRoute(
        path: AppRoutes.appointment,
        builder: (context, state) =>
            AppointmentPage(packageContext: packageContext),
      ),
      GoRoute(
        path: '/packages/:serviceId/:packageId',
        builder: (context, state) => PackageDetailPage(
          serviceId: int.parse(state.pathParameters['serviceId']!),
          packageId: int.parse(state.pathParameters['packageId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('PROFILE_ROUTE_MARKER'))),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith((ref) => _ReadyAuthController(backend)),
        servicesProvider.overrideWith(
          (ref) async => const [
            {'serviceId': 1, 'serviceName': 'Cilt Bakımı', 'description': ''},
          ],
        ),
        // A shared, unfiltered catalog for "Cilt Bakımı" — includes an
        // uncovered sibling (Akne Bakımı) so the coverage filter is
        // genuinely exercised rather than trivially satisfied by absence.
        serviceOptionsProvider.overrideWith(
          (ref, serviceId) async => const [
            {
              'optionId': 51,
              'serviceId': 1,
              'optionName': 'Hydrafacial Bakım',
              'price': '1500',
            },
            {
              'optionId': 52,
              'serviceId': 1,
              'optionName': 'Klasik Cilt Bakımı',
              'price': '900',
            },
            {
              'optionId': 53,
              'serviceId': 1,
              'optionName': 'Akne Bakımı',
              'price': '1400',
            },
          ],
        ),
        servicePackagesProvider.overrideWith((ref, serviceId) async => const []),
        customerPackagesProvider.overrideWith((ref, customerId) async => backend.packages),
        employeesByServiceOptionProvider.overrideWith(
          (ref, query) async => const [
            {'employeeId': 'EMP-2', 'employeeName': 'Eylem Ceylan'},
          ],
        ),
        availableSlotsProvider.overrideWith(
          (ref, query) async => [
            {
              'employeeId': 'EMP-2',
              'employeeName': 'Eylem Ceylan',
              'appointmentDate': slotDate,
              'availableTimes': ['14:00:00', '14:30:00'],
            },
          ],
        ),
        customerUpcomingAppointmentsProvider
            .overrideWith((ref, customerId) async => backend.upcomingAppointments),
        customerPastAppointmentsProvider.overrideWith((ref, customerId) async => const []),
        profileProvider.overrideWith(
          (ref) async => const {
            'customerId': 12,
            'firstName': 'Derya',
            'lastName': 'Yılmaz',
            'phone': '05551110000',
            'email': 'derya@glowbook.test',
          },
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

class _FakeBackend extends GlowBackendService {
  _FakeBackend()
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  final List<Map<String, dynamic>> upcomingAppointments = [];
  final List<Map<String, dynamic>> packages = const [];

  @override
  Future<Map<String, dynamic>> purchasePackageWithFirstAppointment({
    required int customerId,
    required int packageId,
    required String employeeId,
    int? optionId,
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    final appointment = {
      'appointmentId': 42,
      'customerId': customerId,
      'employeeId': employeeId,
      'employeeName': 'Eylem Ceylan',
      'serviceId': 1,
      'serviceName': 'Cilt Bakımı',
      'optionId': optionId,
      'optionName': 'Hydrafacial Bakım',
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'price': '1500',
      'status': 'PENDING',
    };
    upcomingAppointments.add(appointment);
    return {
      'customerPackage': {
        'customerPackageId': 5,
        'packageId': packageId,
        'packageName': 'Hydrafacial Bakım Paketi',
        'totalSession': 5,
        'usedSession': 0,
        'scheduledSession': 1,
        'remainingSession': 4,
        'active': true,
      },
      'appointment': appointment,
    };
  }

  @override
  Future<AuthSession?> currentSession() async => const AuthSession(
        token: 'token',
        role: 'CUSTOMER',
        customerId: 12,
        fullName: 'Derya Yılmaz',
      );
}

class _ReadyAuthController extends AuthController {
  _ReadyAuthController(super.backend) {
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
