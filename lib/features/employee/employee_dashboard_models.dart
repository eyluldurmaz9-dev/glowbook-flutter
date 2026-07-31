import '../appointment/booking_models.dart';

class EmployeeWeekRange {
  const EmployeeWeekRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory EmployeeWeekRange.from(DateTime selectedDate) {
    final normalized = BookingDateUtils.normalize(selectedDate);
    final start = normalized.subtract(Duration(days: normalized.weekday - 1));
    return EmployeeWeekRange(
        start: start, end: start.add(const Duration(days: 6)));
  }

  String get startText => BookingDateUtils.formatDate(start);
  String get endText => BookingDateUtils.formatDate(end);

  List<DateTime> get days => List.generate(
        7,
        (index) => start.add(Duration(days: index)),
        growable: false,
      );
}

List<Map<String, dynamic>> employeeAppointmentsForDate(
  List<Map<String, dynamic>> appointments,
  DateTime date,
) {
  final target = BookingDateUtils.formatDate(date);
  return appointments
      .where((item) => item['appointmentDate']?.toString() == target)
      .toList(growable: false);
}

String employeeAppointmentStatusLabel(Object? status) {
  switch (status?.toString().toUpperCase()) {
    case 'PENDING':
      return 'Onay bekliyor';
    case 'APPROVED':
      return 'Onaylandı';
    case 'COMPLETED':
      return 'Tamamlandı';
    case 'CANCELLED':
      return 'İptal edildi';
    default:
      return 'Durum bilinmiyor';
  }
}

String employeeAppointmentSafeError(Object error) {
  final mapped = bookingErrorMessage(error);
  if (mapped == null || mapped.trim().isEmpty) {
    return 'İşlem tamamlanamadı. Lütfen tekrar dene.';
  }
  if (mapped.contains('Exception:')) {
    return mapped.replaceFirst('Exception:', '').trim();
  }
  return mapped;
}
