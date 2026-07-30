import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class PackagesPage extends ConsumerWidget {
  const PackagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);

    return Scaffold(
      body: SafeArea(
        child: services.when(
          loading: () => const GlowLoading(message: 'Paketler yükleniyor'),
          error: (error, _) => GlowError(
            message: error.toString(),
            onRetry: () => ref.invalidate(servicesProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const GlowEmptyState(title: 'Paket bulunamadı');
            }
            return GlowResponsivePage(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
              child: ListView(
                children: [
                  const GlowPageTop(
                    title: 'Paketler',
                    subtitle: 'Seanslarını avantajlı paketlerle planla.',
                    action: GlowMark(icon: Icons.inventory_2_outlined),
                  ),
                  for (final service in items)
                    if (service['serviceId'] is int)
                      _ServicePackages(service: service),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: GlowBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) => AppNavigation.goBottomTab(context, index),
      ),
    );
  }
}

class _ServicePackages extends ConsumerWidget {
  const _ServicePackages({required this.service});

  final Map<String, dynamic> service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceId = service['serviceId'] as int;
    final packages = ref.watch(servicePackagesProvider(serviceId));

    return packages.when(
      loading: () => const GlowLoading(message: 'Paketler yükleniyor'),
      error: (error, _) => GlowError(
        message: error.toString(),
        onRetry: () => ref.invalidate(servicePackagesProvider(serviceId)),
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service['serviceName']?.toString() ?? 'Hizmet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (final item in items) ...[
              GlowCard(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const GlowMark(
                            icon: Icons.inventory_2_outlined, size: 42),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['packageName']?.toString() ?? 'Paket',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const GlowPill(
                          label: 'Aktif',
                          color: AppColors.goldText,
                          background: AppColors.goldTint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['description']?.toString() ??
                          'Paket seanslarını GlowBook üzerinden takip et.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item['totalSession'] ?? '-'} seans',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          '${item['price'] ?? '-'} TL',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.action,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}
