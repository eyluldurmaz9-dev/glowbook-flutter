import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/web/web_landing_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Public landing auth olmadan gerçek katalog verisini gösterir',
      (tester) async {
    await _pumpLanding(tester, const Size(1440, 900));

    expect(find.text('Güzelliği planlamanın en kolay yolu.'), findsOneWidget);
    expect(find.text('Hakkımızda'), findsWidgets);
    expect(find.text('Hizmetler'), findsWidgets);
    expect(find.text('Paketler'), findsWidgets);
    expect(find.text('Randevu Al'), findsWidgets);
    expect(find.text('İletişim'), findsWidgets);
    expect(find.text('Giriş Yap'), findsWidgets);
    expect(find.byKey(const Key('web_nav_Paketler')), findsNothing);
    expect(find.text('Gerçek Cilt Bakımı'), findsOneWidget);
    expect(find.text('Hydrafacial Premium'), findsOneWidget);
    expect(find.textContaining('6 seans'), findsOneWidget);
    expect(find.textContaining('365 gün geçerli'), findsOneWidget);
  });

  testWidgets('Masaüstü navigasyonu ilgili bölüme kaydırır', (tester) async {
    await _pumpLanding(tester, const Size(1366, 768));
    final scrollable = find.byType(Scrollable).first;
    final before = tester.state<ScrollableState>(scrollable).position.pixels;

    await tester.tap(find.byKey(const Key('web_nav_İletişim')));
    await tester.pumpAndSettle();

    expect(tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(before));
    expect(find.text('Bize ulaşın'), findsOneWidget);
  });

  testWidgets(
      'Hizmetler menüsü Tüm Hizmetler ve Paketler alt eylemlerini sunar',
      (tester) async {
    await _pumpLanding(tester, const Size(1440, 900));

    await tester.tap(find.byKey(const Key('web_services_menu')));
    await tester.pumpAndSettle();

    expect(find.text('Tüm Hizmetler'), findsOneWidget);
    expect(find.text('Paketler'), findsWidgets);
    await tester.tap(find.text('Paketler').last);
    await tester.pumpAndSettle();
    expect(find.text('Hydrafacial Premium'), findsOneWidget);
  });

  testWidgets('Dar web görünümü taşmadan mobil menü kullanır', (tester) async {
    await _pumpLanding(tester, const Size(390, 844));

    expect(find.byKey(const Key('web_mobile_menu')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dar public web menüsünde bağımsız Paketler öğesi yoktur',
      (tester) async {
    await _pumpLanding(tester, const Size(390, 844));

    await tester.tap(find.byKey(const Key('web_mobile_menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('web_mobile_nav_Paketler')), findsNothing);
    expect(find.byKey(const Key('web_mobile_nav_Hizmetler')), findsOneWidget);
    expect(find.byKey(const Key('web_mobile_nav_Randevu Al')), findsOneWidget);
  });
  testWidgets('Giriş Yap login rotasını açar', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(path: '/', builder: (_, __) => const WebLandingPage()),
      GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('LOGIN_ROUTE'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: _catalogOverrides(),
      child:
          MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('web_login')));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN_ROUTE'), findsOneWidget);
  });
}

Future<void> _pumpLanding(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(ProviderScope(
    overrides: _catalogOverrides(),
    child:
        MaterialApp(theme: AppTheme.lightTheme, home: const WebLandingPage()),
  ));
  await tester.pumpAndSettle();
}

List<Override> _catalogOverrides() => [
      servicesProvider.overrideWith((ref) async => const [
            {
              'serviceId': 1,
              'serviceName': 'Gerçek Cilt Bakımı',
              'description': 'Canlandırıcı bakım',
              'active': true,
            },
            {
              'serviceId': 2,
              'serviceName': 'Pasif Hizmet',
              'active': false,
            },
          ]),
      allServicePackagesProvider.overrideWith((ref) async => const [
            {
              'packageId': 4,
              'serviceId': 1,
              'serviceName': 'Cilt Bakımı',
              'packageName': 'Hydrafacial Premium',
              'description': 'Düzenli bakım paketi',
              'totalSession': 6,
              'price': 4800,
              'validityDays': 365,
              'active': true,
            },
          ]),
    ];
