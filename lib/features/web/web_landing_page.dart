import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../catalog/catalog_models.dart';

class WebLandingPage extends ConsumerStatefulWidget {
  const WebLandingPage({super.key});

  @override
  ConsumerState<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends ConsumerState<WebLandingPage> {
  final _controller = ScrollController();
  final _home = GlobalKey();
  final _about = GlobalKey();
  final _services = GlobalKey();
  final _packages = GlobalKey();
  final _booking = GlobalKey();
  final _contact = GlobalKey();

  Future<void> _scrollTo(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(target,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: .04);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final packages = ref.watch(allServicePackagesProvider);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(children: [
        _Header(
          links: [
            _HeaderLink('Ana Sayfa', _home),
            _HeaderLink('Hakkımızda', _about),
            _HeaderLink('Hizmetler', _services),
            _HeaderLink('Paketler', _packages),
            _HeaderLink('Randevu Al', _booking),
            _HeaderLink('İletişim', _contact),
          ],
          onNavigate: _scrollTo,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _controller,
            child: Column(children: [
              _Hero(key: _home),
              _About(key: _about),
              _PublicServicesSection(
                key: _services,
                value: services,
                onRetry: () => ref.invalidate(servicesProvider),
              ),
              _PublicPackagesSection(
                key: _packages,
                value: packages,
                onRetry: () => ref.invalidate(allServicePackagesProvider),
              ),
              _CallToAction(key: _booking),
              _Contact(key: _contact),
              _Footer(links: [
                _FooterLink('Ana Sayfa', _home),
                _FooterLink('Hakkımızda', _about),
                _FooterLink('Hizmetler', _services),
                _FooterLink('Paketler', _packages),
                _FooterLink('Randevu Al', _booking),
                _FooterLink('İletişim', _contact),
              ], onNavigate: _scrollTo),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.links, required this.onNavigate});
  final List<_HeaderLink> links;
  final ValueChanged<GlobalKey> onNavigate;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 2,
        color: AppColors.white,
        child: LayoutBuilder(builder: (context, constraints) {
          final showNavigation = constraints.maxWidth >= 1060;
          final compact = constraints.maxWidth < 500;
          return SizedBox(
            height: 82,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: showNavigation ? 36 : 18),
              child: Row(children: [
                if (compact)
                  Image.asset(
                    'assets/images/branding/glowbook-official-logo.png',
                    width: 46,
                    height: 46,
                  )
                else
                  const GlowBrand(),
                const Spacer(),
                if (showNavigation)
                  for (final link in links)
                    if (link.label == 'Hizmetler')
                      PopupMenuButton<String>(
                        key: const Key('web_services_menu'),
                        tooltip: 'Hizmetler menüsü',
                        onSelected: (value) {
                          final targetLabel =
                              value == 'packages' ? 'Paketler' : 'Hizmetler';
                          final target = links
                              .firstWhere((item) => item.label == targetLabel);
                          onNavigate(target.key);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'services', child: Text('Tüm Hizmetler')),
                          PopupMenuItem(
                              value: 'packages', child: Text('Paketler')),
                        ],
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(children: [
                            Text('Hizmetler'),
                            SizedBox(width: 3),
                            Icon(Icons.keyboard_arrow_down, size: 18),
                          ]),
                        ),
                      )
                    else
                      TextButton(
                          key: Key('web_nav_${link.label}'),
                          onPressed: () => onNavigate(link.key),
                          child: Text(link.label)),
                if (!showNavigation)
                  PopupMenuButton<_HeaderLink>(
                    key: const Key('web_mobile_menu'),
                    tooltip: 'Menü',
                    icon: const Icon(Icons.menu),
                    onSelected: (link) => onNavigate(link.key),
                    itemBuilder: (_) => [
                      for (final link in links)
                        PopupMenuItem(value: link, child: Text(link.label)),
                    ],
                  ),
                const SizedBox(width: 12),
                TextButton(
                  key: const Key('web_login'),
                  child: const Text('Giriş Yap'),
                  onPressed: () => AppNavigation.go(context, AppRoutes.login),
                ),
              ]),
            ),
          );
        }),
      );
}

class _HeaderLink {
  const _HeaderLink(this.label, this.key);

  final String label;
  final GlobalKey key;
}

