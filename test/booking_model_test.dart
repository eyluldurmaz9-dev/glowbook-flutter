import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/features/appointment/booking_models.dart';
import 'package:glowbook_flutter/features/catalog/catalog_models.dart';

void main() {
  test('Tarih formatı local gün değerini ISO tarih olarak üretir', () {
    final date = DateTime(2026, 7, 31, 22, 45);

    expect(BookingDateUtils.formatDate(date), '2026-07-31');
  });

  test('Saat dönüşümü saniyeyi kırpar ve çift haneli saat üretir', () {
    expect(BookingDateUtils.normalizeTime('9:05:00'), '09:05');
    expect(BookingDateUtils.normalizeTime('14:30'), '14:30');
  });

  test('Available slot response güvenli modele eşlenir', () {
    final slots = mapBookingSlots([
      {
        'employeeId': 'EMP-1',
        'employeeName': 'Elif Yılmaz',
        'appointmentDate': '2026-08-01',
        'availableTimes': ['09:00:00', '10:30'],
      },
    ]);

    expect(slots.single.employeeId, 'EMP-1');
    expect(slots.single.availableTimes, ['09:00']);
  });

  test(
      'Customer package yalnızca seçili hizmet paketleriyle eşleşirse kullanılır',
      () {
    final customerPackage = CustomerPackageOption.fromJson({
      'customerPackageId': 8,
      'packageId': 4,
      'packageName': '6 Seans',
      'remainingSession': 2,
      'active': true,
    });
    const servicePackages = [
      CatalogPackage(id: 4, serviceId: 1, name: '6 Seans'),
    ];

    expect(customerPackage.canUseFor(servicePackages), isTrue);
  });

  test('Backend hata mesajı güvenli Türkçe metne dönüştürülür', () {
    expect(
      bookingErrorMessage(Exception('Selected slot is not available')),
      'Seçilen saat az önce doldu. Lütfen başka bir saat seç.',
    );
    expect(
      bookingErrorMessage(Exception('Backend sunucusuna ulaşılamadı.')),
      'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.',
    );
  });
}
