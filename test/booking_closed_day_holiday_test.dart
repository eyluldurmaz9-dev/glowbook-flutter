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
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Regression coverage for the reported bug: selecting a closed weekday (or
/// a holiday date) in the booking wizard's Tarih step must never let the
/// customer proceed as if it were bookable. The wizard supports selecting
/// several dates at once ("Birden fazla tarih seçebilirsin") and always
/// starts with tomorrow pre-selected, so without a selection-time filter a
/// closed/holiday date silently rides along with whatever open date is
/// already selected — its own slots are correctly empty, but the *other*
/// date's real slots still show up in the merged Uygun Zaman list. This
/// tests the actual predicate the real Calendar/date-picker widgets use
/// (CalendarDatePicker.selectableDayPredicate), reached through the real
/// AppointmentPage widget tree, not a bypassed unit test.
void main() {
  const weekdayNames = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  testWidgets(
      'Takvim, kapalı haftalık günü ve tatil tarihini seçilemez işaretler',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Pick a closed weekday and a holiday date that are both clear of
    // tomorrow (the wizard's default pre-selected date), so the fixture
    // doesn't depend on which day "today" happens to fall on.
    var closedDate = today.add(const Duration(days: 3));
    while (closedDate.weekday == tomorrow.weekday) {
      closedDate = closedDate.add(const Duration(days: 1));
    }
    final closedWeekday = weekdayNames[closedDate.weekday - 1];

    var holidayDate = today.add(const Duration(days: 10));
    while (holidayDate.weekday == tomorrow.weekday ||
        weekdayNames[holidayDate.weekday - 1] == closedWeekday) {
      holidayDate = holidayDate.add(const Duration(days: 1));
    }
    String iso(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final backend = _FakeGlowBackendService();
    final router = GoRouter(
      initialLocation: AppRoutes.appointment,
      routes: [
        GoRoute(
          path: AppRoutes.appointment,
          builder: (context, state) => const AppointmentPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glowBackendServiceProvider.overrideWithValue(backend),
          authControllerProvider.overrideWith((ref) => _ReadyAuthController(backend)),
          servicesProvider.overrideWith((ref) async => const [
                {
                  'serviceId': 1,
                  'serviceName': 'Hydrafacial',
                  'description': 'Bakım',
                },
              ]),
          serviceOptionsProvider.overrideWith((ref, serviceId) async => const [
                {
                  'optionId': 11,
                  'serviceId': 1,
                  'optionName': 'Cilt Bakımı',
                  'price': '900',
                },
              ]),
          servicePackagesProvider.overrideWith((ref, serviceId) async => const []),
          employeesByServiceOptionProvider.overrideWith((ref, query) async => const [
                {'employeeId': 'EMP-1', 'employeeName': 'Elif Yılmaz'},
              ]),
          customerPackagesProvider.overrideWith((ref, customerId) async => const []),
          customerUpcomingAppointmentsProvider
              .overrideWith((ref, customerId) async => const []),
          customerPastAppointmentsProvider
              .overrideWith((ref, customerId) async => const []),
          profileProvider.overrideWith((ref) async => const {
                'customerId': 12,
                'firstName': 'Derya',
                'lastName': 'Yılmaz',
                'phone': '05551110000',
                'email': 'derya@glowbook.test',
              }),
          availableSlotsProvider.overrideWith((ref, query) async => const []),
          workingHoursProvider.overrideWith((ref) async => [
                {
                  'workingHourId': 1,
                  'dayOfWeek': closedWeekday,
                  'startTime': '10:00:00',
                  'endTime': '19:00:00',
                  'closed': true,
                },
              ]),
          holidaysProvider.overrideWith((ref, query) async => [
                {
                  'holidayId': 1,
                  'holidayDate': iso(holidayDate),
                  'holidayName': 'Test Tatili',
                },
              ]),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

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

    // Now on the Tarih step.
    final calendar = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    final isSelectable = calendar.selectableDayPredicate!;

    expect(isSelectable(closedDate), isFalse,
        reason: '$closedWeekday kapalı, bu tarih seçilebilir olmamalı');
    expect(isSelectable(holidayDate), isFalse,
        reason: 'Tatil tarihi seçilebilir olmamalı');
    expect(isSelectable(tomorrow), isTrue,
        reason: 'Varsayılan (açık) tarih seçilebilir kalmalı');
  });
}

Future<void> _tapText(WidgetTester tester, String text, {bool last = false}) async {
  final matches = find.text(text);
  final finder = last ? matches.last : matches.first;
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
}

class _FakeGlowBackendService extends GlowBackendService {
  _FakeGlowBackendService()
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
