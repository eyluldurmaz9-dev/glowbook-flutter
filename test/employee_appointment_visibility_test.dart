import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/appointment/booking_models.dart';
import 'package:glowbook_flutter/features/dashboard/employee_dashboard_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// The booked employee must find the customer's appointment in the weekly
/// schedule, and only their own — the backend scopes the query by employee id.
void main() {
  testWidgets('Atanan randevu haftalık takvimde görünür', (tester) async {
    final date = _nextWorkingDay();
    final backend = _FakeEmployeeBackend(
      appointments: [_appointment(77, date, 'EMP-2', 'Cilt Bakımı')],
    );
    await _pumpEmployeeDashboard(tester, backend: backend);

    await _openWeekly(tester);

    expect(find.text('Cilt Bakımı'), findsOneWidget);
    expect(find.textContaining('Derya Yılmaz'), findsWidgets);
    expect(find.textContaining('14:00'), findsWidgets);
    expect(backend.requestedEmployeeIds, contains('EMP-2'));
  });

  testWidgets('Haftalık takvim hizmet, müşteri, saat ve durumu gösterir',
      (tester) async {
    final date = _nextWorkingDay();
    await _pumpEmployeeDashboard(
      tester,
      backend: _FakeEmployeeBackend(
        appointments: [_appointment(77, date, 'EMP-2', 'Cilt Bakımı')],
      ),
    );

    await _openWeekly(tester);

    expect(find.text('Cilt Bakımı'), findsOneWidget);
    expect(find.textContaining('Derya Yılmaz • Hydrafacial'), findsOneWidget);
    expect(find.textContaining(BookingDateUtils.formatDate(date)), findsWidgets);
    expect(find.text('Onay bekliyor'), findsWidgets);
  });

  testWidgets('Başka personelin randevusu bu personelde görünmez',
      (tester) async {
    final date = _nextWorkingDay();
    // The backend only ever returns the signed-in employee's rows.
    final backend = _FakeEmployeeBackend(
      appointments: [_appointment(77, date, 'EMP-2', 'Cilt Bakımı')],
      foreignAppointments: [_appointment(88, date, 'EMP-9', 'Lazer Epilasyon')],
    );
    await _pumpEmployeeDashboard(tester, backend: backend);

    await _openWeekly(tester);

    expect(find.text('Cilt Bakımı'), findsOneWidget);
    expect(find.text('Lazer Epilasyon'), findsNothing);
    expect(backend.requestedEmployeeIds, ['EMP-2']);
  });

  testWidgets('Misafir randevusu da personel takviminde listelenir',
      (tester) async {
    final date = _nextWorkingDay();
    final guest = _appointment(90, date, 'EMP-2', 'Masaj ve Spa')
      ..['customerId'] = null
      ..['customerName'] = 'Misafir'
      ..['customerSurname'] = 'Kullanıcı';
    await _pumpEmployeeDashboard(
      tester,
      backend: _FakeEmployeeBackend(appointments: [guest]),
    );

    await _openWeekly(tester);

    expect(find.text('Masaj ve Spa'), findsOneWidget);
    expect(find.textContaining('Misafir Kullanıcı'), findsOneWidget);
  });

  testWidgets('Personel takviminde teknik terim gösterilmez', (tester) async {
    final date = _nextWorkingDay();
    await _pumpEmployeeDashboard(
      tester,
      backend: _FakeEmployeeBackend(
        appointments: [_appointment(77, date, 'EMP-2', 'Cilt Bakımı')],
      ),
    );

    await _openWeekly(tester);

    final visible = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .join(' ')
        .toLowerCase();
    for (final banned in ['backend', 'endpoint', 'http', 'json', 'dto', 'utc']) {
      expect(visible.contains(banned), isFalse, reason: 'sızan terim: $banned');
    }
  });
}

Future<void> _openWeekly(WidgetTester tester) async {
  final tab = find.text('Haftalık');
  await tester.ensureVisible(tab.last);
  await tester.tap(tab.last, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// A date inside the current week that the salon is open on, guaranteed to
/// be in the future so the fixed 14:00 appointment time these fixtures use
/// is never accidentally treated as already past (see appointmentIsPastDue,
/// which — correctly — would otherwise show these as "Tamamlandı" once the
/// wall clock passes 14:00 on the day the suite happens to run).
DateTime _nextWorkingDay() {
  var candidate = BookingDateUtils.today().add(const Duration(days: 1));
  if (candidate.weekday == DateTime.sunday) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

Map<String, dynamic> _appointment(
  int id,
  DateTime date,
  String employeeId,
  String serviceName,
) {
  return <String, dynamic>{
    'appointmentId': id,
    'employeeId': employeeId,
    'employeeName': 'Eylem Ceylan',
    'serviceName': serviceName,
    'optionName': 'Hydrafacial',
    'customerId': 12,
    'customerName': 'Derya',
    'customerSurname': 'Yılmaz',
    'phone': '+905551112233',
    'appointmentDate': BookingDateUtils.formatDate(date),
    'appointmentTime': '14:00:00',
    'status': 'PENDING',
  };
}

Future<void> _pumpEmployeeDashboard(
  WidgetTester tester, {
  required _FakeEmployeeBackend backend,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith(
          (ref) => _ReadyAuthController(
            backend,
            const AuthSession(
              token: 'token',
              role: 'EMPLOYEE',
              employeeId: 'EMP-2',
              fullName: 'Eylem Ceylan',
            ),
          ),
        ),
        workingHoursProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const EmployeeDashboardPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeEmployeeBackend extends GlowBackendService {
  _FakeEmployeeBackend({
    List<Map<String, dynamic>>? appointments,
    List<Map<String, dynamic>>? foreignAppointments,
  })  : appointments = appointments ?? const [],
        foreignAppointments = foreignAppointments ?? const [],
        super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> foreignAppointments;
  final List<String> requestedEmployeeIds = [];

  @override
  Future<List<Map<String, dynamic>>> getEmployeeAppointments({
    required String employeeId,
    required String startDate,
    required String endDate,
  }) async {
    requestedEmployeeIds.add(employeeId);
    return [...appointments, ...foreignAppointments]
        .where((item) => item['employeeId'] == employeeId)
        .toList(growable: false);
  }
}

class _ReadyAuthController extends AuthController {
  _ReadyAuthController(super.backend, AuthSession session) {
    state = AsyncValue.data(session);
  }
}
