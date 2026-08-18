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

/// Covers the required normal-booking step order (Hizmet -> Seçenek ->
/// Personel -> Tarih -> Saat -> Özet) and that the broken top-right
/// "Personel seç" shortcut — which discarded the whole wizard via
/// `context.go()` and had no way back — is gone for good, not merely hidden.
void main() {
  Future<void> pumpWizard(WidgetTester tester) async {
    final backend = _Backend();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glowBackendServiceProvider.overrideWithValue(backend),
          authControllerProvider.overrideWith((ref) => _Auth(backend)),
          servicesProvider.overrideWith((ref) async => const [
                {
                  'serviceId': 1,
                  'serviceName': 'Hydrafacial',
                  'description': 'Bakım',
                },
              ]),
          serviceOptionsProvider.overrideWith((ref, id) async => const [
                {
                  'optionId': 11,
                  'serviceId': 1,
                  'optionName': 'Cilt Bakımı',
                  'price': '900',
                },
              ]),
          servicePackagesProvider.overrideWith((ref, id) async => const []),
          customerPackagesProvider.overrideWith((ref, id) async => const []),
          employeesByServiceOptionProvider
              .overrideWith((ref, q) async => const [
                    {'employeeId': 'EMP-1', 'employeeName': 'Elif Yılmaz'},
                  ]),
          availableSlotsProvider.overrideWith((ref, q) async => const []),
          customerUpcomingAppointmentsProvider
              .overrideWith((ref, id) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AppointmentPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Normal randevu akışı sırası Hizmet, Seçenek, Personel, Tarih, Saat, Özet',
      (tester) async {
    await pumpWizard(tester);

    final stepper = tester.widget<BookingStepper>(find.byType(BookingStepper));
    expect(stepper.steps,
        ['Hizmet', 'Seçenek', 'Personel', 'Tarih', 'Saat', 'Özet']);
  });

  testWidgets('Bozuk üst-sağ Personel seç kısayolu artık yok', (tester) async {
    await pumpWizard(tester);

    expect(find.byTooltip('Personel seç'), findsNothing);
    expect(find.byIcon(Icons.badge_outlined), findsNothing);
    // The calendar shortcut is the only remaining header action.
    expect(find.byTooltip('Takvim'), findsOneWidget);
  });

  testWidgets('Seçenekten sonraki adım Personel seçimidir, Tarih değildir',
      (tester) async {
    await pumpWizard(tester);

    await tester.tap(find.text('Hydrafacial'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Devam').last);
    await tester.tap(find.text('Devam').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cilt Bakımı'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Devam').last);
    await tester.tap(find.text('Devam').last);
    await tester.pumpAndSettle();

    expect(find.text('Personel seçimi'), findsOneWidget);
    expect(find.text('İlk Müsait Zaman'), findsOneWidget);
    expect(find.text('Tarih seçimi'), findsNothing);
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
