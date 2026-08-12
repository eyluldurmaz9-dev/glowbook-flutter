class GlowBookAssets {
  GlowBookAssets._();

  static const hero = 'assets/images/glowbook-hero.jpg';
  static const hydrafacial = 'assets/images/glowbook-hydrafacial.jpg';
  static const lashes = 'assets/images/glowbook-lashes.jpg';
  static const nails = 'assets/images/glowbook-nails.jpg';
  static const portraitDerya = 'assets/images/glowbook-portrait-derya.jpg';
  static const portraitElif = 'assets/images/glowbook-portrait-elif.jpg';

  static const approved = <String>{
    hero,
    hydrafacial,
    lashes,
    nails,
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

/// The approved Visual Asset Manager repository is the catalog source of truth.
class ServiceImageResolver {
  ServiceImageResolver._();

  static const knownServices = <String>[
    'Cilt Bakımı',
    'Lazer Epilasyon',
    'Masaj ve Spa',
    'Kaş ve Kirpik',
    'Bölgesel İncelme',
  ];

  static ServiceImageResolution resolve(String? serviceName) {
    final value = _normalize(serviceName);
    if (_containsAny(value, const [
      'cilt',
      'hydrafacial',
      'anti aging',
      'leke',
      'akne',
    ])) {
      return const ServiceImageResolution(
        asset: GlowBookAssets.hydrafacial,
        subject: 'Hydrafacial ve yüz cilt bakımı',
        neutralFallback: false,
      );
    }
    if (_containsAny(value, const [
      'kas',
      'kirpik',
      'lifting',
      'ipek kirpik',
    ])) {
      return const ServiceImageResolution(
        asset: GlowBookAssets.lashes,
        subject: 'Kaş, kirpik ve göz çevresi bakımı',
        neutralFallback: false,
      );
    }
    if (_containsAny(value, const [
      'tirnak',
      'manikur',
      'kalici oje',
      'nail art',
      'protez',
    ])) {
      return const ServiceImageResolution(
        asset: GlowBookAssets.nails,
        subject: 'El, tırnak ve manikür uygulaması',
        neutralFallback: false,
      );
    }
    return const ServiceImageResolution(
      asset: GlowBookAssets.hero,
      subject: 'GlowBook salon iç mekânı — nötr fallback',
      neutralFallback: true,
    );
  }

  static String imageFor(String? serviceName) => resolve(serviceName).asset;

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
