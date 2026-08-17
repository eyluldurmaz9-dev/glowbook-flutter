import 'service_image_resolver.dart';
import 'package_image_resolver.dart';

class CatalogService {
  const CatalogService({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.active,
  });

  final int? id;
  final String name;
  final String? description;
  final String? image;
  final bool? active;

  factory CatalogService.fromJson(Map<String, dynamic> json) {
    return CatalogService(
      id: _intValue(json['serviceId']),
      name: _cleanText(json['serviceName']) ?? 'Hizmet',
      description: _cleanText(json['description']),
      image: ServiceImageResolver.imageFor(
        _cleanText(json['serviceName']),
        serviceId: _intValue(json['serviceId']),
      ),
      active: _boolValue(json['active']),
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        (description?.toLowerCase().contains(normalized) ?? false);
  }
}

class CatalogOption {
  const CatalogOption({
    required this.id,
    required this.serviceId,
    required this.name,
    this.priceText,
    this.active,
  });

  final int? id;
  final int? serviceId;
  final String name;
  final String? priceText;
  final bool? active;

  factory CatalogOption.fromJson(Map<String, dynamic> json) {
    return CatalogOption(
      id: _intValue(json['optionId']),
      serviceId: _intValue(json['serviceId']),
      name: _cleanText(json['optionName']) ?? 'Alt hizmet',
      priceText: _priceText(json['price']),
      active: _boolValue(json['active']),
    );
  }
}

class CatalogPackage {
  const CatalogPackage({
    required this.id,
    required this.serviceId,
    required this.name,
    this.serviceName,
    this.description,
    this.totalSession,
    this.priceText,
    this.validityDays,
    this.image,
    this.active,
    this.coveredOptions = const [],
  });

  final int? id;
  final int? serviceId;
  final String name;
  final String? serviceName;
  final String? description;
  final int? totalSession;
  final String? priceText;
  final int? validityDays;
  final String? image;
  final bool? active;

  /// The sub-services this package may actually be booked for — the sole
  /// authority on what "Bu paketle randevu al" may offer. A package whose
  /// name mentions one treatment (e.g. Hydrafacial) must never let the
  /// customer pick a sibling sub-service (e.g. Akne Bakımı) under the same
  /// broad service just because the backend's [serviceId] matches.
  final List<CatalogOption> coveredOptions;

  factory CatalogPackage.fromJson(Map<String, dynamic> json) {
    return CatalogPackage(
      id: _intValue(json['packageId']),
      serviceId: _intValue(json['serviceId']),
      name: _cleanText(json['packageName']) ?? 'Paket',
      serviceName: _cleanText(json['serviceName']),
      description: _cleanText(json['description']),
      totalSession: _intValue(json['totalSession']),
      priceText: _priceText(json['price']),
      validityDays: _intValue(json['validityDays']),
      image: PackageImageResolver.imageFor(
        packageId: _intValue(json['packageId']),
        packageName: _cleanText(json['packageName']),
        serviceName: _cleanText(json['serviceName']),
      ),
      active: _boolValue(json['active']),
      coveredOptions: ((json['coveredOptions'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => CatalogOption.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        (serviceName?.toLowerCase().contains(normalized) ?? false) ||
        (description?.toLowerCase().contains(normalized) ?? false);
  }
}

List<CatalogService> mapCatalogServices(List<Map<String, dynamic>> items) {
  final unique = <String, CatalogService>{};
  for (final item in items.map(CatalogService.fromJson)) {
    unique.putIfAbsent(_canonicalCatalogName(item.name), () => item);
  }
  return unique.values.toList(growable: false);
}

String _canonicalCatalogName(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

List<CatalogOption> mapCatalogOptions(List<Map<String, dynamic>> items) {
  return items.map(CatalogOption.fromJson).toList(growable: false);
}

List<CatalogPackage> mapCatalogPackages(List<Map<String, dynamic>> items) {
  return items.map(CatalogPackage.fromJson).toList(growable: false);
}

String? _cleanText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _priceText(Object? value) {
  if (value == null) return null;
  return _cleanText(value);
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
