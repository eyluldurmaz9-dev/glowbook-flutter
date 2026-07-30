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
                            label: 'Randevu Oluştur',
                            icon: Icons.arrow_forward,
                            onPressed: () =>
                                AppNavigation.go(context, AppRoutes.login),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                AppNavigation.go(context, AppRoutes.services),
                            child: const Text('Hizmetleri Keşfet'),
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
                Expanded(
                  child: Container(
                    height: wide ? 530 : 320,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.blush, AppColors.petal],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(34),
                        topRight: Radius.circular(34),
                        bottomRight: Radius.circular(100),
                        bottomLeft: Radius.circular(34),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 60,
                          offset: Offset(0, 20),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.spa_outlined,
                        color: AppColors.primary, size: 96),
                  ),
                ),
              ];
              return wide
                  ? Row(children: content)
                  : Column(children: content.reversed.toList());
            },
          ),
        ),
      ),
    );
  }
}
