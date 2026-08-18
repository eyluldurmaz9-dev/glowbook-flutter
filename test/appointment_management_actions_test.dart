import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/profile/profile_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Covers the restored appointment-management actions on Randevularım:
/// Düzenle/İptal Et exist for an upcoming appointment (never a past one),
/// cancellation asks for confirmation before calling the backend, and
/// editing opens the reschedule sheet which calls the reschedule endpoint.
void main() {
  const upcoming = {
    'appointmentId': 1,
    'serviceId': 1,
    'optionId': 11,
    'serviceName': 'Hydrafacial',
    'optionName': 'Cilt Bakımı',
    'employeeId': 'EMP-1',
    'employeeName': 'Elif Yılmaz',
    'appointmentDate': '2026-09-01',
    'appointmentTime': '10:00:00',
    'status': 'PENDING',
    'price': '900',
  };
  const past = {
    'appointmentId': 2,
    'serviceId': 1,
    'optionId': 11,
    'serviceName': 'Kalıcı Oje',
    'optionName': 'Manikür',
    'employeeId': 'EMP-1',
    'employeeName': 'Elif Yılmaz',
    'appointmentDate': '2026-07-01',
    'appointmentTime': '12:00:00',
    'status': 'COMPLETED',
    'price': '500',
  };

  Future<_FakeBackend> pumpProfile(WidgetTester tester) async {
    final backend = _FakeBackend();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glowBackendServiceProvider.overrideWithValue(backend),
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
              .overrideWith((ref, id) async => const [upcoming]),
          customerPastAppointmentsProvider
              .overrideWith((ref, id) async => const [past]),
          employeesByServiceOptionProvider.overrideWith((ref, q) async => const [
                {'employeeId': 'EMP-1', 'employeeName': 'Elif Yılmaz'},
              ]),
          availableSlotsProvider.overrideWith((ref, q) async => [
                {
                  'employeeId': 'EMP-1',
                  'employeeName': 'Elif Yılmaz',
                  'appointmentDate': q.date,
                  'availableTimes': ['11:00:00'],
                },
              ]),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return backend;
  }

  testWidgets('Yaklaşan randevuda Düzenle ve İptal Et gösterilir, geçmişte gösterilmez',
      (tester) async {
    await pumpProfile(tester);

    expect(find.byKey(const Key('edit_appointment_1')), findsOneWidget);
    expect(find.byKey(const Key('cancel_appointment_1')), findsOneWidget);
    expect(find.byKey(const Key('edit_appointment_2')), findsNothing);
    expect(find.byKey(const Key('cancel_appointment_2')), findsNothing);
  });

  testWidgets('İptal Et onay ister ve onaylanınca backend çağrısı yapar',
      (tester) async {
    final backend = await pumpProfile(tester);

    await tester.ensureVisible(find.byKey(const Key('cancel_appointment_1')));
    await tester.tap(find.byKey(const Key('cancel_appointment_1')));
    await tester.pumpAndSettle();

    expect(
      find.text('Randevunu iptal etmek istediğine emin misin?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Randevuyu İptal Et'));
    await tester.pumpAndSettle();

    expect(backend.cancelCount, 1);
    expect(find.text('Randevu iptal edildi.'), findsOneWidget);
  });

  testWidgets('Vazgeç iptali durdurur, backend çağrılmaz', (tester) async {
    final backend = await pumpProfile(tester);

    await tester.ensureVisible(find.byKey(const Key('cancel_appointment_1')));
    await tester.tap(find.byKey(const Key('cancel_appointment_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    expect(backend.cancelCount, 0);
  });

  testWidgets('Düzenle sayfası açılır ve saat seçilip kaydedince reschedule çağrısı yapar',
      (tester) async {
    final backend = await pumpProfile(tester);

    await tester.ensureVisible(find.byKey(const Key('edit_appointment_1')));
    await tester.tap(find.byKey(const Key('edit_appointment_1')));
    await tester.pumpAndSettle();

    expect(find.text('Randevuyu Düzenle'), findsOneWidget);
    expect(find.byKey(const Key('edit_employee_EMP-1')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('edit_time_11:00')));
    await tester.tap(find.byKey(const Key('edit_time_11:00')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('edit_confirm')));
    await tester.tap(find.byKey(const Key('edit_confirm')));
    await tester.pumpAndSettle();

    expect(backend.rescheduleCount, 1);
    expect(backend.lastReschedulePayload?['appointmentTime'], '11:00');
    expect(find.text('Randevu güncellendi.'), findsOneWidget);
  });
}

class _FakeBackend extends GlowBackendService {
  _FakeBackend()
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  int cancelCount = 0;
  int rescheduleCount = 0;
  Map<String, dynamic>? lastReschedulePayload;

  @override
  Future<Map<String, dynamic>> cancelAppointment(
    int appointmentId, {
    String? cancellationReason,
  }) async {
    cancelCount++;
    return {'appointmentId': appointmentId, 'status': 'CANCELLED'};
  }

  @override
  Future<Map<String, dynamic>> rescheduleAppointment(
    int appointmentId,
    Map<String, dynamic> payload,
  ) async {
    rescheduleCount++;
    lastReschedulePayload = payload;
    return {'appointmentId': appointmentId, 'status': 'PENDING', ...payload};
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
