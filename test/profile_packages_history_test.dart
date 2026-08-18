import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/appointment/booking_models.dart';
import 'package:glowbook_flutter/features/profile/profile_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Customer profile must show "Paketlerim" with the derived session counts and
/// split appointments into Yaklaşan / Geçmiş without overlap.
void main() {
  const upcomingAppointment = {
    'appointmentId': 1,
    'serviceName': 'Lazer Epilasyon',
    'optionName': '5 Bolge',
    'appointmentDate': '2026-09-01',
    'appointmentTime': '14:00:00',
    'status': 'PENDING',
  };
  const pastAppointment = {
    'appointmentId': 2,
    'serviceName': 'Cilt Bakımı',
    'optionName': 'Hydrafacial',
    'appointmentDate': '2026-08-14',
    'appointmentTime': '09:00:00',
    'status': 'APPROVED',
  };
  const cancelledPastAppointment = {
    'appointmentId': 3,
    'serviceName': 'Masaj ve Spa',
    'optionName': 'Medikal Masaj',
    'appointmentDate': '2026-08-10',
    'appointmentTime': '11:00:00',
    'status': 'CANCELLED',
  };

  testWidgets('Profil Paketlerim bölümünü gösterir', (tester) async {
    await _pumpProfile(tester);

    expect(find.byKey(const Key('profile_my_packages')), findsOneWidget);
    expect(find.text('Paketlerim'), findsOneWidget);
    expect(find.text('10 Seans Lazer'), findsOneWidget);
  });

  testWidgets('Toplam / kullanılan / planlanan / kalan seans sayıları görünür',
      (tester) async {
    await _pumpProfile(tester, packages: const [
      {
        'customerPackageId': 5,
        'packageId': 201,
        'packageName': '10 Seans Lazer',
        'serviceName': 'Lazer Epilasyon',
        'totalSession': 10,
        'usedSession': 3,
        'scheduledSession': 1,
        'remainingSession': 6,
        'validUntil': '2027-08-14',
        'active': true,
      },
    ]);

    expect(find.text('Toplam'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Kullanılan'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Planlanan'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Kalan'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('Gelecekteki paket randevusu kullanılmış olarak sayılmaz',
      (tester) async {
    await _pumpProfile(tester, packages: const [
      {
        'customerPackageId': 5,
        'packageId': 201,
        'packageName': '10 Seans Lazer',
        'serviceName': 'Lazer Epilasyon',
        'totalSession': 10,
        'usedSession': 0,
        'scheduledSession': 1,
        'remainingSession': 9,
        'active': true,
      },
    ]);

    final used = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('profile_my_packages')),
        matching: find.text('0'),
      ),
    );
    expect(used.data, '0');
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('Yaklaşan ve Geçmiş randevular ayrı başlıklarda listelenir',
      (tester) async {
    await _pumpProfile(
      tester,
      upcoming: const [upcomingAppointment],
      past: const [pastAppointment, cancelledPastAppointment],
    );

    expect(find.text('Randevularım'), findsOneWidget);
    expect(find.text('Yaklaşan Randevular'), findsOneWidget);
    expect(find.text('Geçmiş Randevular'), findsOneWidget);
    expect(find.textContaining('2026-09-01 14:00'), findsOneWidget);
    expect(find.textContaining('2026-08-14 09:00'), findsOneWidget);
  });

  testWidgets('Saati geçmiş randevu yalnızca Geçmiş altında görünür',
      (tester) async {
    await _pumpProfile(
      tester,
      upcoming: const [],
      past: const [pastAppointment],
    );

    // The 09:00 appointment is history only; nothing lands in both buckets.
    expect(find.text('Yaklaşan randevun yok'), findsOneWidget);
    expect(find.textContaining('2026-08-14 09:00'), findsOneWidget);
    expect(find.text('Geçmiş randevun yok'), findsNothing);
  });

  testWidgets('İptal edilen geçmiş randevu iptal edildi olarak etiketlenir',
      (tester) async {
    await _pumpProfile(
      tester,
      upcoming: const [],
      past: const [cancelledPastAppointment],
    );

    expect(find.textContaining('İptal edildi'), findsOneWidget);
  });

  testWidgets(
      'Düzenle/Kaydet kişisel bilgiler bölümünün altında, paket ve randevu listelerinden önce görünür',
      (tester) async {
    await _pumpProfile(
      tester,
      upcoming: List.generate(
        20,
        (index) => {
          'appointmentId': index,
          'serviceName': 'Hizmet $index',
          'optionName': 'Seçenek',
          'appointmentDate': '2026-09-${(index % 28) + 1}',
          'appointmentTime': '10:00:00',
          'status': 'PENDING',
        },
      ),
    );

    final editButtonY = tester.getTopLeft(find.text('Düzenle').first).dy;
    final packagesHeaderY = tester.getTopLeft(find.text('Paketlerim')).dy;
    final appointmentsHeaderY = tester.getTopLeft(find.text('Randevularım')).dy;

    expect(editButtonY, lessThan(packagesHeaderY),
        reason: 'Düzenle, Paketlerim bölümünden önce gelmeli');
    expect(editButtonY, lessThan(appointmentsHeaderY),
        reason: 'Düzenle, Randevularım bölümünden önce gelmeli — '
            '20 randevu olsa bile aşağı kaydırmadan erişilebilir olmalı');
  });

  testWidgets('Profil ekranında teknik terim sızmaz', (tester) async {
    await _pumpProfile(
      tester,
      upcoming: const [upcomingAppointment],
      past: const [pastAppointment],
    );

    final visible = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .join(' ')
        .toLowerCase();
    for (final banned in [
      'backend',
      'endpoint',
      'http',
      'json',
      'dto',
      'utc',
      'database',
      'server',
    ]) {
      expect(visible.contains(banned), isFalse, reason: 'sızan terim: $banned');
    }
  });

  group('CustomerPackageOption', () {
    test('backendin türettiği kullanılan seans sayısını okur', () {
      final option = CustomerPackageOption.fromJson(const {
        'customerPackageId': 5,
        'packageId': 201,
        'packageName': '10 Seans Lazer',
        'totalSession': 10,
        'usedSession': 1,
        'scheduledSession': 0,
        'remainingSession': 9,
        'active': true,
      });

      expect(option.totalSession, 10);
      expect(option.usedSession, 1);
      expect(option.scheduledSession, 0);
      expect(option.remainingSession, 9);
    });

    test('planlanan seansı kullanılmış olarak saymaz', () {
      final option = CustomerPackageOption.fromJson(const {
        'customerPackageId': 5,
        'packageId': 201,
        'packageName': '10 Seans Lazer',
        'totalSession': 10,
        'scheduledSession': 1,
        'remainingSession': 9,
        'active': true,
      });

      expect(option.usedSession, 0);
    });
  });
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  List<Map<String, dynamic>>? packages,
  List<Map<String, dynamic>>? upcoming,
  List<Map<String, dynamic>>? past,
}) async {
  final backend = _FakeBackend();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith((ref) => _ReadyAuthController(backend)),
        profileProvider.overrideWith((ref) async => const {
              'customerId': 12,
              'firstName': 'Derya',
              'lastName': 'Yılmaz',
              'phone': '05551110000',
              'email': 'derya@glowbook.test',
            }),
        customerPackagesProvider.overrideWith(
          (ref, customerId) async =>
              packages ??
              const [
                {
                  'customerPackageId': 5,
                  'packageId': 201,
                  'packageName': '10 Seans Lazer',
                  'serviceName': 'Lazer Epilasyon',
                  'totalSession': 10,
                  'usedSession': 0,
                  'scheduledSession': 1,
                  'remainingSession': 9,
                  'active': true,
                },
              ],
        ),
        customerUpcomingAppointmentsProvider
            .overrideWith((ref, customerId) async => upcoming ?? const []),
        customerPastAppointmentsProvider
            .overrideWith((ref, customerId) async => past ?? const []),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProfilePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeBackend extends GlowBackendService {
  _FakeBackend()
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

class _ReadyAuthController extends AuthController {
  _ReadyAuthController(super.backend) {
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
