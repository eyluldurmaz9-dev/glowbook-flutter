import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/dashboard/admin_dashboard_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Regression coverage: on Randevu Yönetimi, three or more appointment rows
/// with different statuses (each showing a different-width İşlem action set)
/// must render as fully separate rows, never bleeding into one another.
/// DataTable's default fixed row height doesn't grow with content, so a
/// wrapped/second line of a "Durum"/İşlem cell used to paint into the row
/// below it instead of growing its own row.
void main() {
  testWidgets(
      'Randevu Yönetiminde üç randevu satırı birbirine binmeden ayrı ayrı render edilir',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glowBackendServiceProvider.overrideWithValue(_FakeAdminBackend()),
          authControllerProvider.overrideWith(
            (ref) => _ReadyAuthController(),
          ),
          employeesProvider.overrideWith((ref) async => const [
                {
                  'employeeId': 'EMP-1',
                  'firstName': 'Elif',
                  'lastName': 'Yılmaz',
                  'active': true,
                },
              ]),
          employeeAppointmentsProvider.overrideWith((ref, query) async => [
                _appointment(1, '10:00', 'PENDING', 'Cilt Bakımı'),
                _appointment(2, '11:00', 'APPROVED', 'Lazer Epilasyon'),
                _appointment(3, '12:00', 'PENDING', 'Masaj ve Spa'),
              ]),
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

    // Every row must show its own İptal button (present in every status) at a
    // strictly increasing, non-overlapping vertical position — proving each
    // row occupies its own space instead of painting on top of the next.
    final cancelButtons = find.widgetWithText(TextButton, 'İptal');
    expect(cancelButtons, findsNWidgets(3));

    final tops = <double>[
      for (final element in cancelButtons.evaluate())
        tester.getTopLeft(find.byWidget(element.widget)).dy,
    ]..sort();

    for (var i = 1; i < tops.length; i++) {
      expect(
        tops[i] - tops[i - 1],
        greaterThan(20),
        reason:
            'Satır ${i + 1} önceki satırla aynı/çakışan konumda render edildi: $tops',
      );
    }

    // Every status label must also be independently findable (not merged
    // into an overlapping smear of text from adjacent rows).
    expect(find.text('Onay bekliyor'), findsNWidgets(2));
    expect(find.text('Onaylandı'), findsOneWidget);
  });
}

Map<String, dynamic> _appointment(
  int id,
  String time,
  String status,
  String serviceName,
) {
  return <String, dynamic>{
    'appointmentId': id,
    'employeeId': 'EMP-1',
    'appointmentDate': DateTime.now().toIso8601String().substring(0, 10),
    'appointmentTime': '$time:00',
    'serviceName': serviceName,
    'customerName': 'Test',
    'customerSurname': 'Musteri$id',
    'status': status,
  };
}

class _FakeAdminBackend extends GlowBackendService {
  _FakeAdminBackend()
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
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
        role: 'ADMIN',
        employeeId: 'ADMIN-1',
        fullName: 'Admin',
      ),
    );
  }
}
