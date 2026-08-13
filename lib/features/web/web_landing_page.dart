import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({super.key});

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> {
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
              _CardSection(
                key: _services,
                eyebrow: 'HİZMETLER',
                title: 'Kendine ayırdığın zamanı güzelleştir.',
                cards: const [
                  _CardData('Cilt Bakımı', 'Yenileyici yüz bakımları.',
                      'assets/images/glowbook-hydrafacial.jpg'),
                  _CardData('Kaş ve Kirpik', 'Bakışlara zarif dokunuşlar.',
                      'assets/images/glowbook-lashes.jpg'),
                  _CardData('Tırnak Bakımı', 'Manikür ve nail art.',
                      'assets/images/glowbook-nails.jpg'),
                ],
              ),
              _CardSection(
                key: _packages,
                eyebrow: 'PAKETLER',
                title: 'Bakım rutinine uygun paketler.',
                cards: const [
                  _CardData('3 Bölge Lazer Paketi', 'Hedefli bakım programı.',
                      'assets/images/packages/package-laser-3-region.png'),
                  _CardData('Hydrafacial Paketi', 'Çok seanslı cilt programı.',
                      'assets/images/packages/package-skin-hydrafacial.png'),
                  _CardData('Anti-Aging Paketi', 'Planlı yenilenme bakımı.',
                      'assets/images/packages/package-skin-anti-aging.png'),
                ],
              ),
              _CallToAction(key: _booking),
              _Contact(key: _contact),
              const _Footer(),
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
          return SizedBox(
            height: 82,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: showNavigation ? 36 : 18),
              child: Row(children: [
                const GlowBrand(),
                const Spacer(),
                if (showNavigation)
                  for (final link in links)
                    TextButton(
                        onPressed: () => onNavigate(link.key),
                        child: Text(link.label)),
                const SizedBox(width: 12),
                GlowButton(
                  label: 'Giriş',
                  icon: Icons.login,
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
                Text('Güzelliği planlamanın en zarif yolu.',
                    textAlign: wide ? TextAlign.left : TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 18),
                Text(
                    'Hizmetini keşfet, uzmanını seç ve randevunu güvenle oluştur.',
                    textAlign: wide ? TextAlign.left : TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 28),
                GlowButton(
                    label: 'Randevu Al',
                    icon: Icons.calendar_month,
                    onPressed: () =>
                        AppNavigation.go(context, AppRoutes.appointment)),
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
              child: Image.asset('assets/images/glowbook-hero.jpg',
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
  const _CardData(this.title, this.body, this.image);
  final String title, body, image;
}

class _CardSection extends StatelessWidget {
  const _CardSection(
      {super.key,
      required this.eyebrow,
      required this.title,
      required this.cards});
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
                                            Text(card.body),
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
          Text('Hazır olduğunda GlowBook yanında.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          GlowButton(
              label: 'Randevu akışını başlat',
              icon: Icons.arrow_forward,
              onPressed: () =>
                  AppNavigation.go(context, AppRoutes.appointment)),
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
          const Wrap(
              spacing: 28,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                Text('info@glowbook.com'),
                Text('0555 000 00 00'),
                Text('İstanbul, Türkiye')
              ]),
        ]),
      );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => Container(
      color: AppColors.primaryText,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: const Wrap(
          spacing: 28,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Image(
              image: AssetImage(
                  'assets/images/branding/glowbook-official-logo.png'),
              width: 58,
              height: 58,
            ),
            Text('© 2026 GlowBook • Beauty • Booking • Life',
                style: TextStyle(color: AppColors.white))
          ]));
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
