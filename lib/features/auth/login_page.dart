import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialRole, this.guestMode = false});

  final String? initialRole;
  final bool guestMode;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  var _role = 'CUSTOMER';
  var _submitted = false;

  @override
  void initState() {
    super.initState();
    final role = widget.initialRole?.toUpperCase();
    if (role == 'EMPLOYEE' || role == 'ADMIN' || role == 'CUSTOMER') {
      _role = role!;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      GlowSnackBar.showError(context, 'Lütfen zorunlu alanları kontrol et.');
      return;
    }

    await ref.read(authControllerProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          role: _role,
        );

    final authState = ref.read(authControllerProvider);
    if (!mounted) return;
    authState.whenOrNull(
      data: (session) {
        if (session == null) return;
        GlowSnackBar.showSuccess(context, 'Giriş başarılı.');
        AppNavigation.go(context, _routeForRole(session.role));
      },
      error: (error, _) => GlowSnackBar.showError(context, error.toString()),
    );
  }

  String _routeForRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return AppRoutes.admin;
      case 'EMPLOYEE':
        return AppRoutes.employeeDashboard;
      case 'CUSTOMER':
      default:
        return AppRoutes.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    if (widget.guestMode) {
      return const _GuestAccessView();
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _AuthBackground(
        child: GlowResponsivePage(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          maxWidth: 980,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final form = _LoginCard(
                formKey: _formKey,
                usernameController: _usernameController,
                passwordController: _passwordController,
                usernameFocus: _usernameFocus,
                passwordFocus: _passwordFocus,
                role: _role,
                submitted: _submitted,
                isLoading: isLoading,
                onRoleChanged: (value) => setState(() => _role = value),
                onLogin: _login,
              );
              final intro = _AuthIntro(role: _role);
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
                        SizedBox(width: 430, child: form),
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
                  form,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.usernameFocus,
    required this.passwordFocus,
    required this.role,
    required this.submitted,
    required this.isLoading,
    required this.onRoleChanged,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final String role;
  final bool submitted;
  final bool isLoading;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onLogin;

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
              if (!isLoading) onLogin();
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
                GlowMark(
                  icon: role == 'EMPLOYEE'
                      ? Icons.badge_outlined
                      : role == 'ADMIN'
                          ? Icons.admin_panel_settings_outlined
                          : Icons.auto_awesome,
                  size: 50,
                ),
                const SizedBox(height: 19),
                GlowEyebrow(_eyebrowForRole(role)),
                const SizedBox(height: 9),
                Text(
                  _titleForRole(role),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  _subtitleForRole(role),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'CUSTOMER', label: Text('Üye')),
                    ButtonSegment(value: 'EMPLOYEE', label: Text('Personel')),
                    ButtonSegment(value: 'ADMIN', label: Text('Admin')),
                  ],
                  selected: {role},
                  onSelectionChanged:
                      isLoading ? null : (value) => onRoleChanged(value.first),
                ),
                const SizedBox(height: 14),
                GlowTextField(
                  label: 'E-posta / Telefon',
                  controller: usernameController,
                  focusNode: usernameFocus,
                  prefixIcon: Icons.mail_outline,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                    AutofillHints.telephoneNumber,
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'E-posta veya telefon zorunludur.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 14),
                GlowPasswordField(
                  label: 'Şifre',
                  controller: passwordController,
                  focusNode: passwordFocus,
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
                    if (!isLoading) onLogin();
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => AppNavigation.go(
                              context,
                              AppRoutes.forgotPassword,
                            ),
                    child: const Text('Şifremi unuttum'),
                  ),
                ),
                GlowButton(
                  label: isLoading ? 'Giriş yapılıyor' : 'Giriş Yap',
                  icon: Icons.arrow_forward,
                  onPressed: isLoading ? null : onLogin,
                  loading: isLoading,
                  fullWidth: true,
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
                GlowButton(
                  label: 'Misafir olarak devam et',
                  icon: Icons.spa_outlined,
                  variant: GlowButtonVariant.outlined,
                  fullWidth: true,
                  onPressed: isLoading
                      ? null
                      : () => AppNavigation.go(
                            context,
                            '${AppRoutes.login}?mode=guest',
                          ),
                ),
                Center(
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => AppNavigation.go(context, AppRoutes.register),
                    child: const Text('Henüz üye değil misin? Üye Ol'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _eyebrowForRole(String role) {
    switch (role) {
      case 'EMPLOYEE':
        return 'GlowBook personel alanı';
      case 'ADMIN':
        return 'GlowBook yönetim alanı';
      default:
        return 'GlowBook üye alanı';
    }
  }

  static String _titleForRole(String role) {
    switch (role) {
      case 'EMPLOYEE':
        return 'Programına güvenle ulaş.';
      case 'ADMIN':
        return 'İşletmeni tek ekrandan yönet.';
      default:
        return 'Tekrar hoş geldin.';
    }
  }

  static String _subtitleForRole(String role) {
    switch (role) {
      case 'EMPLOYEE':
        return 'Randevu takvimini, müşteri akışını ve günlük programını görüntüle.';
      case 'ADMIN':
        return 'Hizmetleri, ekip durumunu ve salon operasyonunu takip et.';
      default:
        return 'Randevularını, paketlerini ve sana özel fırsatlarını tek yerden yönet.';
    }
  }
}

class _AuthIntro extends StatelessWidget {
  const _AuthIntro({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const GlowBrand(),
        const SizedBox(height: 32),
        const GlowEyebrow('Premium güzellik deneyimi'),
        const SizedBox(height: 16),
        Text(
          'Güzelliğin ritmi\nGlowBook ile başlar.',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 18),
        Text(
          'Randevudan bakım deneyimine kadar her adım sade, zarif ve kusursuz.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.secondaryText,
              ),
        ),
      ],
    );
  }
}

class _GuestAccessView extends StatelessWidget {
  const _GuestAccessView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AuthBackground(
        child: SafeArea(
          child: GlowResponsivePage(
            maxWidth: 760,
            child: Center(
              child: GlowCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GlowMark(icon: Icons.spa_outlined, size: 52),
                    const SizedBox(height: 18),
                    const GlowEyebrow('Misafir erişimi'),
                    const SizedBox(height: 10),
                    Text(
                      'Hizmetleri giriş yapmadan keşfedebilirsin.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Randevu oluşturmak, paketlerini takip etmek ve bildirim almak için üye girişi gerekir.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        GlowButton(
                          label: 'Hizmetleri Keşfet',
                          icon: Icons.arrow_forward,
                          onPressed: () =>
                              AppNavigation.go(context, AppRoutes.services),
                        ),
                        GlowButton(
                          label: 'Girişe Dön',
                          variant: GlowButtonVariant.outlined,
                          onPressed: () =>
                              AppNavigation.go(context, AppRoutes.login),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.white, AppColors.petal],
        ),
      ),
      child: child,
    );
  }
}
