import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'CUSTOMER';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      _showMessage('Telefon/e-posta ve şifre zorunludur.');
      return;
    }

    await ref.read(authControllerProvider.notifier).login(
          username: username,
          password: password,
          role: _role,
        );

    final authState = ref.read(authControllerProvider);
    if (!mounted) return;
    authState.whenOrNull(
      data: (session) {
        if (session != null) {
          AppNavigation.go(context, AppRoutes.home);
        }
      },
      error: (error, _) => _showMessage(error.toString()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFFF4F8)],
          ),
        ),
        child: SafeArea(
          child: GlowResponsivePage(
            padding: const EdgeInsets.all(20),
            maxWidth: 430,
            child: Column(
              children: [
                const Align(
                    alignment: Alignment.centerLeft, child: GlowBrand()),
                const Spacer(),
                GlowCard(
                  padding: const EdgeInsets.fromLTRB(24, 27, 24, 23),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GlowMark(icon: Icons.auto_awesome, size: 48),
                      const SizedBox(height: 19),
                      const GlowEyebrow('GlowBook üye alanı'),
                      const SizedBox(height: 9),
                      Text(
                        'Tekrar hoş geldin.',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(height: 1),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Randevularını, paketlerini ve sana özel fırsatlarını tek yerden yönet.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'CUSTOMER', label: Text('Üye')),
                          ButtonSegment(
                              value: 'EMPLOYEE', label: Text('Personel')),
                          ButtonSegment(value: 'ADMIN', label: Text('Admin')),
                        ],
                        selected: {_role},
                        onSelectionChanged: isLoading
                            ? null
                            : (value) => setState(() => _role = value.first),
                      ),
                      const SizedBox(height: 14),
                      GlowTextField(
                        label: 'E-posta / Telefon',
                        controller: _usernameController,
                        prefixIcon: Icons.mail_outline,
                      ),
                      const SizedBox(height: 14),
                      GlowTextField(
                        label: 'Şifre',
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : () {},
                          child: const Text('Şifremi Unuttum'),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: isLoading
                            ? const GlowLoading(message: 'Giriş yapılıyor')
                            : GlowButton(
                                label: 'Giriş Yap',
                                icon: Icons.arrow_forward,
                                onPressed: _login,
                              ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('veya'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () =>
                                  AppNavigation.go(context, AppRoutes.services),
                          child: const Text('Misafir olarak devam et'),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => AppNavigation.go(
                                    context,
                                    AppRoutes.register,
                                  ),
                          child: const Text('Henüz üye değil misin? Üye Ol'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Güzelliği planlamanın en kolay yolu · Güvenli giriş',
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
