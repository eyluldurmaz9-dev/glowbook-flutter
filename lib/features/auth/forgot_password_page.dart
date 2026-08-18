import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../appointment/booking_models.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _sentMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final message = await ref
          .read(glowBackendServiceProvider)
          .forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _sentMessage = message.isNotEmpty
            ? message
            : 'Eğer bu e-posta adresi sistemde kayıtlıysa şifre sıfırlama bağlantısı gönderildi.';
      });
    } catch (error) {
      if (!mounted) return;
      GlowSnackBar.showError(
        context,
        bookingErrorMessage(error) ?? 'İstek gönderilemedi.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlowAppBar(title: 'Şifremi Unuttum'),
      body: GlowResponsivePage(
        maxWidth: 560,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: GlowCard(
              padding: const EdgeInsets.all(28),
              child: _sentMessage != null
                  ? _SentConfirmation(message: _sentMessage!)
                  : _RequestForm(
                      formKey: _formKey,
                      emailController: _emailController,
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

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.formKey,
    required this.emailController,
    required this.submitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
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
          const GlowMark(icon: Icons.lock_reset_outlined, size: 52),
          const SizedBox(height: 18),
          const GlowEyebrow('Şifreni sıfırla'),
          const SizedBox(height: 10),
          Text(
            'Hesabına kayıtlı e-posta adresini gir.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Sana şifreni sıfırlaman için bir bağlantı göndereceğiz.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          GlowTextField(
            label: 'E-posta',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'E-posta zorunludur.';
              if (!email.contains('@') || !email.contains('.')) {
                return 'Geçerli bir e-posta gir.';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (!submitting) onSubmit();
            },
          ),
          const SizedBox(height: 22),
          GlowButton(
            label: submitting ? 'Gönderiliyor' : 'Gönder',
            icon: Icons.send_outlined,
            loading: submitting,
            fullWidth: true,
            onPressed: submitting ? null : onSubmit,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: submitting
                  ? null
                  : () => AppNavigation.go(context, AppRoutes.login),
              child: const Text('Girişe Dön'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlowMark(icon: Icons.mark_email_read_outlined, size: 52),
        const SizedBox(height: 18),
        const GlowEyebrow('Kontrol et'),
        const SizedBox(height: 10),
        Text(message, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(
          'Bağlantı 30 dakika geçerlidir. E-postanı bulamıyorsan spam klasörünü de kontrol et.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        GlowButton(
          label: 'Girişe Dön',
          icon: Icons.arrow_back,
          fullWidth: true,
          onPressed: () => AppNavigation.go(context, AppRoutes.login),
        ),
      ],
    );
  }
}
