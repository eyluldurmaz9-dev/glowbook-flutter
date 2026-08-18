import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/dashboard/customer_dashboard_page.dart';
import 'package:glowbook_flutter/features/notification/notification_page.dart';
import 'package:glowbook_flutter/features/profile/profile_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

void main() {
  testWidgets('Yaklaşan ve geçmiş randevu ayrımı gösterilir', (tester) async {
    await _pumpDashboard(tester, backend: _FakeCustomerBackend());

    _expectText(tester, 'Hydrafacial');
    await _tapText(tester, 'Geçmiş', last: true);
    await tester.pumpAndSettle();

    expect(find.text('Kalıcı Oje'), findsOneWidget);
  });

  testWidgets('Paketlerim müşteri panelinde korunur', (tester) async {
    await _pumpDashboard(tester, backend: _FakeCustomerBackend());

    expect(find.text('Paketlerim'), findsWidgets);
    expect(find.widgetWithText(Tab, 'Paketlerim'), findsOneWidget);
  });
  testWidgets('Randevu iptal başarı durumu provider yeniler', (tester) async {
    final backend = _FakeCustomerBackend();
    await _pumpDashboard(tester, backend: backend);

    await _tapText(tester, 'İptal Et');
    await tester.pumpAndSettle();
    await _tapText(tester, 'İptal Et', last: true);
    await tester.pumpAndSettle();

    expect(backend.cancelCount, 1);
    expect(find.text('Randevu iptal edildi.'), findsOneWidget);
  });

  testWidgets('Randevu iptal hata durumu gösterilir', (tester) async {
    final backend =
        _FakeCustomerBackend(cancelError: Exception('Sunucu hatası'));
    await _pumpDashboard(tester, backend: backend);

    await _tapText(tester, 'İptal Et');
    await tester.pumpAndSettle();
    await _tapText(tester, 'İptal Et', last: true);
    await tester.pump();

    expect(find.textContaining('Sunucu hatası'), findsOneWidget);
  });

  testWidgets('Profil güncelleme validation mesajları gösterilir',
      (tester) async {
    await _pumpProfile(tester, backend: _FakeCustomerBackend());

    // "Düzenle" also now labels each upcoming appointment's edit action
    // (rendered above this row) — `last: true` picks the profile's own
    // edit-mode toggle, not an appointment card's.
    await _tapText(tester, 'Düzenle', last: true);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Ad'), '');
    await tester.enterText(find.widgetWithText(TextFormField, 'Şifre'), '123');
    await _tapText(tester, 'Kaydet');
    await tester.pump();

    expect(find.text('Bu alan zorunludur.'), findsWidgets);
    expect(find.text('Şifre en az 6 karakter olmalıdır.'), findsOneWidget);
  });

  testWidgets('Bildirim okundu işlemi backend çağrısı yapar', (tester) async {
    final backend = _FakeCustomerBackend();
    await _pumpNotification(tester, backend: backend);

    await _tapText(tester, 'Okundu Yap');
    await tester.pumpAndSettle();

    expect(backend.markReadCount, 1);
    expect(find.text('Bildirim okundu olarak işaretlendi.'), findsOneWidget);
  });

  testWidgets('Yetkisiz müşteri paneli giriş mesajı gösterir', (tester) async {
    await _pumpDashboard(
      tester,
      backend: _FakeCustomerBackend(),
      session: null,
    );

    expect(find.text('Müşteri oturumu bulunamadı.'), findsOneWidget);
  });
}

void _expectText(WidgetTester tester, String text) {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .join(' | ');
    fail('Metin bulunamadı: $text. Ekrandaki metinler: $texts');
  }
  expect(finder, findsOneWidget);
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required _FakeCustomerBackend backend,
  AuthSession? session = const AuthSession(
    token: 'token',
    role: 'CUSTOMER',
    customerId: 12,
  ),
}) async {
  await tester.pumpWidget(
    _wrap(
      backend: backend,
      session: session,
      child: const CustomerDashboardPage(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required _FakeCustomerBackend backend,
}) async {
  await tester.pumpWidget(
    _wrap(backend: backend, child: const ProfilePage()),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpNotification(
  WidgetTester tester, {
  required _FakeCustomerBackend backend,
}) async {
  await tester.pumpWidget(
    _wrap(backend: backend, child: const NotificationPage()),
  );
  await tester.pumpAndSettle();
}

Widget _wrap({
  required _FakeCustomerBackend backend,
  required Widget child,
  AuthSession? session = const AuthSession(
    token: 'token',
    role: 'CUSTOMER',
    customerId: 12,
  ),
}) {
  return ProviderScope(
    overrides: [
      glowBackendServiceProvider.overrideWithValue(backend),
      authControllerProvider.overrideWith(
        (ref) => _ReadyAuthController(backend, session),
      ),
      customerUpcomingAppointmentsProvider.overrideWith(
        (ref, customerId) async => const [
          {
            'appointmentId': 1,
            'serviceName': 'Hydrafacial',
            'optionName': 'Cilt Bakımı',
            'employeeName': 'Elif Yılmaz',
            'appointmentDate': '2026-08-01',
            'appointmentTime': '10:00:00',
            'status': 'PENDING',
            'price': '900',
          },
        ],
      ),
      customerPastAppointmentsProvider.overrideWith(
        (ref, customerId) async => const [
          {
            'appointmentId': 2,
            'serviceName': 'Kalıcı Oje',
            'optionName': 'Manikür',
            'employeeName': 'Derya',
            'appointmentDate': '2026-07-01',
            'appointmentTime': '12:00:00',
            'status': 'COMPLETED',
          },
        ],
      ),
      customerPackagesProvider.overrideWith(
        (ref, customerId) async => const [
          {
            'customerPackageId': 4,
            'packageName': '6 Seans',
            'remainingSession': 3,
            'purchaseDate': '2026-07-01',
            'purchasePrice': '1200',
            'active': true,
          },
        ],
      ),
      notificationsProvider.overrideWith(
        (ref, customerId) async => const [
          {
            'notificationId': 5,
            'title': 'Randevu',
            'message': 'Randevunuz oluşturuldu',
            'read': false,
            'createdAt': '2026-07-31T10:00:00',
          },
        ],
      ),
      unreadNotificationsProvider.overrideWith(
        (ref, customerId) async => const [
          {'notificationId': 5},
        ],
      ),
      profileProvider.overrideWith(
        (ref) async => const {
          'customerId': 12,
          'firstName': 'Derya',
          'lastName': 'Yılmaz',
          'phone': '5551112233',
          'email': 'derya@example.com',
        },
      ),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
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

class _FakeCustomerBackend extends GlowBackendService {
  _FakeCustomerBackend({this.cancelError})
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  final Object? cancelError;
  int cancelCount = 0;
  int markReadCount = 0;

  @override
  Future<Map<String, dynamic>> cancelAppointment(
    int appointmentId, {
    String? cancellationReason,
  }) async {
    cancelCount++;
    if (cancelError != null) throw cancelError!;
    return {'appointmentId': appointmentId, 'status': 'CANCELLED'};
  }

  @override
  Future<Map<String, dynamic>> markNotificationAsRead(
      int notificationId) async {
    markReadCount++;
    return {'notificationId': notificationId, 'read': true};
  }

  @override
  Future<Map<String, dynamic>> updateCustomer(
    int customerId,
    Map<String, dynamic> payload,
  ) async {
    return {'customerId': customerId, ...payload};
  }

  @override
  Future<void> logout() async {}
}

class _ReadyAuthController extends AuthController {
  _ReadyAuthController(super.backend, AuthSession? session) {
    state = AsyncValue.data(session);
  }
}
