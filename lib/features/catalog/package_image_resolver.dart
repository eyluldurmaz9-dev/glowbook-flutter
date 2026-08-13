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

  static const _assetByProductionPackageId = <int, String>{
    1: skinAntiAging,
    2: laserThreeRegion,
    3: GlowBookAssets.spa,
    4: GlowBookAssets.bodyTreatment,
    5: skinHydrafacial,
    6: laserFiveRegion,
    7: laserFullBody,
    8: laserThreeRegion,
    9: GlowBookAssets.lashes,
    10: GlowBookAssets.bodyTreatment,
    11: GlowBookAssets.nails,
    12: GlowBookAssets.nails,
    13: GlowBookAssets.lashes,
    14: GlowBookAssets.bodyTreatment,
    15: GlowBookAssets.bodyTreatment,
  };

  static String imageFor({
    int? packageId,
    String? packageName,
    String? serviceName,
  }) {
    final idAsset =
        packageId == null ? null : _assetByProductionPackageId[packageId];
    if (idAsset != null) return idAsset;

    final name = _normalize(packageName);
    final service = _normalize(serviceName);
    if (_containsAny(
        name, const ['3 bolge', 'uc bolge', 'yuz bolgesi', 'lazer devam'])) {
      return laserThreeRegion;
    }
    if (_containsAny(name, const ['5 bolge', 'bes bolge'])) {
      return laserFiveRegion;
    }
    if (_containsAny(name, const ['tum vucut', 'full body'])) {
      return laserFullBody;
    }
    if (_containsAny(name, const ['hydrafacial', 'hydrofacial'])) {
      return skinHydrafacial;
    }
    if (_containsAny(
        name, const ['anti aging', 'antiaging', 'genclik', 'glow cilt'])) {
      return skinAntiAging;
    }
    if (_containsAny(name, const ['medikal', 'akne', 'leke'])) {
      return skinMedical;
    }
    if (_containsAny(name, const ['spa', 'masaj'])) {
      return GlowBookAssets.spa;
    }
    if (_containsAny(name, const ['incelme', 'sikilasma', 'selulit'])) {
      return GlowBookAssets.bodyTreatment;
    }
    if (_containsAny(
        name, const ['tirnak', 'oje', 'nail', 'manikur', 'pedikur'])) {
      return GlowBookAssets.nails;
    }
    if (_containsAny(name, const ['kas', 'kirpik', 'lifting'])) {
      return GlowBookAssets.lashes;
    }

    if (service.contains('lazer')) {
      return laserThreeRegion;
    }
    if (service.contains('cilt')) {
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
