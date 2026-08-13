import 'service_image_resolver.dart';

class PackageImageResolver {
  PackageImageResolver._();

  static const laserThreeRegion =
      'assets/images/packages/package-laser-3-region.png';
  static const laserFiveRegion =
      'assets/images/packages/package-laser-5-region.png';
  static const laserFullBody =
      'assets/images/packages/package-laser-full-body.png';
  static const skinHydrafacial =
      'assets/images/packages/package-skin-hydrafacial.png';
  static const skinAntiAging =
      'assets/images/packages/package-skin-anti-aging.png';
  static const skinMedical = 'assets/images/packages/package-skin-medical.png';

  static const approved = <String>{
    laserThreeRegion,
    laserFiveRegion,
    laserFullBody,
    skinHydrafacial,
    skinAntiAging,
    skinMedical,
  };

  static String imageFor({
    int? packageId,
    String? packageName,
    String? serviceName,
  }) {
    final name = _normalize(packageName);
    final service = _normalize(serviceName);

    if (_containsAny(name, const ['3 bolge', 'uc bolge'])) {
      return laserThreeRegion;
    }
    if (_containsAny(name, const ['5 bolge', 'bes bolge'])) {
      return laserFiveRegion;
    }
    if (_containsAny(name, const ['tum vucut', 'full body'])) {
      return laserFullBody;
    }
    if (_containsAny(name, const ['hydrafacial', 'hydrofacial', 'glow cilt'])) {
      return skinHydrafacial;
    }
    if (_containsAny(name, const ['anti aging', 'antiaging', 'genclik'])) {
      return skinAntiAging;
    }
    if (_containsAny(name, const ['medikal', 'akne', 'leke'])) {
      return skinMedical;
    }

    if (service.contains('lazer')) {
      if (packageId == 1) return laserThreeRegion;
      if (packageId == 2) return laserFiveRegion;
      return laserFullBody;
    }
    if (service.contains('cilt')) {
      if (packageId == 4) return skinHydrafacial;
      if (packageId == 5) return skinAntiAging;
      return skinMedical;
    }
    return ServiceImageResolver.imageFor(serviceName);
  }

  static bool _containsAny(String value, List<String> candidates) =>
      candidates.any(value.contains);

  static String _normalize(String? value) => (value ?? '')
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
}