class _Hero extends StatelessWidget {
  const _Hero({super.key});
  @override
  Widget build(BuildContext context) => _Section(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          final copy = Column(
              crossAxisAlignment:
                  wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/branding/glowbook-official-logo.png',
                    width: wide ? 150 : 110, height: wide ? 150 : 110),
                const SizedBox(height: 24),
                Text('Güzelliği planlamanın en kolay yolu.',
                    textAlign: wide ? TextAlign.left : TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 18),
                Text(
                    'Hizmetini keşfet, uzmanını seç ve randevunu güvenle oluştur.',
                    textAlign: wide ? TextAlign.left : TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 28),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  GlowButton(
                      key: const Key('web_hero_book'),
                      label: 'Randevu Al',
                      icon: Icons.calendar_month,
                      onPressed: () => AppNavigation.go(
                          context, '${AppRoutes.login}?mode=guest')),
                  OutlinedButton.icon(
                      key: const Key('web_hero_login'),
                      onPressed: () =>
                          AppNavigation.go(context, AppRoutes.login),
                      icon: const Icon(Icons.login),
                      label: const Text('Giriş Yap')),
                ]),
              ]);
          final visual = ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Image.asset('assets/images/glowbook-hero.jpg',
                  height: 480, width: double.infinity, fit: BoxFit.cover));
          return wide
              ? Row(children: [
                  Expanded(child: copy),
                  const SizedBox(width: 60),
                  Expanded(child: visual)
                ])
              : Column(children: [copy, const SizedBox(height: 32), visual]);
        }),
      );
}

class _About extends StatelessWidget {
  const _About({super.key});
  @override
  Widget build(BuildContext context) => _Section(
        tinted: true,
        child: LayoutBuilder(builder: (context, constraints) {
          final image = ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset('assets/images/glowbook-hydrafacial.jpg',
                  height: 360, width: double.infinity, fit: BoxFit.cover));
          final copy =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const GlowEyebrow('HAKKIMIZDA'),
            const SizedBox(height: 16),
            Text('Güzellik, bakım ve randevu tek deneyimde.',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            Text(
                'GlowBook; doğru hizmeti, yetkin uzmanı ve uygun saati şeffaf bir randevu deneyiminde buluşturur.',
                style: Theme.of(context).textTheme.bodyLarge),
          ]);
          return constraints.maxWidth >= 760
              ? Row(children: [
                  Expanded(child: image),
                  const SizedBox(width: 54),
                  Expanded(child: copy)
                ])
              : Column(children: [image, const SizedBox(height: 30), copy]);
        }),
      );
}

class _CardData {
  const _CardData(this.title, this.body, this.image,
      {this.metadata, this.action, this.onTap});
  final String title, body, image;
  final String? metadata, action;
  final VoidCallback? onTap;
}

class _PublicServicesSection extends StatelessWidget {
  const _PublicServicesSection(
      {super.key, required this.value, required this.onRetry});
  final AsyncValue<List<Map<String, dynamic>>> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => value.when(
        loading: () => const _LoadingCatalogSection(
            eyebrow: 'HİZMETLER', message: 'Hizmetler yükleniyor'),
        error: (_, __) => _ErrorCatalogSection(
            eyebrow: 'HİZMETLER',
            title: 'Hizmetler yüklenemedi',
            onRetry: onRetry),
        data: (items) {
          final services = mapCatalogServices(items)
              .where((item) => item.active != false)
              .toList();
          return _CardSection(
              eyebrow: 'HİZMETLER',
              title: 'Kendine ayırdığın zamanı güzelleştir.',
              cards: [
                for (final service in services)
                  _CardData(
                    service.name,
                    service.description ??
                        'Hizmet ayrıntılarını inceleyip randevunu planla.',
                    service.image ?? 'assets/images/glowbook-hero.jpg',
                    action: 'Randevu Al',
                    onTap: () => AppNavigation.go(
                        context, '${AppRoutes.login}?mode=guest'),
                  ),
              ]);
        },
      );
}

class _PublicPackagesSection extends StatelessWidget {
  const _PublicPackagesSection(
      {super.key, required this.value, required this.onRetry});
  final AsyncValue<List<Map<String, dynamic>>> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => value.when(
        loading: () => const _LoadingCatalogSection(
            eyebrow: 'PAKETLER', message: 'Paketler yükleniyor'),
        error: (_, __) => _ErrorCatalogSection(
            eyebrow: 'PAKETLER',
            title: 'Paketler yüklenemedi',
            onRetry: onRetry),
        data: (items) {
          final packages = mapCatalogPackages(items)
              .where((item) => item.active != false)
              .toList();
          return _CardSection(
              eyebrow: 'PAKETLER',
              title: 'Bakım rutinine uygun paketler.',
              cards: [
                for (final package in packages)
                  _CardData(
                    package.name,
                    package.description ?? 'Paket ayrıntılarını incele.',
                    package.image ?? 'assets/images/glowbook-hero.jpg',
                    metadata: [
                      if (package.totalSession != null)
                        '${package.totalSession} seans',
                      if (package.priceText != null) '${package.priceText} ₺',
                      if (package.validityDays != null)
                        '${package.validityDays} gün geçerli',
                    ].join(' • '),
                    action: 'Paketi İncele',
                    onTap: package.id == null || package.serviceId == null
                        ? null
                        : () => AppNavigation.go(context,
                            '/packages/${package.serviceId}/${package.id}'),
                  ),
              ]);
        },
      );
}

