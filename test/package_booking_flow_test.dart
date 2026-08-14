import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/appointment/appointment_page.dart';
import 'package:glowbook_flutter/features/appointment/booking_models.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Package booking must carry the already chosen service forward and go
/// straight to personel → tarih → saat → özet.
void main() {
  const packageContext = PackageBookingContext(
    packageId: 201,
    serviceId: 2,
    optionId: 22,
    packageName: '10 Seans Lazer',
    serviceName: 'Lazer Epilasyon',
    totalSession: 10,
  );

  testWidgets('Paket akışı hizmeti tekrar sormaz ve personelle başlar',
      (tester) async {
    await _pumpPackageBooking(tester, backend: _FakeBackend());

    // The stepper starts at Personel — no Hizmet or Seçenek step at all.
    expect(find.text('Personel seçimi'), findsOneWidget);
    expect(find.text('Hizmet seçimi'), findsNothing);
    expect(find.text('Alt hizmet ve paket'), findsNothing);
    expect(find.byKey(const Key('package_employee_step')), findsOneWidget);

    // The already made choice stays visible instead of being asked again.
    expect(find.byKey(const Key('package_booking_context')), findsOneWidget);
    expect(find.text('10 Seans Lazer'), findsOneWidget);
    expect(find.text('Hizmetini tekrar seçmene gerek yok.'), findsOneWidget);
  });

  testWidgets('Paket akışı personel → tarih → saat → özet sırasını izler',
      (tester) async {
    await _pumpPackageBooking(tester, backend: _FakeBackend());

    await _tapText(tester, 'Eylem Ceylan');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    expect(find.text('Tarih seçimi'), findsOneWidget);

    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    expect(find.text('Uygun zaman aralığı'), findsOneWidget);

    await _tapTextContaining(tester, '14:00');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();

    expect(find.text('Randevu özeti'), findsOneWidget);
    expect(find.text('Bu randevu 1 seans kullanır (toplam 10 seans)'),
        findsOneWidget);
  });

  testWidgets('Paket saat adımı yalnızca seçilen personelin saatlerini gösterir',
      (tester) async {
    await _pumpPackageBooking(tester, backend: _FakeBackend());

    await _tapText(tester, 'Eylem Ceylan');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();

    expect(find.textContaining('Eylem Ceylan'), findsWidgets);
    expect(find.textContaining('Baska Personel'), findsNothing);
  });

  testWidgets('Paket saatleri yalnızca tam saat gösterir', (tester) async {
    await _pumpPackageBooking(tester, backend: _FakeBackend());

    await _tapText(tester, 'Eylem Ceylan');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();

    expect(find.textContaining('14:00'), findsOneWidget);
    expect(find.textContaining('14:30'), findsNothing);
    expect(find.textContaining('15:30'), findsNothing);
  });

  testWidgets('Paket onayı tek çağrıda satın alma ve ilk randevu oluşturur',
      (tester) async {
    final backend = _FakeBackend();
    await _pumpPackageBooking(tester, backend: backend);

    await _completePackageSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();

    expect(backend.packageBookingCount, 1);
    expect(backend.createAppointmentCount, 0);
    expect(backend.lastPackageBooking?['packageId'], 201);
    expect(backend.lastPackageBooking?['employeeId'], 'EMP-2');
    expect(backend.lastPackageBooking?['appointmentTime'], '14:00');
    // The service is never re-sent: the backend derives it from the package.
    expect(backend.lastPackageBooking?.containsKey('serviceId'), isFalse);
    expect(find.text('Randevun oluşturuldu'), findsOneWidget);
  });

  testWidgets('Paket akışında teknik terimler kullanıcıya gösterilmez',
      (tester) async {
    await _pumpPackageBooking(tester, backend: _FakeBackend());
    await _completePackageSelections(tester);

    final visible = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .join(' ')
        .toLowerCase();
    for (final banned in [
      'backend',
      'endpoint',
      'http',
      'json',
      'dto',
      'utc',
      'database',
      'server',
    ]) {
      expect(visible.contains(banned), isFalse, reason: 'sızan terim: $banned');
    }
  });

  testWidgets('Dolu slot hatası saat adımına döner ve paketi korur',
      (tester) async {
    final backend = _FakeBackend(
      bookingError: Exception('Selected slot is not available'),
    );
    await _pumpPackageBooking(tester, backend: backend);

    await _completePackageSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await tester.pump();

    expect(find.text('Bu saat artık uygun değil. Lütfen başka bir saat seç.'),
        findsOneWidget);
    expect(find.text('Uygun zaman aralığı'), findsOneWidget);
    expect(find.byKey(const Key('package_booking_context')), findsOneWidget);
  });

  testWidgets(
      'Birden fazla seçenek kapsayan pakette yalnızca alt hizmet sorulur',
      (tester) async {
    await _pumpPackageBooking(
      tester,
      backend: _FakeBackend(),
      packageContext: const PackageBookingContext(
        packageId: 201,
        serviceId: 2,
        packageName: '10 Seans Lazer',
        serviceName: 'Lazer Epilasyon',
        totalSession: 10,
      ),
    );

    expect(find.text('Paket kapsamındaki hizmeti seç'), findsOneWidget);
    expect(find.text('Hizmet seçimi'), findsNothing);

    await _tapText(tester, '5 Bolge');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();

    expect(find.text('Personel seçimi'), findsOneWidget);
  });

  group('PackageBookingContext', () {
    test('rota sorgu parametrelerini ileri ve geri taşır', () {
      final route = packageContext.toRoute('/appointment');
      final parsed = PackageBookingContext.fromQuery(
        Uri.parse(route).queryParameters,
      );

      expect(parsed, isNotNull);
      expect(parsed!.packageId, 201);
      expect(parsed.serviceId, 2);
      expect(parsed.optionId, 22);
      expect(parsed.packageName, '10 Seans Lazer');
      expect(parsed.totalSession, 10);
      expect(parsed.needsPurchase, isTrue);
      expect(parsed.hasKnownOption, isTrue);
    });

    test('paket bilgisi olmayan rota bağlam üretmez', () {
      expect(PackageBookingContext.fromQuery(const {}), isNull);
      expect(PackageBookingContext.fromQuery(const {'packageId': '5'}), isNull);
    });
  });
}

