import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../appointment/booking_models.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  int? _loadedCustomerId;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final session = ref.watch(authControllerProvider).asData?.value;

    return Scaffold(
      body: SafeArea(
        child: GlowResponsivePage(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
          child: profile.when(
            loading: () => const GlowLoading(message: 'Profil yükleniyor'),
            error: (error, _) => GlowError(
              message: bookingErrorMessage(error) ?? '$error',
              onRetry: () => ref.invalidate(profileProvider),
            ),
            data: (data) {
              if (data == null || session?.customerId == null) {
                return GlowError(
                  message: 'Profil bilgileri için tekrar giriş yap.',
                  onRetry: () => AppNavigation.go(context, AppRoutes.login),
                );
              }
              _syncControllers(data, session!.customerId!);
              final displayName = _displayName(data);
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlowPageTop(
                        title: 'Profil',
                        subtitle: 'Hesap bilgilerini güvenli şekilde yönet.',
                        action: GlowIconButton(
                          tooltip: 'Çıkış yap',
                          icon: Icons.logout,
                          onPressed: _logout,
                        ),
                      ),
                      GlowCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.blush,
                              child: Icon(
                                Icons.person_outline,
                                color: AppColors.action,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    data['email']?.toString() ??
                                        data['phone']?.toString() ??
                                        'GlowBook hesabı',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_editing)
                        _ProfileForm(
                          firstNameController: _firstNameController,
                          lastNameController: _lastNameController,
                          phoneController: _phoneController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                        )
                      else
                        GlowCard(
                          child: Column(
                            children: [
                              _ProfileRow(
                                icon: Icons.phone_outlined,
                                label: 'Telefon',
                                value: data['phone']?.toString() ?? '-',
                              ),
                              const Divider(),
                              _ProfileRow(
                                icon: Icons.mail_outline,
                                label: 'E-posta',
                                value: data['email']?.toString() ?? '-',
                              ),
                              const Divider(),
                              const _ProfileRow(
                                icon: Icons.lock_outline,
                                label: 'Şifre',
                                value:
                                    'Ayrı şifre değiştirme endpoint’i bulunmuyor.',
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GlowButton(
                              label: _editing ? 'Vazgeç' : 'Düzenle',
                              icon:
                                  _editing ? Icons.close : Icons.edit_outlined,
                              variant: GlowButtonVariant.outlined,
                              onPressed: () =>
                                  setState(() => _editing = !_editing),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GlowButton(
                              label: 'Kaydet',
                              icon: Icons.save_outlined,
                              loading: _saving,
                              onPressed: _editing && !_saving
                                  ? () => _saveProfile(session.customerId!)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: GlowBottomNavigationBar(
        currentIndex: 4,
        onTap: (index) => AppNavigation.goBottomTab(context, index),
      ),
    );
  }

  void _syncControllers(Map<String, dynamic> data, int customerId) {
    if (_loadedCustomerId == customerId || _editing) return;
    _loadedCustomerId = customerId;
    _firstNameController.text = data['firstName']?.toString() ?? '';
    _lastNameController.text = data['lastName']?.toString() ?? '';
    _phoneController.text = data['phone']?.toString() ?? '';
    _emailController.text = data['email']?.toString() ?? '';
    _passwordController.clear();
  }

  String _displayName(Map<String, dynamic> data) {
    final name = [
      data['firstName'],
      data['lastName'],
    ].where((value) => value != null).join(' ');
    return name.isEmpty ? 'GlowBook Üyesi' : name;
  }

  Future<void> _saveProfile(int customerId) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(glowBackendServiceProvider).updateCustomer(customerId, {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text,
        if (_emailController.text.trim().isNotEmpty)
          'email': _emailController.text.trim(),
        'active': true,
      });
      ref.invalidate(profileProvider);
      if (mounted) {
        setState(() {
          _editing = false;
          _passwordController.clear();
        });
        GlowSnackBar.showSuccess(context, 'Profil güncellendi.');
      }
    } catch (error) {
      if (mounted) {
        GlowSnackBar.showError(context, bookingErrorMessage(error) ?? '$error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      AppNavigation.go(context, AppRoutes.login);
    }
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        children: [
          GlowTextField(
            label: 'Ad',
            controller: firstNameController,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 10),
          GlowTextField(
            label: 'Soyad',
            controller: lastNameController,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 10),
          GlowTextField(
            label: 'Telefon',
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 10),
          GlowTextField(
            label: 'E-posta',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          GlowTextField(
            label: 'Şifre',
            controller: passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: _password,
          ),
        ],
      ),
    );
  }

  static String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Bu alan zorunludur.' : null;
  }

  static String? _password(String? value) {
    if (value == null || value.isEmpty) return 'Şifre zorunludur.';
    if (value.length < 6) return 'Şifre en az 6 karakter olmalıdır.';
    return null;
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: GlowMark(icon: icon, size: 38),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
