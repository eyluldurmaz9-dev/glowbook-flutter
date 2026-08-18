import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/widgets/glow_widgets.dart';
import 'package:glowbook_flutter/features/appointment/booking_models.dart';
import 'package:glowbook_flutter/features/dashboard/admin_dashboard_page.dart';
import 'package:glowbook_flutter/features/dashboard/employee_dashboard_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Regression coverage: a PENDING/APPROVED appointment whose date/time has
/// passed and was never cancelled must display as "Tamamlandı" (and stop
/// offering Onayla/Tamamla) on both the employee's own weekly view and
/// admin's Randevu Yönetimi — this is a display-only derivation
/// (appointmentIsPastDue), the backend's persisted status and package
/// session accounting are untouched. A CANCELLED appointment must never be
/// reclassified this way, no matter how far in the past it is.
void main() {
  // The employee weekly view only renders appointments that fall within the
  // currently displayed (real, wall-clock) week, so "past"/"future" here are
  // expressed as a time-of-day offset on today's date rather than a fixed
  // calendar date — that keeps every fixture inside the visible week while
  // still being unambiguously before/after whatever moment the suite runs.
  final today = BookingDateUtils.formatDate(BookingDateUtils.today());

  Map<String, dynamic> appointment(
    int id,
    String status, {
    required String time,
    String serviceName = 'Cilt Bakımı',
  }) {
    return {
      'appointmentId': id,
      'employeeId': 'EMP-1',
      'employeeName': 'Elif Yılmaz',
      'serviceName': serviceName,
      'optionName': 'Hydrafacial',
      'customerName': 'Derya',
      'customerSurname': 'Yılmaz',
      'phone': '5551112233',
      'appointmentDate': today,
      'appointmentTime': time,
      'status': status,
    };
  }

  group('Employee haftalık görünüm', () {
    Future<void> pumpEmployee(
      WidgetTester tester,
      List<Map<String, dynamic>> appointments,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            glowBackendServiceProvider.overrideWithValue(_FakeBackend()),
            authControllerProvider.overrideWith(
              (ref) => _ReadyAuthController(const AuthSession(
                token: 'token',
                role: 'EMPLOYEE',
                employeeId: 'EMP-1',
                fullName: 'Elif Yılmaz',
              )),
            ),
            employeeAppointmentsProvider
                .overrideWith((ref, query) async => appointments),
            workingHoursProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const EmployeeDashboardPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tab = find.text('Haftalık');
      await tester.ensureVisible(tab.last);
      await tester.tap(tab.last, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('Geçmiş, iptal edilmemiş PENDING randevu Tamamlandı gösterir',
        (tester) async {
      await pumpEmployee(tester, [appointment(1, 'PENDING', time: '00:01:00')]);

      expect(find.text('Tamamlandı'), findsOneWidget);
      expect(find.text('Onay bekliyor'), findsNothing);
      expect(find.widgetWithText(GlowButton, 'Onayla'), findsNothing);
    });

    testWidgets('Geçmiş, iptal edilmemiş APPROVED randevu Tamamlandı gösterir',
        (tester) async {
      await pumpEmployee(tester, [appointment(2, 'APPROVED', time: '00:01:00')]);

      expect(find.text('Tamamlandı'), findsOneWidget);
      expect(find.text('Onaylandı'), findsNothing);
      expect(find.widgetWithText(GlowButton, 'Tamamlandı'), findsNothing);
    });

    testWidgets('Gelecekteki PENDING randevu Onay bekliyor olarak kalır',
        (tester) async {
      await pumpEmployee(tester, [appointment(3, 'PENDING', time: '23:55:00')]);

      expect(find.text('Onay bekliyor'), findsOneWidget);
      expect(find.widgetWithText(GlowButton, 'Onayla'), findsOneWidget);
    });

    testWidgets('Geçmişte olsa bile CANCELLED randevu İptal edildi kalır',
        (tester) async {
      await pumpEmployee(tester, [appointment(4, 'CANCELLED', time: '00:01:00')]);

      expect(find.text('İptal edildi'), findsOneWidget);
      expect(find.text('Tamamlandı'), findsNothing);
    });
  });

  group('Admin Randevu Yönetimi', () {
    Future<void> pumpAdmin(
      WidgetTester tester,
      List<Map<String, dynamic>> appointments,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            glowBackendServiceProvider.overrideWithValue(_FakeBackend()),
            authControllerProvider.overrideWith(
              (ref) => _ReadyAuthController(const AuthSession(
                token: 'token',
                role: 'ADMIN',
                employeeId: 'ADMIN-1',
                fullName: 'Admin',
              )),
            ),
            employeesProvider.overrideWith((ref) async => const [
                  {
                    'employeeId': 'EMP-1',
                    'firstName': 'Elif',
                    'lastName': 'Yılmaz',
                    'active': true,
                  },
                ]),
            employeeAppointmentsProvider
                .overrideWith((ref, query) async => appointments),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AdminDashboardPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bölüm seç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Randevular').last);
      await tester.pumpAndSettle();
    }

    testWidgets('Geçmiş, iptal edilmemiş randevu Tamamlandı gösterir',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpAdmin(tester, [appointment(5, 'PENDING', time: '00:01:00')]);

      expect(find.text('Tamamlandı'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Onayla'), findsNothing);
      // İptal stays available regardless — cancelling an unresolved past
      // booking is still a valid admin action.
      expect(find.widgetWithText(TextButton, 'İptal'), findsOneWidget);
    });

    testWidgets('Geçmişte olsa bile CANCELLED randevu İptal edildi kalır',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpAdmin(tester, [appointment(6, 'CANCELLED', time: '00:01:00')]);

      expect(find.text('İptal edildi'), findsOneWidget);
      expect(find.text('Tamamlandı'), findsNothing);
    });
  });
}

class _FakeBackend extends GlowBackendService {
  _FakeBackend()
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );
}

class _ReadyAuthController extends AuthController {
  _ReadyAuthController(AuthSession session)
      : super(GlowBackendService(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        )) {
    state = AsyncValue.data(session);
  }
}
