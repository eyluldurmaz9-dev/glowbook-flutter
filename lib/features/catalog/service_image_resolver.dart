class GlowBookAssets {
  GlowBookAssets._();

  static const hero = 'assets/images/glowbook-hero.jpg';
  static const hydrafacial = 'assets/images/glowbook-hydrafacial.jpg';
  static const lashes = 'assets/images/glowbook-lashes.jpg';
  static const nails = 'assets/images/glowbook-nails.jpg';
  static const laser = 'assets/images/glowbook-laser.png';
  static const spa = 'assets/images/glowbook-spa.png';
  static const bodyTreatment = 'assets/images/glowbook-body-treatment.png';
  static const hair = 'assets/images/glowbook-hair.png';
  static const makeup = 'assets/images/glowbook-makeup.png';
  static const portraitDerya = 'assets/images/glowbook-portrait-derya.jpg';
  static const portraitElif = 'assets/images/glowbook-portrait-elif.jpg';

  static const approved = <String>{
    hero,
    hydrafacial,
    lashes,
    nails,
    laser,
    spa,
    bodyTreatment,
    hair,
    makeup,
    portraitDerya,
    portraitElif,
  };
}

class ServiceImageResolution {
  const ServiceImageResolution({
    required this.asset,
    required this.subject,
    required this.neutralFallback,
  });

  final String asset;
  final String subject;
  final bool neutralFallback;
}

class ServiceImageResolver {
  ServiceImageResolver._();

  static const knownServices = <String>[
    'Cilt Bakımı',
    'Lazer Epilasyon',
    'Masaj ve Spa',
    'Kaş ve Kirpik',
    'Bölgesel İncelme',
    'Tırnak',
    'Saç',
    'Makyaj',
  ];

  static const _assetByServiceId = <int, String>{
    1: GlowBookAssets.hydrafacial,
    2: GlowBookAssets.laser,
    3: GlowBookAssets.spa,
    4: GlowBookAssets.lashes,
    5: GlowBookAssets.bodyTreatment,
    6: GlowBookAssets.nails,
    7: GlowBookAssets.lashes,
    8: GlowBookAssets.bodyTreatment,
  };

  static ServiceImageResolution resolve(
    String? serviceName, {
    int? serviceId,
  }) {
    final idAsset = serviceId == null ? null : _assetByServiceId[serviceId];
    if (idAsset != null) return _resolutionFor(idAsset);

    final value = _normalize(serviceName);
    if (_containsAny(
        value, const ['cilt', 'hydrafacial', 'anti aging', 'leke', 'akne'])) {
      return _resolutionFor(GlowBookAssets.hydrafacial);
    }
    if (_containsAny(value, const ['lazer', 'epilasyon'])) {
      return _resolutionFor(GlowBookAssets.laser);
    }
    if (_containsAny(value, const ['masaj', 'spa', 'aromaterapi'])) {
      return _resolutionFor(GlowBookAssets.spa);
    }
    if (_containsAny(
        value, const ['kas', 'kirpik', 'lifting', 'ipek kirpik'])) {
      return _resolutionFor(GlowBookAssets.lashes);
    }
    if (_containsAny(value, const [
      'tirnak',
      'manikur',
      'pedikur',
      'kalici oje',
      'nail art',
      'protez'
    ])) {
      return _resolutionFor(GlowBookAssets.nails);
    }
    if (_containsAny(
        value, const ['bolgesel', 'incelme', 'sikilasma', 'selulit', 'body'])) {
      return _resolutionFor(GlowBookAssets.bodyTreatment);
    }
    if (_containsAny(
        value, const ['sac', 'kuafor', 'fön', 'fon', 'kesim', 'boya'])) {
      return _resolutionFor(GlowBookAssets.hair);
    }
    if (_containsAny(value, const ['makyaj', 'makeup'])) {
      return _resolutionFor(GlowBookAssets.makeup);
    }
    return const ServiceImageResolution(
      asset: GlowBookAssets.hero,
      subject:
          'GlowBook salon iç mekânı — yalnızca bilinmeyen kategori fallback',
      neutralFallback: true,
    );
  }

  static String imageFor(String? serviceName, {int? serviceId}) =>
      resolve(serviceName, serviceId: serviceId).asset;

  static ServiceImageResolution _resolutionFor(String asset) {
    const subjects = <String, String>{
      GlowBookAssets.hydrafacial: 'Hydrafacial ve yüz cilt bakımı',
      GlowBookAssets.laser: 'Profesyonel lazer epilasyon cihazı',
      GlowBookAssets.spa: 'Masaj yatağı, havlu ve spa ekipmanı',
      GlowBookAssets.lashes: 'Kaş, kirpik ve göz çevresi bakımı',
      GlowBookAssets.nails: 'El, tırnak, manikür ve pedikür uygulaması',
      GlowBookAssets.bodyTreatment: 'Bölgesel incelme ve vücut bakım cihazı',
      GlowBookAssets.hair: 'Saç şekillendirme ekipmanı',
      GlowBookAssets.makeup: 'Profesyonel makyaj ekipmanı',
    };
    return ServiceImageResolution(
      asset: asset,
      subject: subjects[asset] ?? 'GlowBook bakım hizmeti',
      neutralFallback: false,
    );
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
      .replaceAll('ç', 'c');
}
