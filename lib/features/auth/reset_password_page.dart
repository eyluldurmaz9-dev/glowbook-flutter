import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../appointment/booking_models.dart';

/// Reached from the link a password-reset email sends — on web that's a
/// direct browser open of this route; on mobile, since this app has no
/// registered deep-link scheme, the same link opens in the phone's browser
/// (the web build), which is a real, working flow with zero extra platform
/// configuration needed.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  bool _done = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await ref.read(glowBackendServiceProvider).resetPassword(
            token: token,
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      setState(() => _done = true);
    } catch (error) {
      if (!mounted) return;
      GlowSnackBar.showError(
        context,
        bookingErrorMessage(error) ??
            'Bu bağlantı geçersiz veya süresi dolmuş olabilir.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.token;
    return Scaffold(
      appBar: const GlowAppBar(title: 'Yeni Şifre Belirle'),
      body: GlowResponsivePage(
        maxWidth: 560,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: GlowCard(
              padding: const EdgeInsets.all(28),
              child: token == null || token.isEmpty
                  ? const _InvalidLink()
                  : _done
                      ? const _ResetDone()
                      : _NewPasswordForm(
                          formKey: _formKey,
                          passwordController: _passwordController,
                          confirmController: _confirmController,
                          submitting: _submitting,
                          onSubmit: _submit,
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewPasswordForm extends StatelessWidget {
  const _NewPasswordForm({
    required this.formKey,
    required this.passwordController,
    required this.confirmController,
    required this.submitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlowMark(icon: Icons.lock_outline, size: 52),
          const SizedBox(height: 18),
          const GlowEyebrow('Yeni şifre'),
          const SizedBox(height: 10),
          Text(
            'Hesabın için yeni bir şifre belirle.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          GlowPasswordField(
            label: 'Yeni Şifre',
            controller: passwordController,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre zorunludur.';
              }
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalıdır.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          GlowPasswordField(
            label: 'Yeni Şifre (Tekrar)',
            controller: confirmController,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value != passwordController.text) {
                return 'Şifreler eşleşmiyor.';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (!submitting) onSubmit();
            },
          ),
          const SizedBox(height: 22),
          GlowButton(
            label: submitting ? 'Kaydediliyor' : 'Şifreyi Güncelle',
            icon: Icons.check,
            loading: submitting,
            fullWidth: true,
            onPressed: submitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _ResetDone extends StatelessWidget {
  const _ResetDone();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlowMark(icon: Icons.check_circle_outline, size: 52),
        const SizedBox(height: 18),
        const GlowEyebrow('Tamamlandı'),
        const SizedBox(height: 10),
        Text(
          'Şifren güncellendi.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Artık yeni şifrenle giriş yapabilirsin.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        GlowButton(
          label: 'Girişe Git',
          icon: Icons.login,
          fullWidth: true,
          onPressed: () => AppNavigation.go(context, AppRoutes.login),
        ),
      ],
    );
  }
}

class _InvalidLink extends StatelessWidget {
  const _InvalidLink();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlowMark(icon: Icons.error_outline, size: 52),
        const SizedBox(height: 18),
        const GlowEyebrow('Geçersiz bağlantı'),
        const SizedBox(height: 10),
        Text(
          'Bu bağlantı eksik veya geçersiz.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'Yeni bir şifre sıfırlama bağlantısı iste.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        GlowButton(
          label: 'Şifremi Unuttum',
          icon: Icons.lock_reset_outlined,
          fullWidth: true,
          onPressed: () =>
              AppNavigation.go(context, AppRoutes.forgotPassword),
        ),
      ],
    );
  }
}
