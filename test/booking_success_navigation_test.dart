import 'dart:async';

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
import 'package:glowbook_flutter/features/profile/profile_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Covers the booking-UX cleanup: no redundant "Paketinle devam et" modal, no
/// permanently embedded success card, exactly one outcome per submission, and
/// leaving the booking wizard once the backend confirms an appointment.
void main() {
  group('Paket detayından randevu akışına geçiş', () {
    testWidgets(
        'Bu paketle randevu al doğrudan sihirbaza gider, ara onay modalı göstermez',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/packages/2/201',
        routes: [
          GoRoute(
            path: '/packages/:serviceId/:packageId',
            builder: (context, state) => PackageDetailPage(
              serviceId: int.parse(state.pathParameters['serviceId']!),
              packageId: int.parse(state.pathParameters['packageId']!),
            ),
          ),
          GoRoute(
            path: AppRoutes.appointment,
            builder: (context, state) => AppointmentPage(
              packageContext:
                  PackageBookingContext.fromQuery(state.queryParameters),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            glowBackendServiceProvider.overrideWithValue(_SuccessBackend()),
            authControllerProvider.overrideWith(
              (ref) => _ReadyAuthController(_SuccessBackend()),
            ),
            servicesProvider.overrideWith((ref) async => const []),
            servicePackagesProvider.overrideWith(
              (ref, serviceId) async => const [
                {
                  'packageId': 201,
                  'serviceId': 2,
                  'serviceName': 'Lazer Epilasyon',
                  'packageName': '10 Seans Lazer',
                  'totalSession': 10,
                  'price': '1500',
                  'active': true,
                },
              ],
            ),
            // The package detail screen never collects a sub-service, so the
            // wizard's first step (only) still has to ask for the one the
            // package covers — this is the single allowed extra question.
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
            customerUpcomingAppointmentsProvider
                .overrideWith((ref, customerId) async => const []),
            customerPackagesProvider
                .overrideWith((ref, customerId) async => const []),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No leftover confirmation dialog copy anywhere in the tree.
      expect(find.text('Paketinle devam et'), findsNothing);
      expect(
        find.textContaining('Sırada personel, tarih ve saat seçimi var'),
        findsNothing,
      );
      expect(find.text('Vazgeç'), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const Key('package_detail_book')),
        320,
      );
      await tester.tap(find.byKey(const Key('package_detail_book')));
      await tester.pumpAndSettle();

      // One deliberate tap was enough — straight into the wizard, no modal,
      // and the service is not asked again (only the covered sub-service is).
      expect(router.location, startsWith(AppRoutes.appointment));
      expect(find.text('Paket kapsamındaki hizmeti seç'), findsOneWidget);
      expect(find.text('Hizmet seçimi'), findsNothing);
      expect(find.byKey(const Key('package_booking_context')), findsOneWidget);
      expect(find.text('Paketinle devam et'), findsNothing);
    });
  });

  group('Kayıtlı müşteri başarılı randevu sonrası navigasyon', () {
    testWidgets(
        'Randevu oluştur ekranında kalınmaz, Randevularım açılır, randevu görünür',
        (tester) async {
      final backend = _SuccessBackend();
      final router = await _pumpRegisteredBooking(tester, backend: backend);

      await _completeSelections(tester);
      await _tapText(tester, 'Onayla', last: true);
      await tester.pumpAndSettle();
      await _tapText(tester, 'Onayla', last: true);
      await tester.pumpAndSettle();

      expect(backend.createCount, 1);
      expect(router.location, AppRoutes.profile);
      // Not stuck on the wizard, and no permanent embedded success card.
      expect(find.text('Randevu oluştur'), findsNothing);
      expect(find.byType(BookingResultCard), findsNothing);
      // The new appointment is visible without a manual refresh.
      expect(find.text('Yaklaşan Randevular'), findsOneWidget);
      expect(find.text('Hydrafacial'), findsWidgets);
    });

    testWidgets('Geri dönüldüğünde sihirbaz eski başarı durumuyla açılmaz',
        (tester) async {
      final backend = _SuccessBackend();
      final router = await _pumpRegisteredBooking(tester, backend: backend);

      await _completeSelections(tester);
      await _tapText(tester, 'Onayla', last: true);
      await tester.pumpAndSettle();
      await _tapText(tester, 'Onayla', last: true);
      await tester.pumpAndSettle();
      expect(router.location, AppRoutes.profile);

      // Simulate returning to the booking route (e.g. browser/device back).
      router.go(AppRoutes.appointment);
      await tester.pumpAndSettle();

      // A brand new wizard — not the completed one with old selections.
      expect(find.text('Hizmet seçimi'), findsOneWidget);
      expect(find.byType(BookingResultCard), findsNothing);
      expect(find.text('Cilt Bakımı'), findsNothing);
    });
  });

  group('Misafir başarılı randevu sonrası navigasyon', () {
    testWidgets(
        'Misafir için Randevularıma değil, giriş gerektirmeyen bir ekrana yönlendirilir',
        (tester) async {
      final backend = _SuccessBackend();
      final router = await _pumpGuestBooking(tester, backend: backend);

      await _completeSelections(tester, guest: true);
      await _tapText(tester, 'Onayla', last: true);
      await tester.pumpAndSettle();
      await _tapText(tester, 'Onayla', last: true);
      await tester.pumpAndSettle();

      // Concise confirmation shown first.
      expect(find.text('Randevun oluşturuldu'), findsOneWidget);
      expect(find.text('Hydrafacial'), findsWidgets);

      await _tapText(tester, 'Tamam');
      await tester.pumpAndSettle();

      expect(router.location, AppRoutes.home);
      expect(find.text('HOME_ROUTE_MARKER'), findsOneWidget);
      expect(backend.createCount, 1);
    });
  });

  group('Çelişkili durum ve çift gönderim koruması', () {
    testWidgets(
        'Gönderim sırasında Onayla devre dışı kalır, tekrar tıklama ikinci istek göndermez',
        (tester) async {
      final backend = _DelayedBackend();
      await _pumpRegisteredBooking(tester, backend: backend);

      await _completeSelections(tester);
      await _tapText(tester, 'Onayla', last: true);
      await tester.pumpAndSettle();
      await _tapText(tester, 'Onayla', last: true);
      await tester.pump();

      expect(backend.createCount, 1);
      // While submitting, GlowButton swaps its label for a spinner and
      // disables onPressed — the confirm button itself proves the guard.
      final loadingButtonFinder = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(ElevatedButton),
      );
      expect(loadingButtonFinder, findsOneWidget);
      final loadingButton = tester.widget<ElevatedButton>(loadingButtonFinder);
      expect(loadingButton.onPressed, isNull,
          reason: 'Onayla butonu gönderim sırasında devre dışı olmalı');

      // A tap on the disabled button must not be able to fire a second request.
      await tester.tap(loadingButtonFinder, warnIfMissed: false);
      await tester.pump();
      expect(backend.createCount, 1);

      backend.resolve();
      await tester.pumpAndSettle();

      expect(backend.createCount, 1);
    });

    testWidgets('Başarı ve çakışma hatası aynı anda hiçbir zaman gösterilmez',
        (tester) async {
      final backend = _SuccessBackend();
      final router = await _pumpRegisteredBooking(tester, backend: backend);

      await _completeSelections(tester);
      await _tapText(tester, 'Onayla', last: true);
      await tester.pumpAndSettle();
      await _tapText(tester, 'Onayla', last: true);
      await tester.pumpAndSettle();

      // Landed cleanly on Randevularım: no success card and no conflict
      // message coexist anywhere in the tree.
      expect(router.location, AppRoutes.profile);
      expect(find.text('Randevun oluşturuldu'), findsNothing);
      expect(
        find.text('Bu saat artık uygun değil. Lütfen başka bir saat seç.'),
        findsNothing,
      );
    });
  });
}

