import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if ([firstName, lastName, phone, password].any((value) => value.isEmpty)) {
      _showMessage('Ad, soyad, telefon ve şifre zorunludur.');
      return;
    }

    await ref.read(authControllerProvider.notifier).register(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          password: password,
          email: _emailController.text.trim(),
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
    GlowSnackBar.showError(context, message);
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
            colors: [AppColors.white, AppColors.petal],
          ),
        ),
        child: SafeArea(
          child: GlowResponsivePage(
            maxWidth: 430,
            child: ListView(
              children: [
                const GlowBrand(),
                const SizedBox(height: 28),
                GlowCard(
                  padding: const EdgeInsets.fromLTRB(24, 27, 24, 23),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GlowMark(icon: Icons.favorite_border, size: 48),
                      const SizedBox(height: 19),
                      const GlowEyebrow('Yeni üyelik'),
                      const SizedBox(height: 9),
                      Text(
                        'GlowBook hesabını oluştur.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Randevularını ve paketlerini güvenle takip etmek için bilgilerini gir.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      GlowTextField(
                          label: 'Ad', controller: _firstNameController),
                      const SizedBox(height: 14),
                      GlowTextField(
                          label: 'Soyad', controller: _lastNameController),
                      const SizedBox(height: 14),
                      GlowTextField(
                          label: 'Telefon', controller: _phoneController),
                      const SizedBox(height: 14),
                      GlowTextField(
                          label: 'E-posta', controller: _emailController),
                      const SizedBox(height: 14),
                      GlowTextField(
                        label: 'Şifre',
                        controller: _passwordController,
                        obscureText: true,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: isLoading
                            ? const GlowLoading(message: 'Üyelik oluşturuluyor')
                            : GlowButton(
                                label: 'Üye Ol',
                                icon: Icons.arrow_forward,
                                onPressed: _register,
                              ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () =>
                                  AppNavigation.go(context, AppRoutes.login),
                          child: const Text('Zaten üye misin? Giriş Yap'),
                        ),
                      ),
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
