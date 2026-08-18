import 'dart:io';

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

/// Covers KOMUT 1: Randevu Özeti alignment plus the Turkish-copy audit.
void main() {
  group('Randevu Özeti hizalaması', () {
    testWidgets(
        'Etiketler aynı x konumunda başlar, değerler aynı x konumunda başlar',
        (tester) async {
      await _pumpToSummaryStep(tester);

      final labelXs = <double>[];
      final valueXs = <double>[];
      for (final label in ['Hizmet', 'Alt Hizmet', 'Fiyat', 'Tarih', 'Saat']) {
        labelXs.add(tester.getTopLeft(find.text(label).last).dx);
      }
      for (final value in ['Hydrafacial', 'Cilt Bakımı', '900']) {
        valueXs.add(tester.getTopLeft(find.text(value).last).dx);
      }

      expect(labelXs.toSet().length, 1,
          reason: 'Tüm etiketler aynı dikey eksende başlamalı: $labelXs');
      expect(valueXs.toSet().length, 1,
          reason: 'Tüm değerler aynı dikey eksende başlamalı: $valueXs');
      // The label column and the value column must be two genuinely distinct
      // x positions (not accidentally the same, which would mean the row
      // collapsed into a single column).
      expect(valueXs.first, greaterThan(labelXs.first));
    });

    testWidgets('Uzun bir hizmet/paket adı taşmadan sarmalanır',
        (tester) async {
      await _pumpToSummaryStep(
        tester,
        optionName:
            'Bölgesel İncelme ve Sıkılaştırma için Uzun Süreli Bakım Programı',
      );

      // No RenderFlex overflow / layout exception for the long value.
      expect(tester.takeException(), isNull);

      final labelX = tester.getTopLeft(find.text('Hizmet').last).dx;
      final valueFinder =
          find.textContaining('Bölgesel İncelme ve Sıkılaştırma').last;
      final valueX = tester.getTopLeft(valueFinder).dx;
      final valueSize = tester.getSize(valueFinder);

      // Still starts in the value column, not the label column, and wrapped
      // to more than one line instead of overflowing sideways.
      expect(valueX, greaterThan(labelX));
      expect(valueSize.height, greaterThan(20));
    });
  });

  group('Türkçe metin doğru render ediliyor', () {
    // "Geçmiş Randevular" / "Yaklaşan Randevular" / "İletişim" / "Çıkış Yap"
    // already have dedicated, passing coverage: test/profile_packages_history_test.dart
    // ("Yaklaşan ve Geçmiş randevular ayrı başlıklarda listelenir"),
    // test/web_landing_page_test.dart ("İletişim" nav/footer links), and
    // test/admin_dashboard_test.dart (byTooltip('Çıkış Yap'), updated in this change).
    testWidgets('"Cilt Bakımı" Randevu Özeti\'nde doğru görüntülenir',
        (tester) async {
      await _pumpToSummaryStep(tester, optionName: 'Cilt Bakımı');

      expect(find.text('Cilt Bakımı'), findsWidgets);
      expect(find.text('Cilt bakimi'), findsNothing);
      expect(find.text('Cilt Bakimi'), findsNothing);
    });
  });

  group('Kaynak kodda bilinen hatalı Türkçe stringler kalmamış', () {
    test(
        'Cilt Bakimi / Gecmis Randevular / Yaklasan Randevular / Iletisim / Cikis Yap gibi '
        'bozuk stringler lib/ altında yok', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      const banned = [
        'Cilt Bakimi',
        'Gecmis Randevular',
        'gecmis randevular',
        'Yaklasan Randevular',
        'yaklasan randevular',
        'Iletisim',
        'Cikis Yap',
        'cikis yap',
        'Oturumu kapat',
        'Oturumu Kapat',
        'Aninda randevu',
        'Kas ve Kirpik',
        'Bolgesel Incelme',
      ];

      final offenders = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        for (final phrase in banned) {
          if (content.contains(phrase)) {
            offenders.add('${entity.path}: "$phrase"');
          }
        }
      }

      expect(offenders, isEmpty,
          reason: 'Bozuk Türkçe metin(ler) hâlâ mevcut:\n${offenders.join('\n')}');
    });

    test('lib/ altındaki tüm .dart dosyaları geçerli UTF-8', () {
      final libDir = Directory('lib');
      final invalid = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        try {
          entity.readAsStringSync();
        } on FormatException {
          invalid.add(entity.path);
        }
      }
      expect(invalid, isEmpty,
          reason: 'Geçersiz/mojibake UTF-8 içeren dosyalar:\n${invalid.join('\n')}');
    });
  });
}

Future<void> _pumpToSummaryStep(
  WidgetTester tester, {
  String optionName = 'Cilt Bakımı',
}) async {
  final backend = _Backend();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith((ref) => _Auth(backend)),
        servicesProvider.overrideWith((ref) async => const [
              {'serviceId': 1, 'serviceName': 'Hydrafacial', 'description': 'x'}
            ]),
        serviceOptionsProvider.overrideWith((ref, id) async => [
              {'optionId': 11, 'serviceId': 1, 'optionName': optionName, 'price': '900'}
            ]),
        servicePackagesProvider.overrideWith((ref, id) async => const []),
        customerPackagesProvider.overrideWith((ref, id) async => const []),
        employeesByServiceOptionProvider.overrideWith((ref, q) async => const [
              {'employeeId': 'EMP-1', 'employeeName': 'Eylem Ceylan'},
            ]),
        availableSlotsProvider.overrideWith((ref, q) async => [
              {
                'employeeId': 'EMP-1',
                'employeeName': 'Eylem Ceylan',
                'appointmentDate': q.date,
                'availableTimes': ['10:00:00'],
              }
            ]),
        customerUpcomingAppointmentsProvider.overrideWith((ref, id) async => const []),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const AppointmentPage()),
    ),
  );
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Hydrafacial'));
  await tester.tap(find.text('Hydrafacial'), warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Devam').last);
  await tester.tap(find.text('Devam').last, warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(optionName));
  await tester.tap(find.text(optionName), warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Devam').last);
  await tester.tap(find.text('Devam').last, warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Eylem Ceylan'));
  await tester.tap(find.text('Eylem Ceylan'), warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Devam').last);
  await tester.tap(find.text('Devam').last, warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Devam').last);
  await tester.tap(find.text('Devam').last, warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.textContaining('10:00'));
  await tester.tap(find.textContaining('10:00').first, warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Devam').last);
  await tester.tap(find.text('Devam').last, warnIfMissed: false);
  await tester.pumpAndSettle();
}

class _Backend extends GlowBackendService {
  _Backend() : super(ApiService(GlowApiClient(secureStorage: SecureStorageService())), SecureStorageService());
  @override
  Future<AuthSession?> currentSession() async =>
      const AuthSession(token: 't', role: 'CUSTOMER', customerId: 12, fullName: 'Test');
}

class _Auth extends AuthController {
  _Auth(super.backend) {
    state = const AsyncValue.data(
      AuthSession(token: 't', role: 'CUSTOMER', customerId: 12, fullName: 'Test'),
    );
  }
}