Future<void> _completePackageSelections(WidgetTester tester) async {
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
}

Future<void> _pumpPackageBooking(
  WidgetTester tester, {
  required _FakeBackend backend,
  PackageBookingContext? packageContext,
}) async {
  final slotDay = DateTime.now().add(const Duration(days: 1));
  final slotDate = '${slotDay.year.toString().padLeft(4, '0')}-'
      '${slotDay.month.toString().padLeft(2, '0')}-'
      '${slotDay.day.toString().padLeft(2, '0')}';

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith((ref) => _ReadyAuthController(backend)),
        servicesProvider.overrideWith((ref) async => const []),
        serviceOptionsProvider.overrideWith(
          (ref, serviceId) async => const [
            {
              'optionId': 22,
              'serviceId': 2,
              'optionName': '5 Bolge',
              'price': '1650',
            },
          ],
        ),
        servicePackagesProvider.overrideWith((ref, serviceId) async => const []),
        customerPackagesProvider.overrideWith((ref, customerId) async => const []),
        employeesByServiceOptionProvider.overrideWith(
          (ref, query) async => const [
            {'employeeId': 'EMP-2', 'employeeName': 'Eylem Ceylan'},
            {'employeeId': 'EMP-9', 'employeeName': 'Baska Personel'},
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
            {
              'employeeId': 'EMP-9',
              'employeeName': 'Baska Personel',
              'appointmentDate': slotDate,
              'availableTimes': ['15:00:00', '15:30:00'],
            },
          ],
        ),
        customerUpcomingAppointmentsProvider
            .overrideWith((ref, customerId) async => const []),
        customerPastAppointmentsProvider
            .overrideWith((ref, customerId) async => const []),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: AppointmentPage(
          packageContext: packageContext ??
              const PackageBookingContext(
                packageId: 201,
                serviceId: 2,
                optionId: 22,
                packageName: '10 Seans Lazer',
                serviceName: 'Lazer Epilasyon',
                totalSession: 10,
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapText(
  WidgetTester tester,
  String text, {
  bool last = false,
}) async {
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

class _FakeBackend extends GlowBackendService {
  _FakeBackend({this.bookingError})
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  final Object? bookingError;
  int packageBookingCount = 0;
  int createAppointmentCount = 0;
  Map<String, dynamic>? lastPackageBooking;

  @override
  Future<Map<String, dynamic>> purchasePackageWithFirstAppointment({
    required int customerId,
    required int packageId,
    required String employeeId,
    int? optionId,
    required String appointmentDate,
    required String appointmentTime,
  }) async {
    packageBookingCount++;
    lastPackageBooking = {
      'customerId': customerId,
      'packageId': packageId,
      'employeeId': employeeId,
      if (optionId != null) 'optionId': optionId,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
    };
    if (bookingError != null) throw bookingError!;
    return {
      'customerPackage': {
        'customerPackageId': 5,
        'packageId': packageId,
        'packageName': '10 Seans Lazer',
        'totalSession': 10,
        'usedSession': 0,
        'scheduledSession': 1,
        'remainingSession': 9,
        'active': true,
      },
      'appointment': {
        'appointmentId': 42,
        'customerId': customerId,
        'employeeId': employeeId,
        'employeeName': 'Eylem Ceylan',
        'serviceId': 2,
        'serviceName': 'Lazer Epilasyon',
        'optionId': optionId,
        'optionName': '5 Bolge',
        'appointmentDate': appointmentDate,
        'appointmentTime': appointmentTime,
        'price': '1650',
        'status': 'PENDING',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> payload,
  ) async {
    createAppointmentCount++;
    return {'appointmentId': 1, 'status': 'PENDING'};
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
