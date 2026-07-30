import 'package:flutter/material.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlowAppBar(title: 'Şifremi Unuttum'),
      body: GlowResponsivePage(
        maxWidth: 560,
        child: Center(
          child: GlowCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlowMark(icon: Icons.lock_reset_outlined, size: 52),
                const SizedBox(height: 18),
                const GlowEyebrow('Backend desteği gerekli'),
                const SizedBox(height: 10),
                Text(
                  'Şifre sıfırlama henüz aktif değil.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'Mevcut backend sözleşmesinde şifre sıfırlama endpoint’i bulunmuyor. Güvenlik nedeniyle sahte başarı mesajı göstermiyoruz.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                GlowButton(
                  label: 'Girişe Dön',
                  icon: Icons.arrow_back,
                  onPressed: () => AppNavigation.go(context, AppRoutes.login),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
