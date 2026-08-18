import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/widgets/glow_widgets.dart';
import 'package:glowbook_flutter/features/appointment/appointment_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Regression coverage for the calendar month-navigation defect: reaching the
/// booking wizard's Tarih step after scrolling through an earlier, longer
/// step used to leave the calendar's month header scrolled above the
/// viewport, so its "next month" arrow existed in the tree but could not
/// actually be tapped — August → September silently did nothing.
void main() {
  // Flutter's CalendarDatePicker clears the tooltip (sets it to null) on the
  // button for a disabled boundary month, so matching by icon shape — not
  // tooltip text — is what reliably finds the button in both its enabled and
  // its intentionally-disabled state.
  Finder nextMonthButton() => find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.chevron_right,
      );
  Finder previousMonthButton() => find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.chevron_left,
      );
  Finder dayCell(String day) => find.descendant(
        of: find.byType(CalendarDatePicker),
        matching: find.text(day),
      );

  group('Sihirbaz içindeki takvim (gerçek uçtan uca senaryo)', () {
    testWidgets(
        'Uzun bir adımdan sonra takvime gelindiğinde ay başlığı ekstra kaydırma olmadan görünür ve çalışır',
        (tester) async {
      await _pumpToDateStep(tester);

      // The exact defect: without any manual scroll/ensureVisible, the
      // button must already be on-screen and hittable.
      final button = nextMonthButton();
      expect(button, findsOneWidget);
      final center = tester.getCenter(button);
      final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(center.dy, greaterThanOrEqualTo(0));
      expect(center.dy, lessThanOrEqualTo(viewport.height));

      final currentMonthLabel = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .firstWhere((text) => text.contains('2026') || text.contains('2027'));

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text(currentMonthLabel), findsNothing);
    });

    testWidgets('Ağustos → Eylül gezinmesi çalışır', (tester) async {
      await _pumpToDateStep(tester);
      expect(find.text('August 2026'), findsOneWidget);

      await tester.tap(nextMonthButton());
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('August 2026'), findsNothing);
    });

    testWidgets('Eylül → Ekim gezinmesi çalışır', (tester) async {
      await _pumpToDateStep(tester);
      await tester.tap(nextMonthButton());
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      await tester.tap(nextMonthButton());
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
    });

    testWidgets('Eylül ayında bir tarihe tıklamak o tarihi gerçekten seçer',
        (tester) async {
      await _pumpToDateStep(tester);
      await tester.tap(nextMonthButton());
      await tester.pumpAndSettle();
      expect(find.text('September 2026'), findsOneWidget);

      // Day 20 sits in a lower grid row that may extend past the current
      // scroll position — a normal need for scrollable content, distinct
      // from the header-visibility defect this file otherwise regresses.
      await tester.ensureVisible(dayCell('20'));
      await tester.tap(dayCell('20'));
      await tester.pumpAndSettle();

      expect(find.text('2026-09-20'), findsOneWidget);
    });

    testWidgets(
        'Eylül tarihi seçilip devam edildiğinde o tarih için uygunluk yüklenir',
        (tester) async {
      await _pumpToDateStep(tester, availableTimesForSeptember: ['11:00:00']);
      await tester.tap(nextMonthButton());
      await tester.pumpAndSettle();
      await tester.ensureVisible(dayCell('20'));
      await tester.tap(dayCell('20'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Devam').last);
      await tester.tap(find.text('Devam').last);
      await tester.pumpAndSettle();

      expect(find.text('Uygun zaman aralığı'), findsOneWidget);
      expect(find.textContaining('11:00'), findsOneWidget);
    });

    testWidgets('Geçmiş tarihler gezinme sonrasında da seçilemez kalır',
        (tester) async {
      await _pumpToDateStep(tester);

      // The very first month is already the earliest allowed one — going
      // backward from it must stay disabled, proving past months/dates are
      // still unreachable after the navigation fix.
      expect(previousMonthButton(), findsOneWidget);
      final disabledPrevious =
          tester.widget<IconButton>(previousMonthButton());
      expect(disabledPrevious.onPressed, isNull);
    });
  });

  group('Ay/yıl sınırı gezinmesi (izole CalendarDatePicker, deterministik)',
      () {
    // Isolated with an explicit wide range so year-boundary navigation is
    // deterministic regardless of the real wall-clock date, while exercising
    // the exact widget/config pattern the booking wizard uses.
    Future<void> pumpWideCalendar(
      WidgetTester tester, {
      required DateTime initial,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: GlowCard(
                  padding: const EdgeInsets.all(8),
                  child: CalendarDatePicker(
                    initialDate: initial,
                    firstDate: DateTime(2026, 8, 1),
                    lastDate: DateTime(2027, 3, 1),
                    currentDate: DateTime(2026, 8, 14),
                    onDateChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Aralık → Ocak (yıl değişimi) çalışır', (tester) async {
      await pumpWideCalendar(tester, initial: DateTime(2026, 12, 1));
      expect(find.text('December 2026'), findsOneWidget);

      await tester.tap(nextMonthButton());
      await tester.pumpAndSettle();

      expect(find.text('January 2027'), findsOneWidget);
    });

    testWidgets('Ocak → Aralık (önceki yıla dönüş) izin verilen aralıkta çalışır',
        (tester) async {
      await pumpWideCalendar(tester, initial: DateTime(2027, 1, 1));
      expect(find.text('January 2027'), findsOneWidget);

      await tester.tap(previousMonthButton());
      await tester.pumpAndSettle();

      expect(find.text('December 2026'), findsOneWidget);
    });

    testWidgets('İzin verilen aralığın öncesine geçilemez', (tester) async {
      await pumpWideCalendar(tester, initial: DateTime(2026, 8, 1));
      expect(find.text('August 2026'), findsOneWidget);

      final disabledPrevious =
          tester.widget<IconButton>(previousMonthButton());
      expect(disabledPrevious.onPressed, isNull);

      await tester.tap(previousMonthButton(), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('August 2026'), findsOneWidget);
    });
  });
}

Future<void> _pumpToDateStep(
  WidgetTester tester, {
  List<String>? availableTimesForSeptember,
}) async {
  final backend = _Backend();
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final tomorrowText = '${tomorrow.year.toString().padLeft(4, '0')}-'
      '${tomorrow.month.toString().padLeft(2, '0')}-'
      '${tomorrow.day.toString().padLeft(2, '0')}';

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith((ref) => _Auth(backend)),
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
        // A long, scrollable package list stands in for whatever earlier
        // step originally left the wizard's shared scroll offset well past
        // the top — this is what previously stranded the calendar header.
        servicePackagesProvider.overrideWith(
          (ref, serviceId) async => List.generate(
            10,
            (index) => {
              'packageId': 100 + index,
              'serviceId': 1,
              'serviceName': 'Hydrafacial',
              'packageName': 'Paket ${index + 1}',
              'totalSession': 5,
              'price': '1200',
              'active': true,
            },
          ),
        ),
        customerPackagesProvider.overrideWith((ref, customerId) async => const []),
        employeesByServiceOptionProvider.overrideWith(
          (ref, query) async => const [
            {'employeeId': 'EMP-1', 'employeeName': 'Elif Yılmaz'},
          ],
        ),
        availableSlotsProvider.overrideWith((ref, query) async {
          if (availableTimesForSeptember != null &&
              query.date.startsWith('2026-09')) {
            return [
              {
                'employeeId': 'EMP-1',
                'employeeName': 'Elif Yılmaz',
                'appointmentDate': query.date,
                'availableTimes': availableTimesForSeptember,
              },
            ];
          }
          return const [];
        }),
        customerUpcomingAppointmentsProvider
            .overrideWith((ref, customerId) async => const []),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppointmentPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Hydrafacial'));
  await tester.tap(find.text('Hydrafacial'), warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Devam').last);
  await tester.tap(find.text('Devam').last, warnIfMissed: false);
  await tester.pumpAndSettle();

  // Select the sub-service, then scroll deep into the long package list
  // before continuing — reproducing the scroll offset the real defect
  // depended on.
  await tester.ensureVisible(find.text('Cilt Bakımı'));
  await tester.tap(find.text('Cilt Bakımı'), warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Paket 10'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Devam').last);
  await tester.tap(find.text('Devam').last, warnIfMissed: false);
  await tester.pumpAndSettle();

  // Personel now comes before Tarih — pick "İlk Müsait Zaman" to reach the
  // calendar step this file actually regresses.
  expect(find.text('Personel seçimi'), findsOneWidget);
  await tester.ensureVisible(find.text('İlk Müsait Zaman'));
  await tester.tap(find.text('İlk Müsait Zaman'), warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Devam').last);
  await tester.tap(find.text('Devam').last, warnIfMissed: false);
  await tester.pumpAndSettle();

  expect(find.text('Tarih seçimi'), findsOneWidget);
  expect(find.text(tomorrowText), findsWidgets);
}

class _Backend extends GlowBackendService {
  _Backend()
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  @override
  Future<AuthSession?> currentSession() async => const AuthSession(
        token: 'token',
        role: 'CUSTOMER',
        customerId: 12,
        fullName: 'Derya Yılmaz',
      );
}

class _Auth extends AuthController {
  _Auth(super.backend) {
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
