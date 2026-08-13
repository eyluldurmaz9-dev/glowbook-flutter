import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

List<int> pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  expect(bytes.length, greaterThan(24), reason: path);
  expect(bytes.sublist(1, 4), <int>[80, 78, 71], reason: path);
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  return <int>[data.getUint32(16), data.getUint32(20)];
}

void main() {
  test('web favicon and PWA icons use the platform mark resources', () {
    final expected = <String, List<int>>{
      'web/favicon.png': <int>[64, 64],
      'web/icons/Icon-192.png': <int>[192, 192],
      'web/icons/Icon-512.png': <int>[512, 512],
      'web/icons/Icon-maskable-192.png': <int>[192, 192],
      'web/icons/Icon-maskable-512.png': <int>[512, 512],
    };
    for (final entry in expected.entries) {
      final size = pngSize(entry.key);
      expect(size, entry.value, reason: entry.key);
    }

    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('favicon.png?v=20260813'));
    expect(html, contains('Icon-192.png?v=20260813'));

    final manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    final icons = manifest['icons'] as List<dynamic>;
    expect(
        icons.map((icon) => icon['src']),
        containsAll(expected.keys
            .skip(1)
            .map((path) => path.replaceFirst('web/', ''))));
    expect(icons.where((icon) => icon['purpose'] == 'maskable').length, 2);
  });

  test('Android launcher has legacy, round, and adaptive resources', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher_round"'));

    for (final density in <String, int>{
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      for (final name in ['ic_launcher.png', 'ic_launcher_round.png']) {
        final path = 'android/app/src/main/res/mipmap-${density.key}/$name';
        final size = pngSize(path);
        expect(size, <int>[density.value, density.value], reason: path);
      }
    }

    for (final name in ['ic_launcher.xml', 'ic_launcher_round.xml']) {
      final xml = File('android/app/src/main/res/mipmap-anydpi-v26/$name')
          .readAsStringSync();
      expect(xml, contains('@drawable/ic_launcher_foreground'));
      expect(xml, contains('@color/ic_launcher_background'));
    }
  });

  test('all configured iOS AppIcon files exist at their declared dimensions',
      () {
    const root = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final contents = jsonDecode(File('$root/Contents.json').readAsStringSync())
        as Map<String, dynamic>;
    for (final image in contents['images'] as List<dynamic>) {
      final filename = image['filename'] as String;
      final logicalSize =
          double.parse((image['size'] as String).split('x').first);
      final scale = int.parse((image['scale'] as String).replaceFirst('x', ''));
      final pixels = (logicalSize * scale).round();
      final size = pngSize('$root/$filename');
      expect(size, <int>[pixels, pixels], reason: filename);
    }
  });

  test(
      'platform icon is not used as service, package, employee, or customer content',
      () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in dartFiles) {
      expect(file.readAsStringSync(),
          isNot(contains('glowbook-platform-icon.png')),
          reason: file.path);
    }
  });
}
