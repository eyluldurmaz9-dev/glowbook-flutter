import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static regression guard for Defect 2: searches every source file under
/// lib/ for the removed "Paketinle devam et" continuation dialog (or its
/// body copy), so the dialog cannot silently come back through a new or
/// duplicated code path without this test catching it — independent of
/// whichever specific screen a future change might route through.
void main() {
  test('kaynak kodda "Paketinle devam et" ara onay modalına dair iz kalmamış',
      () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ klasörü bulunamadı');

    // Note: the wizard keeps a legitimate, non-blocking inline banner
    // ("_PackageContextBanner") that also says the service won't be asked
    // again — that one never requires a tap to proceed, so it is not part
    // of what was removed. Only the modal's own title and its "up next"
    // sentence identify the dialog specifically.
    const bannedPhrases = [
      'Paketinle devam et',
      'Sırada personel, tarih ve saat seçimi var',
    ];

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      for (final phrase in bannedPhrases) {
        if (content.contains(phrase)) {
          offenders.add('${entity.path}: "$phrase"');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Kaldırılan paket devam modalına ait metin(ler) hâlâ mevcut:\n'
          '${offenders.join('\n')}',
    );
  });

  test('paket detay sayfasında showDialog tabanlı bir devam onayı yok', () {
    final file = File('lib/features/package/package_detail_page.dart');
    expect(file.existsSync(), isTrue);
    final content = file.readAsStringSync();

    // The purchase confirmation for buying a package outright is a separate,
    // legitimate flow and is out of scope here; this file's continuation
    // path ("Bu paketle randevu al") specifically must not show any dialog
    // before navigating into the wizard.
    expect(content.contains('showDialog'), isFalse,
        reason:
            'package_detail_page.dart artık hiçbir showDialog çağrısı içermemeli');
  });
}
