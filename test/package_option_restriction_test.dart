import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/appointment/appointment_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Regression coverage: picking an owned package on the normal booking
/// wizard's Alt Hizmet/Paket step must restrict "Alt hizmet" to only the
/// sub-service(s) that package actually covers (real coveredOptions
/// relationship, not name matching) — the backend already rejected a
/// mismatched combination at submit time, but the customer could reach that
/// rejection by picking an uncovered option after picking the package.
void main() {
  const fiveBolge = {
    'optionId': 11,
    'serviceId': 2,
    'optionName': '5 Bölge',
    'price': '2200',
  };
  const threeBolge = {
    'optionId': 12,
    'serviceId': 2,
    'optionName': '3 Bölge',
    'price': '1600',
  };
  const wholeBody = {
    'optionId': 13,
    'serviceId': 2,
    'optionName': 'Tüm Vücut',
    'price': '3200',
  };

  Future<void> pumpToOptionStep(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glowBackendServiceProvider.overrideWithValue(_Backend()),
          authControllerProvider.overrideWith((ref) => _Auth()),
          servicesProvider.overrideWith((ref) async => const [
                {
                  'serviceId': 2,
                  'serviceName': 'Lazer Epilasyon',
                  'description': 'Bakım',
                },
              ]),
          serviceOptionsProvider.overrideWith(
            (ref, id) async => const [fiveBolge, threeBolge, wholeBody],
          ),
          servicePackagesProvider.overrideWith((ref, id) async => const [
                {
                  'packageId': 301,
                  'serviceId': 2,
                  'serviceName': 'Lazer Epilasyon',
                  'packageName': '5 Bölge Lazer Paketi',
                  'totalSession': 6,
                  'price': '9800',
                  'active': true,
                },
              ]),
          customerPackagesProvider.overrideWith((ref, id) async => const [
                {
                  'customerPackageId': 55,
                  'packageId': 301,
                  'packageName': '5 Bölge Lazer Paketi',
                  'serviceId': 2,
                  'serviceName': 'Lazer Epilasyon',
                  'totalSession': 6,
                  'usedSession': 0,
                  'scheduledSession': 0,
                  'remainingSession': 6,
                  'active': true,
                  'coveredOptions': [fiveBolge],
                },
              ]),
          customerUpcomingAppointmentsProvider
              .overrideWith((ref, id) async => const []),
          employeesByServiceOptionProvider.overrideWith((ref, q) async => const [
                {'employeeId': 'EMP-1', 'employeeName': 'Elif Yılmaz'},
              ]),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AppointmentPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lazer Epilasyon'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Devam').last);
    await tester.tap(find.text('Devam').last);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Paket dışı seçenekler paket seçildikten sonra hiç gösterilmez ve kapsanan seçenek otomatik seçilir',
      (tester) async {
    await pumpToOptionStep(tester);

    // Before picking the package, every sub-service is offered normally.
    expect(find.text('5 Bölge'), findsOneWidget);
    expect(find.text('3 Bölge'), findsOneWidget);
    expect(find.text('Tüm Vücut'), findsOneWidget);

    await tester.ensureVisible(find.text('5 Bölge Lazer Paketi'));
    await tester.tap(find.text('5 Bölge Lazer Paketi'));
    await tester.pumpAndSettle();

    // Only the package's covered option remains selectable at all.
    expect(find.text('5 Bölge'), findsOneWidget);
    expect(find.text('3 Bölge'), findsNothing);
    expect(find.text('Tüm Vücut'), findsNothing);
  });

  testWidgets('Paket seçildiğinde kapsanan seçenek otomatik seçili hale gelir',
      (tester) async {
    await pumpToOptionStep(tester);

    await tester.ensureVisible(find.text('5 Bölge Lazer Paketi'));
    await tester.tap(find.text('5 Bölge Lazer Paketi'));
    await tester.pumpAndSettle();

    // Continuing must be allowed immediately — the option was auto-resolved,
    // not left unset.
    await tester.ensureVisible(find.text('Devam').last);
    await tester.tap(find.text('Devam').last);
    await tester.pumpAndSettle();

    expect(find.text('Personel seçimi'), findsOneWidget);
  });

  testWidgets(
      'Paket kullanılmadan (Tek seans) normal booking tüm seçenekleri sunmaya devam eder',
      (tester) async {
    await pumpToOptionStep(tester);

    expect(find.text('Tek seans olarak devam et'), findsOneWidget);
    await tester.ensureVisible(find.text('Tek seans olarak devam et'));
    await tester.tap(find.text('Tek seans olarak devam et'));
    await tester.pumpAndSettle();

    expect(find.text('5 Bölge'), findsOneWidget);
    expect(find.text('3 Bölge'), findsOneWidget);
    expect(find.text('Tüm Vücut'), findsOneWidget);

    await tester.ensureVisible(find.text('3 Bölge'));
    await tester.tap(find.text('3 Bölge'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Devam').last);
    await tester.tap(find.text('Devam').last);
    await tester.pumpAndSettle();

    expect(find.text('Personel seçimi'), findsOneWidget);
  });
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
  _Auth()
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
