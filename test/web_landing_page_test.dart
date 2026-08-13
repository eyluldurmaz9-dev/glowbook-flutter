import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/web/web_landing_page.dart';

void main() {
  testWidgets('Web açılış sayfası temel bölümleri ve resmî logoyu gösterir',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const WebLandingPage(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ana Sayfa'), findsOneWidget);
    expect(find.text('Hakkımızda'), findsOneWidget);
    expect(find.text('Hizmetler'), findsOneWidget);
    expect(find.text('Paketler'), findsOneWidget);
    expect(find.text('Randevu Al'), findsWidgets);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage)
              .assetName
              .contains('branding/glowbook-official-logo.png')),
      findsWidgets,
    );
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
