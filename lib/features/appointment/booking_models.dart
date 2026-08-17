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
          .where(BookingDateUtils.isFullHour)
          .toList(growable: false),
    );
  }

  bool hasTime(String time) => availableTimes.contains(time);
}

/// One owned package with the session numbers the backend derived.
///
/// `used` counts sessions whose appointment time has already passed, `scheduled`
/// counts appointments still ahead, and `remaining` is what may still be booked.
/// A future appointment is therefore never reported as already used.
class CustomerPackageOption {
  const CustomerPackageOption({
    required this.customerPackageId,
    required this.packageId,
    required this.name,
    this.serviceId,
    this.serviceName,
    this.remainingSession,
    this.totalSession,
    this.usedSessionCount,
    this.scheduledSession,
    this.validUntil,
    this.active,
    this.coveredOptions = const [],
  });

  final int? customerPackageId;
  final int? packageId;
  final String name;
  final int? serviceId;
  final String? serviceName;
  final int? remainingSession;
  final int? totalSession;
  final int? usedSessionCount;
  final int? scheduledSession;
  final String? validUntil;
  final bool? active;

  /// The sub-services this owned package may actually be booked for — same
  /// authority as [CatalogPackage.coveredOptions], carried onto the
  /// customer's own copy so "Paketlerim" can route into the same
  /// package-scoped booking logic as a fresh purchase.
  final List<CatalogOption> coveredOptions;

  factory CustomerPackageOption.fromJson(Map<String, dynamic> json) {
    return CustomerPackageOption(
      customerPackageId: _intValue(json['customerPackageId']),
      packageId: _intValue(json['packageId']),
      name: _cleanText(json['packageName']) ?? 'Paket',
      serviceId: _intValue(json['serviceId']),
      serviceName: _cleanText(json['serviceName']),
      remainingSession: _intValue(json['remainingSession']),
      totalSession: _intValue(json['totalSession']),
      usedSessionCount: _intValue(json['usedSession']),
      scheduledSession: _intValue(json['scheduledSession']),
      validUntil: _cleanText(json['validUntil']),
      active: _boolValue(json['active']),
      coveredOptions: ((json['coveredOptions'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => CatalogOption.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  /// Falls back to `total - remaining` only when the backend did not send the
  /// derived value, so older responses still render something sensible.
  int? get usedSession {
    if (usedSessionCount != null) return usedSessionCount;
    if (totalSession == null || remainingSession == null) return null;
    final scheduled = scheduledSession ?? 0;
    return totalSession! - remainingSession! - scheduled;
  }

  bool canUseFor(List<CatalogPackage> servicePackages) {
    if (active == false ||
        customerPackageId == null ||
        packageId == null ||
        (remainingSession ?? 0) <= 0) {
      return false;
    }
    return servicePackages.any((item) => item.id == packageId);
  }
}

/// Selections the customer already made before entering the booking wizard.
///
/// When a package carries this context the wizard must not ask for the service
/// again: the package fixes it. Only [optionId] may still be missing, and only
/// when the package covers more than one sub-service.
class PackageBookingContext {
  const PackageBookingContext({
    required this.packageId,
    required this.serviceId,
    this.optionId,
    this.customerPackageId,
    this.packageName,
    this.serviceName,
    this.totalSession,
    this.coveredOptionIds = const [],
  });

  final int packageId;
  final int serviceId;
  final int? optionId;
  final int? customerPackageId;
  final String? packageName;
  final String? serviceName;
  final int? totalSession;

  /// IDs of every sub-service this package actually covers (see
  /// [CatalogPackage.coveredOptions]) — the wizard's option step, when it is
  /// shown at all, must never offer anything outside this list. Carried
  /// through the URL (see [toQuery]/[fromQuery]) so it survives Back/Forward
  /// and a page refresh exactly like every other package selection.
  final List<int> coveredOptionIds;

  /// True when the package still has to be bought as part of this booking.
  bool get needsPurchase => customerPackageId == null;

  bool get hasKnownOption => optionId != null;

  PackageBookingContext withOption(int optionId) => PackageBookingContext(
        packageId: packageId,
        serviceId: serviceId,
        optionId: optionId,
        customerPackageId: customerPackageId,
        packageName: packageName,
        serviceName: serviceName,
        totalSession: totalSession,
        coveredOptionIds: coveredOptionIds,
      );

  static PackageBookingContext? fromQuery(Map<String, String> query) {
    final packageId = int.tryParse(query['packageId'] ?? '');
    final serviceId = int.tryParse(query['serviceId'] ?? '');
    if (packageId == null || serviceId == null) return null;
    return PackageBookingContext(
      packageId: packageId,
      serviceId: serviceId,
      optionId: int.tryParse(query['optionId'] ?? ''),
      customerPackageId: int.tryParse(query['customerPackageId'] ?? ''),
      packageName: _cleanText(query['packageName']),
      serviceName: _cleanText(query['serviceName']),
      totalSession: int.tryParse(query['totalSession'] ?? ''),
      coveredOptionIds: (query['coveredOptionIds'] ?? '')
          .split(',')
          .map((item) => int.tryParse(item.trim()))
          .whereType<int>()
          .toList(growable: false),
    );
  }

  Map<String, String> toQuery() => {
        'packageId': '$packageId',
        'serviceId': '$serviceId',
        if (optionId != null) 'optionId': '$optionId',
        if (customerPackageId != null)
          'customerPackageId': '$customerPackageId',
        if (packageName != null) 'packageName': packageName!,
        if (serviceName != null) 'serviceName': serviceName!,
        if (totalSession != null) 'totalSession': '$totalSession',
        if (coveredOptionIds.isNotEmpty)
          'coveredOptionIds': coveredOptionIds.join(','),
      };

  String toRoute(String basePath) {
    final query = toQuery()
        .entries
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
    return '$basePath?$query';
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

  static bool isFullHour(String value) {
    final parts = value.split(':');
    return parts.length >= 2 && int.tryParse(parts[1]) == 0;
  }

  static bool isFutureFullHourSlot(
    DateTime date,
    String time, {
    DateTime? now,
  }) {
    if (!isFullHour(time)) return false;
    final parts = time.split(':');
    final hour = int.tryParse(parts.first);
    if (hour == null || hour < 0 || hour > 23) return false;
    final current = now ?? DateTime.now();
    final start = DateTime(date.year, date.month, date.day, hour);
    return start.isAfter(current);
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
    return 'Bu saat artık uygun değil. Lütfen başka bir saat seç.';
  }
  if (message.contains('Geçmiş bir tarih') ||
      message.toLowerCase().contains('past date')) {
    return 'Geçmiş bir tarih için randevu oluşturamazsın.';
  }
  if (message.contains('geçmişte kaldı') ||
      message.toLowerCase().contains('past time')) {
    return 'Bu saat artık geçmişte kaldı. Lütfen başka bir saat seç.';
  }
  if (message.toLowerCase().contains('connection') ||
      message.toLowerCase().contains('ulaşılamadı')) {
    return 'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.';
  }
  return message;
}

bool isStaleSlotError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('occupied') || message.contains('not available');
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
