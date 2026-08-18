import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/routes/app_routes.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/features/appointment/appointment_page.dart';
import 'package:glowbook_flutter/features/profile/profile_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

void main() {
  testWidgets('Tam saatler her gerçek personel için ayrı gösterilir',
      (tester) async {
    await _pumpBooking(
      tester,
      backend: _FakeGlowBackendService(),
      slots: const [
        {
          'employeeId': 'EMP-1',
          'employeeName': 'Elif Yılmaz',
          'availableTimes': ['10:00', '10:30'],
        },
        {
          'employeeId': 'EMP-2',
          'employeeName': 'Eylem Ceylan',
          'availableTimes': ['10:00'],
        },
      ],
    );
    await _tapText(tester, 'Hydrafacial');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Cilt Bakımı');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    // "İlk Müsait Zaman" keeps every qualified employee's hours on the saat
    // step instead of filtering down to one — that's what this test checks.
    await _tapText(tester, 'İlk Müsait Zaman');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();

    expect(find.textContaining('10:30'), findsNothing);
    expect(find.textContaining('Elif Yılmaz'), findsOneWidget);
    expect(find.textContaining('Eylem Ceylan'), findsOneWidget);
    expect(find.textContaining('uzman'), findsNothing);
  });

  testWidgets(
      'Sol üstteki geri butonu ilk adımda Ana Sayfaya döner',
      (tester) async {
    final router = await _pumpBooking(tester, backend: _FakeGlowBackendService());

    await tester.tap(find.byKey(const Key('booking_top_back')));
    await tester.pumpAndSettle();

    expect(find.text('HOME_ROUTE_MARKER'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        AppRoutes.home);
  });

  testWidgets(
      'Sol üstteki geri butonu ileri adımda önceki adıma döner',
      (tester) async {
    await _pumpBooking(tester, backend: _FakeGlowBackendService());

    await _tapText(tester, 'Hydrafacial');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    expect(find.text('Cilt Bakımı'), findsOneWidget);

    await tester.tap(find.byKey(const Key('booking_top_back')));
    await tester.pumpAndSettle();

    // Back on the service step, not Home: the wizard state (previously
    // selected Hydrafacial) survives the step-back.
    expect(find.text('HOME_ROUTE_MARKER'), findsNothing);
    expect(find.text('Hydrafacial'), findsOneWidget);
  });

  testWidgets(
      'Tam başarılı randevu akışı sonrası Randevu oluştur ekranından çıkılır',
      (tester) async {
    final backend = _FakeGlowBackendService();
    final router = await _pumpBooking(tester, backend: backend);

    await _completeSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();

    expect(backend.createCount, 1);
    // The customer is no longer inside the booking wizard.
    expect(router.location, AppRoutes.profile);
    expect(find.text('Randevu oluştur'), findsNothing);
    expect(find.text('Personel seçimi'), findsNothing);
    // The new appointment is visible on Randevularım without a manual refresh.
    expect(find.text('Randevularım'), findsOneWidget);
    expect(find.text('Yaklaşan Randevular'), findsOneWidget);
    expect(find.text('Hydrafacial'), findsWidgets);
  });

  testWidgets('Slot doldu hatası kullanıcıya Türkçe gösterilir',
      (tester) async {
    final backend = _FakeGlowBackendService(
      createError: Exception('Selected appointment time is already occupied'),
    );
    await _pumpBooking(tester, backend: backend);

    await _completeSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await tester.pump();

    expect(find.text('Bu saat artık uygun değil. Lütfen başka bir saat seç.'),
        findsOneWidget);
    expect(find.text('Saat'), findsOneWidget);
    expect(find.textContaining('backend'), findsNothing);
  });

  testWidgets('Ağ hatası güvenli hata mesajı gösterir', (tester) async {
    final backend = _FakeGlowBackendService(
      createError: Exception('Backend sunucusuna ulaşılamadı.'),
    );
    await _pumpBooking(tester, backend: backend);

    await _completeSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await tester.pump();

    expect(
        find.text('Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.'),
        findsOneWidget);
  });

  testWidgets('Yetkisiz oturum mesajı gösterilir', (tester) async {
    final backend = _FakeGlowBackendService(
      createError: Exception('401 unauthorized'),
    );
    await _pumpBooking(tester, backend: backend);

    await _completeSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await tester.pump();

    expect(find.text('Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap.'),
        findsOneWidget);
  });

  testWidgets('Bekleme listesine katılma gerçek endpoint çağrısını yapar',
      (tester) async {
    final backend = _FakeGlowBackendService();
    await _pumpBooking(tester, backend: backend, slots: const []);

    await _tapText(tester, 'Hydrafacial');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Cilt Bakımı');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'İlk Müsait Zaman');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Bekleme Listesine Katıl');
    await tester.pumpAndSettle();

    expect(find.text('Bekleme listesine eklendin'), findsOneWidget);
    expect(backend.waitlistCount, 1);
  });

  testWidgets('Geri navigasyonda seçim state korunur', (tester) async {
    await _pumpBooking(tester, backend: _FakeGlowBackendService());

    await _tapText(tester, 'Hydrafacial');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Cilt Bakımı');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Geri');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();

    expect(find.text('Cilt Bakımı'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });

  testWidgets('Çift gönderim tek randevu oluşturur', (tester) async {
    final backend = _FakeGlowBackendService();
    await _pumpBooking(tester, backend: backend);

    await _completeSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();

    expect(backend.createCount, 1);
  });
}

/// Wraps [AppointmentPage] with the same real [GoRouter] destinations the
/// production app uses (Randevularım/profile), so a successful booking's
/// navigation is exercised for real instead of being stubbed out — and
/// returns the router so tests can assert on where it actually landed.
Future<GoRouter> _pumpBooking(
  WidgetTester tester, {
  required _FakeGlowBackendService backend,
  List<Map<String, dynamic>>? slots,
}) async {
  final slotDay = DateTime.now().add(const Duration(days: 1));
  final slotDate = '${slotDay.year.toString().padLeft(4, '0')}-'
      '${slotDay.month.toString().padLeft(2, '0')}-'
      '${slotDay.day.toString().padLeft(2, '0')}';
  final effectiveSlots = (slots ??
          [
            {
              'employeeId': 'EMP-1',
              'employeeName': 'Elif Yılmaz',
              'appointmentDate': slotDate,
              'availableTimes': ['10:00:00'],
            }
          ])
      .map((slot) => {'appointmentDate': slotDate, ...slot})
      .toList();
  // The employee step now runs before tarih/saat, so it needs its own
  // qualified-employee list independent of slot availability — derive it
  // from the same fixture so existing per-test `slots` overrides keep
  // driving both the employee choices and the saat step consistently.
  final employeeChoices = [
    for (final slot in effectiveSlots)
      {
        'employeeId': slot['employeeId'],
        'employeeName': slot['employeeName'],
      },
  ];
  final router = GoRouter(
    initialLocation: AppRoutes.appointment,
    routes: [
      GoRoute(
        path: AppRoutes.appointment,
        builder: (context, state) => const AppointmentPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('HOME_ROUTE_MARKER')),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith(
          (ref) => _ReadyAuthController(backend),
        ),
        servicesProvider.overrideWith(
          (ref) async => const [
            {
              'serviceId': 1,
              'serviceName': 'Hydrafacial',
              'description': 'Bakım',
            },
          ],
        ),
        serviceOptionsProvider.overrideWith(
          (ref, serviceId) async => const [
            {
              'optionId': 11,
              'serviceId': 1,
              'optionName': 'Cilt Bakımı',
              'price': '900',
            },
          ],
        ),
        servicePackagesProvider
            .overrideWith((ref, serviceId) async => const []),
        employeesByServiceOptionProvider
            .overrideWith((ref, query) async => employeeChoices),
        customerPackagesProvider
            .overrideWith((ref, customerId) async => backend.packages),
        availableSlotsProvider
            .overrideWith((ref, query) async => effectiveSlots),
        customerUpcomingAppointmentsProvider.overrideWith(
          (ref, customerId) async => backend.upcomingAppointments,
        ),
        customerPastAppointmentsProvider
            .overrideWith((ref, customerId) async => const []),
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
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _completeSelections(WidgetTester tester) async {
  await _tapText(tester, 'Hydrafacial');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();
  await _tapText(tester, 'Cilt Bakımı');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();
  await _tapText(tester, 'Elif Yılmaz');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();
  await _tapTextContaining(tester, '10:00');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
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
  final finder = find.textContaining(text).first;
  if (finder.evaluate().isEmpty) {
    fail('Metin parçası bulunamadı: $text');
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
}

class _FakeGlowBackendService extends GlowBackendService {
  _FakeGlowBackendService({this.createError})
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  final Object? createError;
  int createCount = 0;
  int waitlistCount = 0;

  /// Tracks what a real backend would now return for the customer's upcoming
  /// appointments, so provider overrides reading this list after an
  /// invalidate prove the new booking is visible without a manual refresh.
  final List<Map<String, dynamic>> upcomingAppointments = [];
  final List<Map<String, dynamic>> packages = const [];

  @override
  Future<Map<String, dynamic>> createAppointment(
      Map<String, dynamic> payload) async {
    createCount++;
    if (createError != null) throw createError!;
    final appointment = {
      'appointmentId': 99,
      'customerId': payload['customerId'],
      'employeeId': payload['employeeId'],
      'employeeName': 'Elif Yılmaz',
      'serviceId': payload['serviceId'],
      'serviceName': 'Hydrafacial',
      'optionId': payload['optionId'],
      'optionName': 'Cilt Bakımı',
      'appointmentDate': payload['appointmentDate'],
      'appointmentTime': payload['appointmentTime'],
      'price': '900',
      'status': 'PENDING',
    };
    upcomingAppointments.add(appointment);
    return appointment;
  }

  @override
  Future<Map<String, dynamic>> createWaitingListRecord(
    Map<String, dynamic> payload,
  ) async {
    waitlistCount++;
    return {
      'waitingListId': 7,
      'customerId': payload['customerId'],
      'serviceId': payload['serviceId'],
      'serviceName': 'Hydrafacial',
      'optionId': payload['optionId'],
      'optionName': 'Cilt Bakımı',
      'preferredDate': payload['preferredDate'],
      'preferredStartTime': payload['preferredStartTime'],
      'status': 'ACTIVE',
    };
  }

  @override
  Future<AuthSession?> currentSession() async {
    return const AuthSession(
      token: 'token',
      role: 'CUSTOMER',
      customerId: 12,
      fullName: 'Derya Yılmaz',
    );
  }
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
