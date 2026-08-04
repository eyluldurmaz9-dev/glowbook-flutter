import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../catalog/catalog_models.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final session = ref.watch(authControllerProvider).asData?.value;
    final firstName = session?.fullName?.split(' ').first;
    final signedIn = session?.customerId != null;

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
            child: HomeCatalogContent(
              services: mapCatalogServices(items),
              firstName: firstName,
              signedIn: signedIn,
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

class HomeCatalogContent extends StatelessWidget {
  const HomeCatalogContent({
    super.key,
    required this.services,
    this.firstName,
    this.signedIn = false,
  });

  final List<CatalogService> services;
  final String? firstName;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final featured = services.take(4).toList();
    return GlowResponsivePage(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
      child: ListView(
        children: [
          GlowPageTop(
            title: 'Merhaba, ${firstName ?? 'GlowBook'}',
            subtitle: 'Hizmetleri keşfet ve randevunu planla.',
            action: signedIn
                ? GlowIconButton(
                    icon: Icons.notifications_outlined,
                    tooltip: 'Bildirimler',
                    onPressed: () =>
                        AppNavigation.go(context, AppRoutes.notification),
                  )
                : null,
          ),
          _HomeHero(
            onBook: () => AppNavigation.go(context, AppRoutes.services),
          ),
          const SizedBox(height: 18),
          GlowSectionHeader(
            title: 'Öne çıkan hizmetler',
            subtitle: 'Aktif katalog servislerinden seçildi.',
            actionLabel: 'Tümünü gör',
            onAction: () => AppNavigation.go(context, AppRoutes.services),
          ),
          const SizedBox(height: 12),
          if (featured.isEmpty)
            const GlowEmptyState(
              title: 'Hizmet bulunamadı',
              message: 'Katalogda aktif hizmet geldiğinde burada görünür.',
              icon: Icons.spa_outlined,
            )
          else
            for (final service in featured) ...[
              GlowServiceCard(
                title: service.name,
                subtitle: service.description ?? 'Ayrıntılar için dokun.',
                imageAsset: service.image,
                onTap: service.id == null
                    ? null
                    : () =>
                        AppNavigation.go(context, '/services/${service.id}'),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      radius: 25,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.petal,
      borderColor: AppColors.softBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GlowEyebrow('GlowBook katalog'),
                const SizedBox(height: 8),
                Text(
                  'Kendine ayırdığın\nzaman burada.',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(height: 1.04),
                ),
                const SizedBox(height: 9),
                Text(
                  'Gerçek hizmet kataloğunu incele, detayları gör ve randevu akışına geç.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 15),
                GlowButton(
                  label: 'Hizmetleri Keşfet',
                  icon: Icons.arrow_forward,
                  onPressed: onBook,
                ),
              ],
            ),
          ),
          const GlowCatalogImage(
            semanticLabel: 'GlowBook hizmet görseli',
            image: 'assets/images/glowbook-hero.jpg',
            width: double.infinity,
            height: 150,
            radius: 0,
          ),
        ],
      ),
    );
  }
}
