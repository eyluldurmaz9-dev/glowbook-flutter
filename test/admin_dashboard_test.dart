import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/widgets/glow_widgets.dart';
import 'package:glowbook_flutter/features/dashboard/admin_dashboard_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

void main() {
  testWidgets('Admin route guard müşteri erişimini engeller', (tester) async {
    await _pumpAdmin(
      tester,
      backend: _FakeAdminBackend(),
      session:
          const AuthSession(token: 'token', role: 'CUSTOMER', customerId: 1),
    );

    expect(find.text('Admin yetkisi gerekli'), findsOneWidget);
  });

  testWidgets('Responsive admin layout geniş ekranda sidebar gösterir',
      (tester) async {
    _setWideViewport(tester);
    await _pumpAdmin(tester, backend: _FakeAdminBackend());

    expect(find.text('Genel Bakış'), findsWidgets);
    expect(find.text('Hizmetler'), findsWidgets);
    expect(find.text('Paketler'), findsWidgets);

    addTearDown(() => _resetViewport(tester));
  });

  testWidgets(
      'Backend destek kapsamı placeholder kartı kaldırıldı, diğer istatistikler kaldı',
      (tester) async {
    _setWideViewport(tester);
    await _pumpAdmin(tester, backend: _FakeAdminBackend());

    expect(find.text('Backend destek kapsamı'), findsNothing);
    expect(find.text('Hizmetler'), findsWidgets);
    expect(find.text('Paketler'), findsWidgets);
    expect(find.text('Personel'), findsWidgets);
    expect(find.text('Müşteriler'), findsWidgets);

    addTearDown(() => _resetViewport(tester));
  });

  testWidgets('Admin çıkış düğmesi mobil görünümde erişilebilirdir',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await _pumpAdmin(tester, backend: _FakeAdminBackend());

    expect(find.byKey(const Key('admin_mobile_logout')), findsOneWidget);
    expect(find.byTooltip('Çıkış Yap'), findsOneWidget);
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets('Hizmet CRUD oluşturma ve silme onay akışı çalışır',
      (tester) async {
    _setWideViewport(tester);
    final backend = _FakeAdminBackend();
    await _pumpAdmin(tester, backend: backend);

    await tester.tap(find.byKey(const Key('admin_nav_services')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin_service_create_form')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hizmet adı'),
      'Cilt Bakımı',
    );
    await _tapText(tester, 'Kaydet');
    await tester.pumpAndSettle();

    expect(backend.createServiceCount, 1);
    expect(find.text('Hizmet kaydedildi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin_service_delete')).first);
    await tester.pumpAndSettle();
    expect(find.text('Hizmeti pasifleştir'), findsOneWidget);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();

    expect(backend.deactivateServiceCount, 1);
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets('Paket CRUD güncelleme backend çağrısı yapar', (tester) async {
    _setWideViewport(tester);
    final backend = _FakeAdminBackend();
    await _pumpAdmin(tester, backend: backend);

    await tester.tap(find.byKey(const Key('admin_nav_packages')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('admin_package_edit')));
    await tester.tap(find.byKey(const Key('admin_package_edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Paket adı'),
      'Premium Paket',
    );
    await _tapText(tester, 'Kaydet');
    await tester.pumpAndSettle();

    expect(backend.updatePackageCount, 1);
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets('Personel listeleme gerçek provider verisini gösterir',
      (tester) async {
    _setWideViewport(tester);
    await _pumpAdmin(tester, backend: _FakeAdminBackend());

    await tester.tap(find.byKey(const Key('admin_nav_employees')));
    await tester.pumpAndSettle();

    expect(find.text('EMP-1'), findsOneWidget);
    expect(find.text('Elif Yılmaz'), findsOneWidget);
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets('Personel oluşturma ana hizmeti tek kez gösterip kaydeder',
      (tester) async {
    _setWideViewport(tester);
    final backend = _FakeAdminBackend();
    await _pumpAdmin(tester, backend: backend);

    await tester.tap(find.byKey(const Key('admin_nav_employees')));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Personel Ekle');
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Personel ID'), 'EMP-2');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ad'), 'Ayşe');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Soyad'), 'Uzman');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Şifre'), 'safe-password');
    expect(find.text('Hydrafacial'), findsOneWidget);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Hydrafacial'));
    await tester.pump();
    await _tapText(tester, 'Kaydet');
    await tester.pumpAndSettle();

    expect(backend.createdEmployee?['serviceIds'], [1, 2]);
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets('Personel düzenleme mevcut yetkinliği seçili gösterir',
      (tester) async {
    _setWideViewport(tester);
    await _pumpAdmin(tester, backend: _FakeAdminBackend());

    await tester.tap(find.byKey(const Key('admin_nav_employees')));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Düzenle');
    await tester.pumpAndSettle();
    final checkbox = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Hydrafacial'),
    );
    expect(checkbox.value, isTrue);
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets('Personel silme güvenli pasifleştirme onayı gösterir',
      (tester) async {
    _setWideViewport(tester);
    final backend = _FakeAdminBackend();
    await _pumpAdmin(tester, backend: backend);

    await tester.tap(find.byKey(const Key('admin_nav_employees')));
    await tester.pumpAndSettle();
    final deleteButton = find.byKey(const Key('admin_employee_delete_EMP-1'));
    tester.widget<TextButton>(deleteButton).onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Personeli Sil'), findsOneWidget);
    await _tapText(tester, 'Onayla', last: true);
    await tester.pumpAndSettle();

    expect(backend.deactivateEmployeeCount, 1);
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets('API validation ve conflict hataları güvenli gösterilir',
      (tester) async {
    _setWideViewport(tester);
    final backend =
        _FakeAdminBackend(createServiceError: Exception('409 conflict'));
    await _pumpAdmin(tester, backend: backend);

    await tester.tap(find.byKey(const Key('admin_nav_services')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin_service_create_form')));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Kaydet');
    await tester.pump();
    expect(find.text('Bu alan zorunludur.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hizmet adı'),
      'Çakışan Hizmet',
    );
    await _tapText(tester, 'Kaydet');
    await tester.pumpAndSettle();

    expect(
      find.text('Bu kayıt başka bir veriyle çakışıyor. Bilgileri kontrol et.'),
      findsOneWidget,
    );
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets(
      'Admin panelinde public-home "Ana Sayfaya Dön" kontrolü yoktur',
      (tester) async {
    _setWideViewport(tester);
    await _pumpAdmin(tester, backend: _FakeAdminBackend());

    expect(find.byKey(const Key('services_public_home')), findsNothing);
    expect(find.byKey(const Key('packages_public_home')), findsNothing);
    expect(find.byKey(const Key('booking_public_home')), findsNothing);
    expect(
        find.byKey(const Key('guest_access_public_home')), findsNothing);
    expect(find.text('Ana Sayfaya Dön'), findsNothing);
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets(
      'Hizmet kartı görseli 16/9 AspectRatio içinde render edilir (mobil/web kırpma regresyonu)',
      (tester) async {
    _setWideViewport(tester);
    await _pumpAdmin(tester, backend: _FakeAdminBackend());

    await tester.tap(find.byKey(const Key('admin_nav_services')));
    await tester.pumpAndSettle();

    final image = tester.widget<GlowCatalogImage>(
      find.byType(GlowCatalogImage).first,
    );
    final aspectRatio = tester.widget<AspectRatio>(find.ancestor(
      of: find.byWidget(image),
      matching: find.byType(AspectRatio),
    ));
    expect(aspectRatio.aspectRatio, 16 / 9);
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets(
      'Tatil Günleri bölümü uzak geçmiş/gelecek tatiller dahil tüm kayıtları gösterir',
      (tester) async {
    _setWideViewport(tester);
    // Mirrors the real backend's findByHolidayDateBetween: only holidays
    // whose date falls inside the requested [startDate, endDate] window are
    // returned, so this only shows all 6 if the app actually requests a wide
    // enough range instead of a narrow near-term one.
    final allHolidays = [
      {'holidayId': 1, 'holidayDate': '2024-01-01', 'holidayName': 'Eski Tatil 1'},
      {'holidayId': 2, 'holidayDate': '2025-03-01', 'holidayName': 'Eski Tatil 2'},
      {'holidayId': 3, 'holidayDate': '2026-08-25', 'holidayName': 'Yakin Tatil 1'},
      {'holidayId': 4, 'holidayDate': '2026-09-15', 'holidayName': 'Yakin Tatil 2'},
      {'holidayId': 5, 'holidayDate': '2027-06-01', 'holidayName': 'Uzak Tatil 1'},
      {'holidayId': 6, 'holidayDate': '2028-12-25', 'holidayName': 'Uzak Tatil 2'},
    ];
    final backend = _FakeAdminBackend();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glowBackendServiceProvider.overrideWithValue(backend),
          authControllerProvider.overrideWith(
            (ref) => _ReadyAuthController(
              backend,
              const AuthSession(
                token: 'token',
                role: 'ADMIN',
                employeeId: 'ADMIN-1',
                fullName: 'Admin',
              ),
            ),
          ),
          servicesProvider.overrideWith((ref) async => backend.services),
          serviceOptionsProvider
              .overrideWith((ref, serviceId) async => backend.options),
          allServicePackagesProvider
              .overrideWith((ref) async => backend.packages),
          employeesProvider.overrideWith((ref) async => backend.employees),
          customersProvider.overrideWith((ref) async => backend.customers),
          workingHoursProvider
              .overrideWith((ref) async => backend.workingHours),
          holidaysProvider.overrideWith((ref, query) async {
            final start = DateTime.parse(query.startDate);
            final end = DateTime.parse(query.endDate);
            return allHolidays.where((item) {
              final date = DateTime.parse(item['holidayDate'] as String);
              return !date.isBefore(start) && !date.isAfter(end);
            }).toList();
          }),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme, home: const AdminDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin_nav_schedule')));
    await tester.pumpAndSettle();

    for (final name in [
      'Eski Tatil 1',
      'Eski Tatil 2',
      'Yakin Tatil 1',
      'Yakin Tatil 2',
      'Uzak Tatil 1',
      'Uzak Tatil 2',
    ]) {
      expect(find.text(name), findsOneWidget, reason: '$name görünmüyor');
    }
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets(
      'Kapalı gün listede KAPALI olarak gösterilir, açık günler saatiyle kalır',
      (tester) async {
    _setWideViewport(tester);
    final backend = _FakeAdminBackend();
    final workingHours = const [
      {
        'workingHourId': 1,
        'dayOfWeek': 'MONDAY',
        'startTime': '10:00:00',
        'endTime': '19:00:00',
        'closed': false,
      },
      {
        'workingHourId': 2,
        'dayOfWeek': 'TUESDAY',
        'startTime': '10:00:00',
        'endTime': '19:00:00',
        'closed': true,
      },
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glowBackendServiceProvider.overrideWithValue(backend),
          authControllerProvider.overrideWith(
            (ref) => _ReadyAuthController(
              backend,
              const AuthSession(
                token: 'token',
                role: 'ADMIN',
                employeeId: 'ADMIN-1',
                fullName: 'Admin',
              ),
            ),
          ),
          servicesProvider.overrideWith((ref) async => backend.services),
          serviceOptionsProvider
              .overrideWith((ref, serviceId) async => backend.options),
          allServicePackagesProvider
              .overrideWith((ref) async => backend.packages),
          employeesProvider.overrideWith((ref) async => backend.employees),
          customersProvider.overrideWith((ref) async => backend.customers),
          workingHoursProvider.overrideWith((ref) async => workingHours),
          holidaysProvider.overrideWith((ref, query) async => const []),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme, home: const AdminDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin_nav_schedule')));
    await tester.pumpAndSettle();

    // Regression guard for the reported bug: a closed day must never show
    // a time range that makes it look open again.
    expect(find.text('KAPALI'), findsOneWidget);
    expect(find.text('10:00:00 - 19:00:00'), findsOneWidget,
        reason: 'MONDAY açık, kendi saatiyle görünmeli');

    final editButtons = find.widgetWithText(TextButton, 'Düzenle');
    await tester.ensureVisible(editButtons.last);
    await tester.tap(editButtons.last);
    await tester.pumpAndSettle();

    final closedSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Kapalı'),
    );
    expect(closedSwitch.value, isTrue,
        reason:
            'TUESDAY kapalı olarak kaydedildiyse Düzenle formu Kapalı=ON ile açılmalı');
    addTearDown(() => _resetViewport(tester));
  });

  testWidgets(
      'Randevu Yönetimi: Tamamlandı ve İptal Edildi randevularda İptal aksiyonu yok',
      (tester) async {
    _setWideViewport(tester);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final date = '${tomorrow.year.toString().padLeft(4, '0')}-'
        '${tomorrow.month.toString().padLeft(2, '0')}-'
        '${tomorrow.day.toString().padLeft(2, '0')}';
    final appointments = [
      {
        'appointmentId': 1,
        'appointmentDate': date,
        'appointmentTime': '10:00:00',
        'serviceName': 'Hydrafacial',
        'customerName': 'Beklemede',
        'customerSurname': 'Musteri',
        'status': 'PENDING',
      },
      {
        'appointmentId': 2,
        'appointmentDate': date,
        'appointmentTime': '11:00:00',
        'serviceName': 'Hydrafacial',
        'customerName': 'Onayli',
        'customerSurname': 'Musteri',
        'status': 'APPROVED',
      },
      {
        'appointmentId': 3,
        'appointmentDate': date,
        'appointmentTime': '12:00:00',
        'serviceName': 'Hydrafacial',
        'customerName': 'Tamamlanan',
        'customerSurname': 'Musteri',
        'status': 'COMPLETED',
      },
      {
        'appointmentId': 4,
        'appointmentDate': date,
        'appointmentTime': '13:00:00',
        'serviceName': 'Hydrafacial',
        'customerName': 'Iptal',
        'customerSurname': 'Musteri',
        'status': 'CANCELLED',
      },
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glowBackendServiceProvider.overrideWithValue(_FakeAdminBackend()),
          authControllerProvider.overrideWith(
            (ref) => _ReadyAuthController(
              _FakeAdminBackend(),
              const AuthSession(
                token: 'token',
                role: 'ADMIN',
                employeeId: 'ADMIN-1',
                fullName: 'Admin',
              ),
            ),
          ),
          employeesProvider.overrideWith((ref) async => const [
                {'employeeId': 'EMP-1', 'firstName': 'Elif', 'lastName': 'Yılmaz'},
              ]),
          // A blanket family override: every EmployeeAppointmentsQuery (any
          // week range) resolves to the same fixture, so the test doesn't
          // need to reproduce the widget's own week-range computation.
          employeeAppointmentsProvider.overrideWith((ref, query) async => appointments),
        ],
        child: MaterialApp(
            theme: AppTheme.lightTheme, home: const AdminDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin_nav_appointments')));
    await tester.pumpAndSettle();

    // Onayla only for the PENDING row, Tamamla only for the APPROVED row —
    // and İptal for exactly those two, never for COMPLETED or CANCELLED.
    expect(find.widgetWithText(TextButton, 'Onayla'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Tamamla'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'İptal'), findsNWidgets(2));
    addTearDown(() => _resetViewport(tester));
  });
}

Future<void> _pumpAdmin(
  WidgetTester tester, {
  required _FakeAdminBackend backend,
  AuthSession session = const AuthSession(
    token: 'token',
    role: 'ADMIN',
    employeeId: 'ADMIN-1',
    fullName: 'Admin',
  ),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glowBackendServiceProvider.overrideWithValue(backend),
        authControllerProvider.overrideWith(
          (ref) => _ReadyAuthController(backend, session),
        ),
        servicesProvider.overrideWith((ref) async => backend.services),
        serviceOptionsProvider.overrideWith(
          (ref, serviceId) async => backend.options,
        ),
        allServicePackagesProvider
            .overrideWith((ref) async => backend.packages),
        employeesProvider.overrideWith((ref) async => backend.employees),
        customersProvider.overrideWith((ref) async => backend.customers),
        workingHoursProvider.overrideWith((ref) async => backend.workingHours),
        holidaysProvider.overrideWith((ref, query) async => backend.holidays),
      ],
      child: MaterialApp(
          theme: AppTheme.lightTheme, home: const AdminDashboardPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void _setWideViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 900);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
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
  final candidates =
      last ? matches.evaluate().toList().reversed : matches.evaluate().toList();
  for (final candidate in candidates) {
    final textFinder = find.byWidget(candidate.widget);
    final controls = [
      find.ancestor(of: textFinder, matching: find.byType(TextButton)),
      find.ancestor(of: textFinder, matching: find.byType(ElevatedButton)),
      find.ancestor(of: textFinder, matching: find.byType(OutlinedButton)),
      find.ancestor(of: textFinder, matching: find.byType(PopupMenuItem)),
    ];
    for (final control in controls) {
      if (control.evaluate().isNotEmpty) {
        await tester.ensureVisible(control.first);
        await tester.tap(control.first, warnIfMissed: false);
        return;
      }
    }
  }
  final finder = last ? matches.last : matches.first;
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
}

class _FakeAdminBackend extends GlowBackendService {
  _FakeAdminBackend({this.createServiceError})
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  final Object? createServiceError;
  int createServiceCount = 0;
  int deactivateServiceCount = 0;
  int updatePackageCount = 0;
  int deactivateEmployeeCount = 0;
  Map<String, dynamic>? createdEmployee;

  final services = const [
    {
      'serviceId': 1,
      'serviceName': 'Hydrafacial',
      'description': 'Cilt bakımı',
      'active': true,
    },
    {
      'serviceId': 2,
      'serviceName': 'hydrafacial',
      'description': 'Tekrarlanan katalog kaydı',
      'active': true,
    },
  ];

  final options = const [
    {
      'optionId': 11,
      'serviceId': 1,
      'optionName': 'Standart',
      'price': 900.0,
      'active': true,
    },
  ];

  final packages = const [
    {
      'packageId': 5,
      'serviceId': 1,
      'serviceName': 'Hydrafacial',
      'packageName': '6 Seans',
      'description': 'Paket',
      'totalSession': 6,
      'price': 4800.0,
      'active': true,
    },
  ];

  final employees = const [
    {
      'employeeId': 'EMP-1',
      'firstName': 'Elif',
      'lastName': 'Yılmaz',
      'phone': '5551112233',
      'email': 'elif@example.com',
      'active': true,
      'assignedServiceCount': 1,
      'assignedServices': [
        {
          'employeeServiceId': 1,
          'employeeId': 'EMP-1',
          'employeeName': 'Elif Yılmaz',
          'serviceId': 1,
          'serviceName': 'Hydrafacial',
          'optionId': null,
          'optionName': null,
        },
        {
          'employeeServiceId': 2,
          'employeeId': 'EMP-1',
          'employeeName': 'Elif Yılmaz',
          'serviceId': 2,
          'serviceName': 'hydrafacial',
          'optionId': null,
          'optionName': null,
        },
      ],
    },
  ];

  final customers = const [
    {
      'customerId': 1,
      'firstName': 'Derya',
      'lastName': 'Yılmaz',
      'phone': '5550001122',
      'email': 'derya@example.com',
      'active': true,
    },
  ];

  final workingHours = const [
    {
      'workingHourId': 1,
      'dayOfWeek': 'MONDAY',
      'startTime': '09:00:00',
      'endTime': '18:00:00',
      'closed': false,
    },
  ];

  final holidays = const [
    {
      'holidayId': 1,
      'holidayDate': '2026-08-30',
      'holidayName': 'Zafer Bayramı',
      'description': 'Resmi tatil',
    },
  ];

  @override
  Future<Map<String, dynamic>> createService(
      Map<String, dynamic> payload) async {
    createServiceCount++;
    if (createServiceError != null) throw createServiceError!;
    return {'serviceId': 2, ...payload};
  }

  @override
  Future<Map<String, dynamic>> deactivateService(int serviceId) async {
    deactivateServiceCount++;
    return services.first;
  }

  @override
  Future<Map<String, dynamic>> updatePackage(
    int packageId,
    Map<String, dynamic> payload,
  ) async {
    updatePackageCount++;
    return {'packageId': packageId, ...payload};
  }

  @override
  Future<Map<String, dynamic>> createEmployee(
      Map<String, dynamic> payload) async {
    createdEmployee = payload;
    return payload;
  }

  @override
  Future<Map<String, dynamic>> deactivateEmployee(String employeeId) async {
    deactivateEmployeeCount++;
    return {...employees.first, 'active': false};
  }
}

class _ReadyAuthController extends AuthController {
  _ReadyAuthController(super.backend, AuthSession session) {
    state = AsyncValue.data(session);
  }
}
