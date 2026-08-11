import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GlowResponsivePage(
          maxWidth: 1100,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 760;
              final content = [
                Expanded(
                  child: Column(
                    crossAxisAlignment: wide
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GlowBrand(),
                      const SizedBox(height: 32),
                      const GlowEyebrow('Premium güzellik deneyimi'),
                      const SizedBox(height: 18),
                      Text(
                        'Güzelliği planlamanın\nen kolay yolu.',
                        textAlign: wide ? TextAlign.left : TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: wide ? 52 : 36, height: 1),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Hizmetleri keşfet, uzmanını seç ve randevunu birkaç dokunuşla oluştur.',
                        textAlign: wide ? TextAlign.left : TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.secondaryText,
                              height: 1.6,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          GlowButton(
                            label: 'Üye Girişi',
                            icon: Icons.arrow_forward,
                            onPressed: () =>
                                AppNavigation.go(context, AppRoutes.login),
                          ),
                          GlowButton(
                            label: 'Personel Girişi',
                            icon: Icons.badge_outlined,
                            variant: GlowButtonVariant.outlined,
                            onPressed: () => AppNavigation.go(
                              context,
                              '${AppRoutes.login}?role=EMPLOYEE',
                            ),
                          ),
                          GlowButton(
                            label: 'Misafir Devam',
                            icon: Icons.spa_outlined,
                            variant: GlowButtonVariant.secondary,
                            onPressed: () => AppNavigation.go(
                              context,
                              '${AppRoutes.login}?mode=guest',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            AppNavigation.go(context, AppRoutes.register),
                        child: const Text('Üye Ol'),
                      ),
                    ],
                  ),
                ),
                if (wide) const SizedBox(width: 56),
                Expanded(child: _WelcomeHeroVisual(height: wide ? 530 : 320)),
              ];
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: wide
                      ? Row(children: content)
                      : Column(children: content.reversed.toList()),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeroVisual extends StatelessWidget {
  const _WelcomeHeroVisual({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'GlowBook premium guzellik deneyimi',
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 60,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(34),
              topRight: Radius.circular(34),
              bottomRight: Radius.circular(100),
              bottomLeft: Radius.circular(34),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/glowbook-hero.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.blush, AppColors.petal],
                        ),
                      ),
                      child: Icon(
                        Icons.spa_outlined,
                        color: AppColors.action,
                        size: 96,
                      ),
                    );
                  },
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0x66FFF8FB),
                        Color(0xCCFFF8FB),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _HeroPill(icon: Icons.spa_outlined, label: 'Cilt bakimi'),
                      _HeroPill(
                        icon: Icons.calendar_today_outlined,
                        label: 'Aninda randevu',
                      ),
                      _HeroPill(icon: Icons.star_outline, label: '4.9 deneyim'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .92),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.action, size: 16),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
