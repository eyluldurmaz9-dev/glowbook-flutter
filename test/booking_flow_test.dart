import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/features/appointment/appointment_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

void main() {
  testWidgets('Tam başarılı randevu akışı backend sonucu gösterir',
      (tester) async {
    final backend = _FakeGlowBackendService();
    await _pumpBooking(tester, backend: backend);

    await _completeSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();

    expect(find.text('Randevun oluşturuldu'), findsOneWidget);
    expect(find.text('PENDING'), findsOneWidget);
    expect(backend.createCount, 1);
  });

  testWidgets('Slot doldu hatası kullanıcıya Türkçe gösterilir',
      (tester) async {
    final backend = _FakeGlowBackendService(
      createError: Exception('Selected appointment time is already occupied'),
    );
    await _pumpBooking(tester, backend: backend);

    await _completeSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await tester.pump();

    expect(find.text('Seçilen saat az önce doldu. Lütfen başka bir saat seç.'),
        findsOneWidget);
  });

  testWidgets('Ağ hatası güvenli hata mesajı gösterir', (tester) async {
    final backend = _FakeGlowBackendService(
      createError: Exception('Backend sunucusuna ulaşılamadı.'),
    );
    await _pumpBooking(tester, backend: backend);

    await _completeSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await tester.pump();

    expect(
        find.text('Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.'),
        findsOneWidget);
  });

  testWidgets('Yetkisiz oturum mesajı gösterilir', (tester) async {
    final backend = _FakeGlowBackendService(
      createError: Exception('401 unauthorized'),
    );
    await _pumpBooking(tester, backend: backend);

    await _completeSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await tester.pump();

    expect(find.text('Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap.'),
        findsOneWidget);
  });

  testWidgets('Bekleme listesine katılma gerçek endpoint çağrısını yapar',
      (tester) async {
    final backend = _FakeGlowBackendService();
    await _pumpBooking(tester, backend: backend, slots: const []);

    await _tapText(tester, 'Hydrafacial');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Cilt Bakımı');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Bekleme Listesine Katıl');
    await tester.pumpAndSettle();

    expect(find.text('Bekleme listesine eklendin'), findsOneWidget);
    expect(backend.waitlistCount, 1);
  });

  testWidgets('Geri navigasyonda seçim state korunur', (tester) async {
    await _pumpBooking(tester, backend: _FakeGlowBackendService());

    await _tapText(tester, 'Hydrafacial');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Cilt Bakımı');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Geri');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Devam', last: true);
    await tester.pumpAndSettle();

    expect(find.text('Cilt Bakımı'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });

  testWidgets('Çift gönderim tek randevu oluşturur', (tester) async {
    final backend = _FakeGlowBackendService();
    await _pumpBooking(tester, backend: backend);

    await _completeSelections(tester);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Onayla', last: true);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();

    expect(backend.createCount, 1);
  });
}

Future<void> _pumpBooking(
  WidgetTester tester, {
  required _FakeGlowBackendService backend,
  List<Map<String, dynamic>>? slots,
}) async {
  final today = DateTime.now();
  final slotDate = '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';
  final effectiveSlots = slots ??
      [
        {
          'employeeId': 'EMP-1',
          'employeeName': 'Elif Yılmaz',
          'appointmentDate': slotDate,
          'availableTimes': ['10:00:00'],
        }
      ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith(
          (ref) => _ReadyAuthController(backend),
        ),
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
        servicePackagesProvider
            .overrideWith((ref, serviceId) async => const []),
        customerPackagesProvider
            .overrideWith((ref, customerId) async => const []),
        availableSlotsProvider
            .overrideWith((ref, query) async => effectiveSlots),
        customerUpcomingAppointmentsProvider.overrideWith(
          (ref, customerId) async => const [],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AppointmentPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _completeSelections(WidgetTester tester) async {
  await _tapText(tester, 'Hydrafacial');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();
  await _tapText(tester, 'Cilt Bakımı');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();
  await _tapTextContaining(tester, '10:00');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();
  await _tapText(tester, 'Elif Yılmaz');
  await tester.pumpAndSettle();
  await _tapText(tester, 'Devam', last: true);
  await tester.pumpAndSettle();
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

Future<void> _tapTextContaining(WidgetTester tester, String text) async {
  final finder = find.textContaining(text).first;
  if (finder.evaluate().isEmpty) {
    fail('Metin parçası bulunamadı: $text');
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
}

class _FakeGlowBackendService extends GlowBackendService {
  _FakeGlowBackendService({this.createError})
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  final Object? createError;
  int createCount = 0;
  int waitlistCount = 0;

  @override
  Future<Map<String, dynamic>> createAppointment(
      Map<String, dynamic> payload) async {
    createCount++;
    if (createError != null) throw createError!;
    return {
      'appointmentId': 99,
      'customerId': payload['customerId'],
      'employeeId': payload['employeeId'],
      'employeeName': 'Elif Yılmaz',
      'serviceId': payload['serviceId'],
      'serviceName': 'Hydrafacial',
      'optionId': payload['optionId'],
      'optionName': 'Cilt Bakımı',
      'appointmentDate': payload['appointmentDate'],
      'appointmentTime': payload['appointmentTime'],
      'price': '900',
      'status': 'PENDING',
    };
  }

  @override
  Future<Map<String, dynamic>> createWaitingListRecord(
    Map<String, dynamic> payload,
  ) async {
    waitlistCount++;
    return {
      'waitingListId': 7,
      'customerId': payload['customerId'],
      'serviceId': payload['serviceId'],
      'serviceName': 'Hydrafacial',
      'optionId': payload['optionId'],
      'optionName': 'Cilt Bakımı',
      'preferredDate': payload['preferredDate'],
      'preferredStartTime': payload['preferredStartTime'],
      'status': 'ACTIVE',
    };
  }

  @override
  Future<AuthSession?> currentSession() async {
    return const AuthSession(
      token: 'token',
      role: 'CUSTOMER',
      customerId: 12,
      fullName: 'Derya Yılmaz',
    );
  }
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