class _LoadingCatalogSection extends StatelessWidget {
  const _LoadingCatalogSection({required this.eyebrow, required this.message});
  final String eyebrow, message;
  @override
  Widget build(BuildContext context) => _Section(
          child: Column(children: [
        GlowEyebrow(eyebrow),
        const SizedBox(height: 24),
        GlowLoading(message: message),
      ]));
}

class _ErrorCatalogSection extends StatelessWidget {
  const _ErrorCatalogSection(
      {required this.eyebrow, required this.title, required this.onRetry});
  final String eyebrow, title;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _Section(
          child: Column(children: [
        GlowEyebrow(eyebrow),
        const SizedBox(height: 24),
        GlowError(
            title: title, message: 'Lütfen yeniden deneyin.', onRetry: onRetry),
      ]));
}

class _CardSection extends StatelessWidget {
  const _CardSection(
      {required this.eyebrow, required this.title, required this.cards});
  final String eyebrow, title;
  final List<_CardData> cards;
  @override
  Widget build(BuildContext context) => _Section(
        child: Column(children: [
          GlowEyebrow(eyebrow),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 34),
          LayoutBuilder(
              builder: (context, constraints) => Wrap(
                    spacing: 22,
                    runSpacing: 22,
                    children: [
                      for (final card in cards)
                        SizedBox(
                          width: constraints.maxWidth > 900
                              ? (constraints.maxWidth - 44) / 3
                              : 340,
                          child: GlowCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(24)),
                                      child: Image.asset(card.image,
                                          height: 210,
                                          width: double.infinity,
                                          fit: BoxFit.cover)),
                                  Padding(
                                      padding: const EdgeInsets.all(22),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(card.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge),
                                            const SizedBox(height: 8),
                                            Text(card.body,
                                                maxLines: 3,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            if (card.metadata?.isNotEmpty ==
                                                true) ...[
                                              const SizedBox(height: 10),
                                              Text(card.metadata!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge),
                                            ],
                                            if (card.action != null) ...[
                                              const SizedBox(height: 12),
                                              TextButton(
                                                  onPressed: card.onTap,
                                                  child: Text(card.action!)),
                                            ],
                                          ])),
                                ]),
                          ),
                        )
                    ],
                  )),
        ]),
      );
}

class _CallToAction extends StatelessWidget {
  const _CallToAction({super.key});
  @override
  Widget build(BuildContext context) => _Section(
        tinted: true,
        child: Column(children: [
          const GlowEyebrow('RANDEVU AL'),
          const SizedBox(height: 14),
          Text('Bakımını dört kolay adımda planla.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 22),
          const Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                Text('1. Hizmetini seç'),
                Text('2. Personelini seç'),
                Text('3. Tarih ve saat seç'),
                Text('4. Randevunu oluştur'),
              ]),
          const SizedBox(height: 24),
          GlowButton(
              label: 'Randevu akışını başlat',
              icon: Icons.arrow_forward,
              onPressed: () =>
                  AppNavigation.go(context, '${AppRoutes.login}?mode=guest')),
        ]),
      );
}

class _Contact extends StatelessWidget {
  const _Contact({super.key});
  @override
  Widget build(BuildContext context) => _Section(
        child: Column(children: [
          const GlowEyebrow('İLETİŞİM'),
          const SizedBox(height: 14),
          Text('Bize ulaşın',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: const Text(
              'İletişim bilgilerimiz hazırlanıyor. Güncel telefon, e-posta ve adres bilgileri yayınlandığında burada yer alacak.',
              textAlign: TextAlign.center,
            ),
          ),
        ]),
      );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.links, required this.onNavigate});
  final List<_FooterLink> links;
  final ValueChanged<GlobalKey> onNavigate;
  @override
  Widget build(BuildContext context) => Container(
      color: AppColors.primaryText,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Wrap(
          spacing: 28,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Image(
              image: AssetImage(
                  'assets/images/branding/glowbook-official-logo.png'),
              width: 58,
              height: 58,
            ),
            for (final link in links)
              TextButton(
                  onPressed: () => onNavigate(link.target),
                  child: Text(link.label,
                      style: const TextStyle(color: AppColors.white))),
            TextButton(
                onPressed: () => AppNavigation.go(context, AppRoutes.login),
                child: const Text('Giriş',
                    style: TextStyle(color: AppColors.white))),
            const Text('© 2026 GlowBook • Beauty • Booking • Life',
                style: TextStyle(color: AppColors.white))
          ]));
}

class _FooterLink {
  const _FooterLink(this.label, this.target);
  final String label;
  final GlobalKey target;
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.tinted = false});
  final Widget child;
  final bool tinted;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      color: tinted ? AppColors.petal : AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 82),
      child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: child)));
}
