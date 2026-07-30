import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(milliseconds: 900), _openNextPage);
  }

  void _openNextPage() {
    if (!mounted) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    AppNavigation.go(
      context,
      session == null ? AppRoutes.welcome : AppRoutes.home,
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: GlowResponsivePage(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlowMark(icon: Icons.auto_awesome, size: 82),
            SizedBox(height: 24),
            Text(
              'GlowBook',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Text('Güzelliği planlamanın en kolay yolu'),
            SizedBox(height: 20),
            GlowLoading(message: 'Hazırlanıyor'),
          ],
        ),
      ),
    );
  }
}
