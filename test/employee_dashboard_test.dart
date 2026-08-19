import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/widgets/glow_widgets.dart';
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

  testWidgets(
      'Personel panelinde public-home "Ana Sayfaya Dön" kontrolü yoktur',
      (tester) async {
    await _pumpDashboard(tester, backend: _FakeEmployeeBackend());

    expect(find.byKey(const Key('services_public_home')), findsNothing);
    expect(find.byKey(const Key('packages_public_home')), findsNothing);
    expect(find.byKey(const Key('booking_public_home')), findsNothing);
    expect(
        find.byKey(const Key('guest_access_public_home')), findsNothing);
    expect(find.text('Ana Sayfaya Dön'), findsNothing);
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

  testWidgets(
      'Çalışma Saatleri: 7 gün görünür, kapalı gün Kapalı, açık gün gerçek saatiyle Aktif',
      (tester) async {
    const workingHours = [
      {
        'workingHourId': 1,
        'dayOfWeek': 'MONDAY',
        'startTime': '10:00:00',
        'endTime': '19:00:00',
        'closed': false,
      },
      {
        'workingHourId': 2,
        'dayOfWeek': 'TUESDAY',
        'startTime': '10:00:00',
        'endTime': '19:00:00',
        'closed': true,
      },
      {
        'workingHourId': 3,
        'dayOfWeek': 'WEDNESDAY',
        'startTime': '11:00:00',
        'endTime': '18:00:00',
        'closed': false,
      },
      {
        'workingHourId': 4,
        'dayOfWeek': 'THURSDAY',
        'startTime': '10:00:00',
        'endTime': '19:00:00',
        'closed': false,
      },
      {
        'workingHourId': 5,
        'dayOfWeek': 'FRIDAY',
        'startTime': '09:30:00',
        'endTime': '17:30:00',
        'closed': false,
      },
      {
        'workingHourId': 6,
        'dayOfWeek': 'SATURDAY',
        'startTime': '10:00:00',
        'endTime': '18:00:00',
        'closed': false,
      },
      {
        'workingHourId': 7,
        'dayOfWeek': 'SUNDAY',
        'startTime': '12:00:00',
        'endTime': '17:00:00',
        'closed': false,
      },
    ];
    await _pumpDashboard(
      tester,
      backend: _FakeEmployeeBackend(),
      workingHours: workingHours,
    );

    await _tapText(tester, 'Çalışma Saatleri', last: true);
    await tester.pumpAndSettle();

    // TEST 5/12: all 7 days present and reachable by scrolling the panel's
    // own list — the ListView only builds what's near the viewport, so
    // each day is checked as it's scrolled into view rather than assumed
    // to already be built, matching how a user actually reaches Sunday.
    final panelList = find.byType(ListView).last;
    Finder cardFor(String day) {
      final finder = find.text(day);
      return find.ancestor(of: finder, matching: find.byType(GlowCard));
    }

    Future<void> scrollTo(String day) => tester.dragUntilVisible(
          find.text(day),
          panelList,
          const Offset(0, -80),
        );

    for (final day in workingHours) {
      await scrollTo(day['dayOfWeek'] as String);
      expect(find.text(day['dayOfWeek'] as String), findsOneWidget,
          reason: '${day['dayOfWeek']} listede görünmüyor');
    }

    // TEST 6: TUESDAY is closed — must read "Kapalı", never its stored hours
    // rendered as if the day were open.
    await scrollTo('TUESDAY');
    final tuesdayCard = cardFor('TUESDAY');
    expect(find.descendant(of: tuesdayCard, matching: find.text('Kapalı')),
        findsNWidgets(2)); // subtitle + trailing both say "Kapalı"
    expect(
        find.descendant(
            of: tuesdayCard, matching: find.textContaining('10:00')),
        findsNothing,
        reason: 'Kapalı günün eski saatleri açıkmış gibi gösterilmemeli');

    // TEST 7/9: WEDNESDAY and FRIDAY each show their own real, different
    // hours — not a shared hardcoded value.
    await scrollTo('WEDNESDAY');
    final wednesdayCard = cardFor('WEDNESDAY');
    expect(
        find.descendant(
            of: wednesdayCard, matching: find.text('11:00:00 - 18:00:00')),
        findsOneWidget);
    expect(
        find.descendant(of: wednesdayCard, matching: find.text('Aktif')),
        findsOneWidget);

    await scrollTo('FRIDAY');
    final fridayCard = cardFor('FRIDAY');
    expect(
        find.descendant(
            of: fridayCard, matching: find.text('09:30:00 - 17:30:00')),
        findsOneWidget);

    // TEST 8: SUNDAY reachable (via the panel's own scroll) with its own
    // distinct hours, not missing/clipped and not defaulted to Monday's.
    await scrollTo('SUNDAY');
    final sundayCard = cardFor('SUNDAY');
    expect(
        find.descendant(
            of: sundayCard, matching: find.text('12:00:00 - 17:00:00')),
        findsOneWidget);
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
  List<Map<String, dynamic>>? workingHours,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith(
          (ref) => _ReadyAuthController(backend, session),
        ),
        // The real WorkingHourResponse field is `closed`, not `active` —
        // this fixture must match the real backend contract, or a bug in
        // the panel that only ever exercised a wrong-but-matching field
        // name (like the one this file's own dynamic-hours test guards
        // against) would silently pass.
        workingHoursProvider.overrideWith(
          (ref) async =>
              workingHours ??
              const [
                {
                  'dayOfWeek': 'MONDAY',
                  'startTime': '09:00:00',
                  'endTime': '18:00:00',
                  'closed': false,
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