Future<GoRouter> _pumpRegisteredBooking(
  WidgetTester tester, {
  required GlowBackendService backend,
}) {
  return _pumpBooking(tester, backend: backend, guest: false);
}

Future<GoRouter> _pumpGuestBooking(
  WidgetTester tester, {
  required GlowBackendService backend,
}) {
  return _pumpBooking(tester, backend: backend, guest: true);
}

Future<GoRouter> _pumpBooking(
  WidgetTester tester, {
  required GlowBackendService backend,
  required bool guest,
}) async {
  final slotDay = DateTime.now().add(const Duration(days: 1));
  final slotDate = '${slotDay.year.toString().padLeft(4, '0')}-'
      '${slotDay.month.toString().padLeft(2, '0')}-'
      '${slotDay.day.toString().padLeft(2, '0')}';
  final effectiveSlots = [
    {
      'employeeId': 'EMP-1',
      'employeeName': 'Elif Yılmaz',
      'appointmentDate': slotDate,
      'availableTimes': ['10:00:00'],
    }
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
          (ref) => guest
              ? _GuestAuthController(backend)
              : _ReadyAuthController(backend),
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
        customerPackagesProvider
            .overrideWith((ref, customerId) async => const []),
        availableSlotsProvider
            .overrideWith((ref, query) async => effectiveSlots),
        customerUpcomingAppointmentsProvider.overrideWith(
          (ref, customerId) async => backend is _SuccessBackend
              ? backend.upcomingAppointments
              : const [],
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

Future<void> _completeSelections(
  WidgetTester tester, {
  bool guest = false,
}) async {
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
  await _tapTextContaining(tester, '10:00');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();
  await _tapText(tester, 'Elif Yılmaz');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();

  if (guest) {
    await tester.enterText(find.widgetWithText(TextFormField, 'Ad'), 'Misafir');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Soyad'),
      'Kullanıcı',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Telefon'),
      '05551234567',
    );
    await tester.pumpAndSettle();
  }
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

class _SuccessBackend extends GlowBackendService {
  _SuccessBackend()
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  int createCount = 0;
  final List<Map<String, dynamic>> upcomingAppointments = [];

  @override
  Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> payload,
  ) async {
    createCount++;
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
  Future<AuthSession?> currentSession() async => const AuthSession(
        token: 'token',
        role: 'CUSTOMER',
        customerId: 12,
        fullName: 'Derya Yılmaz',
      );
}

/// Lets a test control exactly when the backend "responds", so it can prove
/// the confirm button is disabled for the entire in-flight window.
class _DelayedBackend extends GlowBackendService {
  _DelayedBackend()
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  int createCount = 0;
  final Completer<void> _gate = Completer<void>();

  void resolve() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> payload,
  ) async {
    createCount++;
    await _gate.future;
    return {
      'appointmentId': 99,
      'employeeId': payload['employeeId'],
      'employeeName': 'Elif Yılmaz',
      'serviceName': 'Hydrafacial',
      'optionName': 'Cilt Bakımı',
      'appointmentDate': payload['appointmentDate'],
      'appointmentTime': payload['appointmentTime'],
      'price': '900',
      'status': 'PENDING',
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

class _GuestAuthController extends AuthController {
  _GuestAuthController(super.backend) {
    state = const AsyncValue.data(null);
  }
}
