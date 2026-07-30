import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final session = ref.watch(authControllerProvider).valueOrNull;
    final firstName = session?.fullName?.split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: services.when(
          loading: () => const GlowLoading(message: 'Hizmetler yükleniyor'),
          error: (error, _) => GlowError(
            message: error.toString(),
            onRetry: () => ref.invalidate(servicesProvider),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(servicesProvider),
            child: GlowResponsivePage(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
              child: ListView(
                children: [
                  GlowPageTop(
                    title: 'Merhaba, ${firstName ?? 'Derya'}',
                    subtitle: 'Güzelliği planlamanın en kolay yolu',
                    action: GlowIconButton(
                      icon: Icons.notifications_outlined,
                      tooltip: 'Bildirimler',
                      onPressed: () =>
                          AppNavigation.go(context, AppRoutes.notification),
                    ),
                  ),
                  _HeroCard(
                    onBook: () =>
                        AppNavigation.go(context, AppRoutes.appointment),
                  ),
                  const SizedBox(height: 12),
                  const _LocationRow(),
                  const SizedBox(height: 18),
                  _SectionHead(
                    eyebrow: 'Özenle seçtik',
                    title: 'Popüler hizmetler',
                    actionLabel: 'Tümünü gör',
                    onAction: () =>
                        AppNavigation.go(context, AppRoutes.services),
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const GlowEmptyState(title: 'Hizmet bulunamadı')
                  else
                    for (final service in items.take(4)) ...[
                      _HomeServiceTile(service: service),
                      const SizedBox(height: 9),
                    ],
                  const SizedBox(height: 16),
                  _SectionHead(
                    eyebrow: 'Yakınındaki salonlar',
                    title: 'İyi hissettiren yerler',
                    actionLabel: 'Haritayı aç',
                    onAction: () {},
                  ),
                  const SizedBox(height: 10),
                  const _SalonCard(),
                  const SizedBox(height: 16),
                  const GlowSoftNotice(
                    title: 'İlk ziyaretine özel',
                    message:
                        'Seçili cilt bakımlarında ayrıcalıklı deneyim seni bekliyor.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: GlowBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) => AppNavigation.goBottomTab(context, index),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.petal, AppColors.white],
        ),
        border: Border.all(color: const Color(0xFFF9E8EF)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlowEyebrow('Bugünün önerisi'),
                const SizedBox(height: 8),
                Text(
                  'Kendine ayırdığın\nzaman burada.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        height: 1.04,
                      ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Sana iyi gelen hizmeti bul, uzmanını seç ve randevunu birkaç dokunuşla oluştur.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 15),
                GlowButton(
                  label: 'Randevu Oluştur',
                  icon: Icons.arrow_forward,
                  onPressed: onBook,
                ),
              ],
            ),
          ),
          Container(
            height: 142,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD1DC), Color(0xFFFFF8FB)],
              ),
            ),
            child: const Icon(
              Icons.spa_outlined,
              color: AppColors.primary,
              size: 64,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            color: AppColors.secondaryText, size: 14),
        const SizedBox(width: 7),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'İstanbul',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' · Sana yakın salonları keşfet'),
              ],
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Icon(Icons.chevron_right,
            color: AppColors.secondaryText, size: 16),
      ],
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({
    required this.eyebrow,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String eyebrow;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlowEyebrow(eyebrow),
              const SizedBox(height: 6),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _HomeServiceTile extends StatelessWidget {
  const _HomeServiceTile({required this.service});

  final Map<String, dynamic> service;

  @override
  Widget build(BuildContext context) {
    final serviceId = service['serviceId'];
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap:
          serviceId == null ? null : () => context.go('/services/$serviceId'),
      child: GlowCard(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            _ServiceThumb(
                label: service['serviceName']?.toString() ?? 'Hizmet'),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['serviceName']?.toString() ?? 'Hizmet',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    service['description']?.toString() ??
                        'Ödeme salonda yapılır',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          color: AppColors.secondaryText, size: 11),
                      const SizedBox(width: 4),
                      Text('60 dk',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(width: 6),
                      const GlowPill(
                        label: 'Ödeme salonda',
                        color: Color(0xFF4E8A71),
                        background: Color(0xFFEDF7F1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.favorite_border,
                color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ServiceThumb extends StatelessWidget {
  const _ServiceThumb({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label.characters.first.toUpperCase(),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SalonCard extends StatelessWidget {
  const _SalonCard();

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(9),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.petal,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.storefront_outlined,
                color: AppColors.primary, size: 34),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Lal Beauty Studio',
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    const Icon(Icons.star,
                        color: AppColors.goldAccent, size: 13),
                    Text('4,9', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 7),
                Text('Nişantaşı · 1,2 km',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    GlowPill(label: 'Hydrafacial'),
                    GlowPill(label: 'İpek kirpik'),
                    GlowPill(label: 'Manikür'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
