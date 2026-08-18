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

/// True when a still-PENDING/APPROVED appointment's date/time has already
/// passed. The backend deliberately keeps time-based classification (used
/// for Yaklaşan/Geçmiş bucketing, and for package session accounting —
/// AppointmentTimeClassifier.hasStarted) separate from the persisted status
/// column, which only staff action (approve/complete/cancel) ever changes.
/// Admin/employee screens still need to *show* a past, uncancelled
/// appointment as completed, so this mirrors that same time rule purely for
/// display — it never writes anything back, so it can't double-count or
/// conflict with the backend's own status transitions.
bool appointmentIsPastDue(Map<String, dynamic> appointment) {
  final status = appointment['status']?.toString().toUpperCase();
  if (status != 'PENDING' && status != 'APPROVED') return false;
  final date = BookingDateUtils.parseDate(appointment['appointmentDate']);
  final time = BookingDateUtils.normalizeTime(appointment['appointmentTime']);
  if (date == null || time == null) return false;
  final parts = time.split(':');
  final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '');
  if (hour == null) return false;
  final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  final start = DateTime(date.year, date.month, date.day, hour, minute);
  return !start.isAfter(DateTime.now());
}

String employeeAppointmentStatusLabel(Map<String, dynamic> appointment) {
  final status = appointment['status']?.toString().toUpperCase();
  if (status == 'CANCELLED') return 'İptal edildi';
  if (status == 'COMPLETED') return 'Tamamlandı';
  if (appointmentIsPastDue(appointment)) return 'Tamamlandı';
  switch (status) {
    case 'PENDING':
      return 'Onay bekliyor';
    case 'APPROVED':
      return 'Onaylandı';
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
