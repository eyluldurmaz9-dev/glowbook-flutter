import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      body: SafeArea(
        child: GlowResponsivePage(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
          child: profile.when(
            loading: () => const GlowLoading(message: 'Profil yükleniyor'),
            error: (error, _) => GlowError(
              message: error.toString(),
              onRetry: () => ref.invalidate(profileProvider),
            ),
            data: (data) {
              if (data == null) {
                return const GlowEmptyState(
                  title: 'Oturum bulunamadı',
                  message: 'Profil bilgileri için tekrar giriş yap.',
                  icon: Icons.person_off_outlined,
                );
              }
              final name = [
                data['firstName'],
                data['lastName'],
              ].where((value) => value != null).join(' ');
              final displayName = name.isEmpty
                  ? data['fullName']?.toString() ?? 'GlowBook Üyesi'
                  : name;
              return ListView(
                children: [
                  GlowPageTop(
                    title: 'Profil',
                    subtitle: 'Hesap ve güzellik yolculuğun burada.',
                    action: GlowIconButton(
                      tooltip: 'Çıkış yap',
                      icon: Icons.logout,
                      onPressed: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .logout();
                        if (context.mounted) {
                          AppNavigation.go(context, AppRoutes.login);
                        }
                      },
                    ),
                  ),
                  GlowCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.blush,
                          child: Icon(Icons.person_outline,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 5),
                              Text(
                                data['email']?.toString() ??
                                    data['phone']?.toString() ??
                                    'GlowBook hesabı',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        _ProfileRow(
                          icon: Icons.verified_user_outlined,
                          label: 'Rol',
                          value: data['role']?.toString() ?? 'Müşteri',
                        ),
                      ],
                    ),
                  ),
                ],
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
