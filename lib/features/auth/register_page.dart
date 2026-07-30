import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _submitted = false;

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
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      GlowSnackBar.showError(context, 'Lütfen zorunlu alanları kontrol et.');
      return;
    }

    await ref.read(authControllerProvider.notifier).register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          email: _emailController.text.trim(),
        );

    final authState = ref.read(authControllerProvider);
    if (!mounted) return;
    authState.whenOrNull(
      data: (session) {
        if (session != null) {
          GlowSnackBar.showSuccess(context, 'Üyelik başarıyla oluşturuldu.');
          AppNavigation.go(context, AppRoutes.home);
        }
      },
      error: (error, _) => GlowSnackBar.showError(context, error.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
            maxWidth: 920,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final card = _RegisterCard(
                  formKey: _formKey,
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  phoneController: _phoneController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  submitted: _submitted,
                  isLoading: isLoading,
                  onRegister: _register,
                );
                final intro = const _RegisterIntro();
                if (wide) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: intro),
                          const SizedBox(width: 44),
                          SizedBox(width: 430, child: card),
                        ],
                      ),
                    ),
                  );
                }
                return ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    intro,
                    const SizedBox(height: 24),
                    card,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.submitted,
    required this.isLoading,
    required this.onRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool submitted;
  final bool isLoading;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (!isLoading) onRegister();
              return null;
            },
          ),
        },
        child: GlowCard(
          padding: const EdgeInsets.fromLTRB(24, 27, 24, 23),
          radius: 28,
          child: Form(
            key: formKey,
            autovalidateMode: submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlowMark(icon: Icons.favorite_border, size: 50),
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
                  label: 'Ad',
                  controller: firstNameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  validator: _required('Ad zorunludur.'),
                ),
                const SizedBox(height: 14),
                GlowTextField(
                  label: 'Soyad',
                  controller: lastNameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  validator: _required('Soyad zorunludur.'),
                ),
                const SizedBox(height: 14),
                GlowTextField(
                  label: 'Telefon',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Telefon zorunludur.';
                    }
                    if (value.trim().length < 10) {
                      return 'Geçerli bir telefon gir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                GlowTextField(
                  label: 'E-posta',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return null;
                    if (!email.contains('@')) {
                      return 'Geçerli bir e-posta gir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                GlowPasswordField(
                  label: 'Şifre',
                  controller: passwordController,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre zorunludur.';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!isLoading) onRegister();
                  },
                ),
                const SizedBox(height: 22),
                GlowButton(
                  label: isLoading ? 'Üyelik oluşturuluyor' : 'Üye Ol',
                  icon: Icons.arrow_forward,
                  onPressed: isLoading ? null : onRegister,
                  loading: isLoading,
                  fullWidth: true,
                ),
                Center(
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => AppNavigation.go(context, AppRoutes.login),
                    child: const Text('Zaten üye misin? Giriş Yap'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? Function(String?) _required(String message) {
    return (value) => value == null || value.trim().isEmpty ? message : null;
  }
}

class _RegisterIntro extends StatelessWidget {
  const _RegisterIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const GlowBrand(),
        const SizedBox(height: 32),
        const GlowEyebrow('Üyelere özel'),
        const SizedBox(height: 16),
        Text(
          'Randevuların,\npaketlerin ve bildirimlerin\ntek yerde.',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 18),
        Text(
          'Üyelik yalnızca müşteri hesabı oluşturur. Personel ve admin hesapları backend yönetimiyle sağlanır.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.secondaryText,
              ),
        ),
      ],
    );
  }
}
