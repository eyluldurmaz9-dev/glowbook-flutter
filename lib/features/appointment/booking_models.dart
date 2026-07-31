import '../catalog/catalog_models.dart';

class BookingSlot {
  const BookingSlot({
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.availableTimes,
  });

  final String employeeId;
  final String employeeName;
  final DateTime date;
  final List<String> availableTimes;

  factory BookingSlot.fromJson(Map<String, dynamic> json) {
    return BookingSlot(
      employeeId: _cleanText(json['employeeId']) ?? '',
      employeeName: _cleanText(json['employeeName']) ?? 'Personel',
      date: BookingDateUtils.parseDate(json['appointmentDate']) ??
          BookingDateUtils.today(),
      availableTimes: (json['availableTimes'] as List? ?? const [])
          .map((item) => BookingDateUtils.normalizeTime(item))
          .whereType<String>()
          .toList(growable: false),
    );
  }

  bool hasTime(String time) => availableTimes.contains(time);
}

class CustomerPackageOption {
  const CustomerPackageOption({
    required this.customerPackageId,
    required this.packageId,
    required this.name,
    this.remainingSession,
    this.active,
  });

  final int? customerPackageId;
  final int? packageId;
  final String name;
  final int? remainingSession;
  final bool? active;

  factory CustomerPackageOption.fromJson(Map<String, dynamic> json) {
    return CustomerPackageOption(
      customerPackageId: _intValue(json['customerPackageId']),
      packageId: _intValue(json['packageId']),
      name: _cleanText(json['packageName']) ?? 'Paket',
      remainingSession: _intValue(json['remainingSession']),
      active: _boolValue(json['active']),
    );
  }

  bool canUseFor(List<CatalogPackage> servicePackages) {
    if (active == false || customerPackageId == null || packageId == null) {
      return false;
    }
    return servicePackages.any((item) => item.id == packageId);
  }
}

class BookingResult {
  const BookingResult({
    this.appointmentId,
    this.waitingListId,
    this.serviceName,
    this.optionName,
    this.employeeName,
    this.date,
    this.time,
    this.price,
    this.status,
    this.waitingList = false,
  });

  final int? appointmentId;
  final int? waitingListId;
  final String? serviceName;
  final String? optionName;
  final String? employeeName;
  final String? date;
  final String? time;
  final String? price;
  final String? status;
  final bool waitingList;

  factory BookingResult.appointment(Map<String, dynamic> json) {
    return BookingResult(
      appointmentId: _intValue(json['appointmentId']),
      serviceName: _cleanText(json['serviceName']),
      optionName: _cleanText(json['optionName']),
      employeeName: _cleanText(json['employeeName']),
      date: _cleanText(json['appointmentDate']),
      time: BookingDateUtils.normalizeTime(json['appointmentTime']),
      price: _cleanText(json['price']),
      status: _cleanText(json['status']),
    );
  }

  factory BookingResult.waitingList(Map<String, dynamic> json) {
    return BookingResult(
      waitingListId: _intValue(json['waitingListId']),
      serviceName: _cleanText(json['serviceName']),
      optionName: _cleanText(json['optionName']),
      date: _cleanText(json['preferredDate']),
      time: BookingDateUtils.normalizeTime(json['preferredStartTime']),
      status: _cleanText(json['status']),
      waitingList: true,
    );
  }
}

class BookingDateUtils {
  BookingDateUtils._();

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isPast(DateTime date) => normalize(date).isBefore(today());

  static String formatDate(DateTime date) {
    final normalized = normalize(date);
    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }

  static DateTime? parseDate(Object? value) {
    final text = _cleanText(value);
    if (text == null) return null;
    final parsed = DateTime.tryParse(text);
    return parsed == null ? null : normalize(parsed);
  }

  static String? normalizeTime(Object? value) {
    final text = _cleanText(value);
    if (text == null) return null;
    final parts = text.split(':');
    if (parts.length < 2) return text;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return text;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  static String dayLabel(DateTime date) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[date.weekday - 1];
  }
}

List<BookingSlot> mapBookingSlots(List<Map<String, dynamic>> items) {
  return items.map(BookingSlot.fromJson).toList(growable: false);
}

List<CustomerPackageOption> mapCustomerPackageOptions(
  List<Map<String, dynamic>> items,
) {
  return items.map(CustomerPackageOption.fromJson).toList(growable: false);
}

String? bookingErrorMessage(Object error) {
  final message = error.toString();
  if (message.contains('401') ||
      message.toLowerCase().contains('unauthorized')) {
    return 'Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap.';
  }
  if (message.toLowerCase().contains('occupied') ||
      message.toLowerCase().contains('not available')) {
    return 'Seçilen saat az önce doldu. Lütfen başka bir saat seç.';
  }
  if (message.toLowerCase().contains('connection') ||
      message.toLowerCase().contains('ulaşılamadı')) {
    return 'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.';
  }
  return message;
}

String? _cleanText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty || text == 'null' ? null : text;
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool? _boolValue(Object? value) {
  if (value is bool) return value;
  if (value == null) return null;
  final text = value.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return null;
}
