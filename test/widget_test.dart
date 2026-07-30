import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:glowbook_flutter/app.dart';

void main() {
  testWidgets('GlowBook app renders welcome route',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GlowBookApp()));

    await tester.pump();

    expect(find.text('GlowBook'), findsWidgets);
  });
}
