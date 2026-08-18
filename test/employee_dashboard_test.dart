import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/appointment/booking_models.dart';
import 'package:glowbook_flutter/features/dashboard/employee_dashboard_page.dart';
import 'package:glowbook_flutter/features/employee/employee_dashboard_models.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

void main() {
  testWidgets('Personel rol guard müşteri erişimini engeller', (tester) async {
    await _pumpDashboard(
      tester,
      backend: _FakeEmployeeBackend(),
      session: const AuthSession(
        token: 'token',
        role: 'CUSTOMER',
        customerId: 12,
      ),
    );

    expect(find.text('Personel yetkisi gerekli'), findsOneWidget);
  });

  testWidgets('Günlük ve haftalık randevu filtreleri gösterilir',
      (tester) async {
    final today = BookingDateUtils.today();
    final otherDay = today.weekday == DateTime.monday
        ? today.add(const Duration(days: 1))
        : today.subtract(Duration(days: today.weekday - 1));
    await _pumpDashboard(
      tester,
      backend: _FakeEmployeeBackend(
        appointments: [
          _appointment(1, today, 'Hydrafacial', 'PENDING'),
          _appointment(2, otherDay, 'Kalıcı Oje', 'APPROVED'),
        ],
      ),
    );

    expect(find.text('Hydrafacial'), findsOneWidget);
    expect(find.text('Kalıcı Oje'), findsNothing);

    await _tapText(tester, 'Haftalık', last: true);
    await tester.pumpAndSettle();

    expect(find.text('Kalıcı Oje'), findsOneWidget);
  });

  testWidgets('Randevu durum güncelleme backend çağrısı yapar', (tester) async {
    final backend = _FakeEmployeeBackend(
      appointments: [
        // Tomorrow, not today — the fixed 10:00 appointment time in
        // _appointment() must stay unambiguously in the future regardless of
        // what time this suite happens to run at (see appointmentIsPastDue).
        _appointment(1, BookingDateUtils.today().add(const Duration(days: 1)),
            'Hydrafacial', 'PENDING'),
      ],
    );
    await _pumpDashboard(tester, backend: backend);
    await _tapText(tester, 'Haftalık', last: true);
    await tester.pumpAndSettle();

    await _tapButton(tester, 'Onayla');
    await tester.pumpAndSettle();

    expect(backend.approveCount, 1);
    expect(find.text('Randevu onaylandı'), findsOneWidget);
  });

  testWidgets('API hata ve yetkisiz erişim güvenli gösterilir', (tester) async {
    await _pumpDashboard(
      tester,
      backend: _FakeEmployeeBackend(
        appointmentsError: Exception('401 unauthorized'),
      ),
    );

    expect(
      find.text('Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap.'),
      findsOneWidget,
    );
  });

  test('Takvim tarih dönüşümleri hafta aralığını normalize eder', () {
    final range = EmployeeWeekRange.from(DateTime(2026, 8, 2));

    expect(range.startText, '2026-07-27');
    expect(range.endText, '2026-08-02');
    expect(range.days, hasLength(7));
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required _FakeEmployeeBackend backend,
  AuthSession session = const AuthSession(
    token: 'token',
    role: 'EMPLOYEE',
    employeeId: 'EMP-1',
    fullName: 'Elif Yılmaz',
  ),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith(
          (ref) => _ReadyAuthController(backend, session),
        ),
        workingHoursProvider.overrideWith(
          (ref) async => const [
            {
              'dayOfWeek': 'MONDAY',
              'startTime': '09:00:00',
              'endTime': '18:00:00',
              'active': true,
            },
          ],
        ),
      ],
      child: MaterialApp(
          theme: AppTheme.lightTheme, home: const EmployeeDashboardPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _appointment(
  int id,
  DateTime date,
  String serviceName,
  String status,
) {
  return {
    'appointmentId': id,
    'employeeId': 'EMP-1',
    'serviceName': serviceName,
    'optionName': 'Bakım',
    'customerName': 'Derya',
    'customerSurname': 'Yılmaz',
    'phone': '5551112233',
    'appointmentDate': BookingDateUtils.formatDate(date),
    'appointmentTime': '10:00:00',
    'status': status,
  };
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

Future<void> _tapButton(WidgetTester tester, String text) async {
  final finder = find.ancestor(
    of: find.text(text),
    matching: find.byType(ElevatedButton),
  );
  if (finder.evaluate().isEmpty) {
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .join(' | ');
    fail('Buton bulunamadı: $text. Ekrandaki metinler: $texts');
  }
  await tester.ensureVisible(finder.first);
  await tester.pump();
  final visibleFinder = finder.hitTestable();
  await tester.tap(
    visibleFinder.evaluate().isEmpty ? finder.first : visibleFinder.first,
    warnIfMissed: false,
  );
}

class _FakeEmployeeBackend extends GlowBackendService {
  _FakeEmployeeBackend({
    List<Map<String, dynamic>>? appointments,
    this.appointmentsError,
  })  : appointments = appointments ?? const [],
        super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  final List<Map<String, dynamic>> appointments;
  final Object? appointmentsError;
  int approveCount = 0;

  @override
  Future<List<Map<String, dynamic>>> getEmployeeAppointments({
    required String employeeId,
    required String startDate,
    required String endDate,
  }) async {
    if (appointmentsError != null) throw appointmentsError!;
    return appointments;
  }

  @override
  Future<Map<String, dynamic>> approveAppointment(int appointmentId) async {
    approveCount++;
    return {
      'appointmentId': appointmentId,
      'status': 'APPROVED',
    };
  }

  @override
  Future<Map<String, dynamic>> completeAppointment(int appointmentId) async {
    return {
      'appointmentId': appointmentId,
      'status': 'COMPLETED',
    };
  }
}

class _ReadyAuthController extends AuthController {
  _ReadyAuthController(super.backend, AuthSession? session) {
    state = AsyncValue.data(session);
  }
}
