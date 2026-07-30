import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../catalog/catalog_models.dart';

class PackageDetailPage extends ConsumerWidget {
  const PackageDetailPage({
    super.key,
    required this.serviceId,
    required this.packageId,
  });

  final int serviceId;
  final int packageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(servicePackagesProvider(serviceId));
    return Scaffold(
      body: SafeArea(
        child: GlowResponsivePage(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: packages.when(
            loading: () => const GlowLoading(message: 'Paket yükleniyor'),
            error: (error, _) => GlowError(
              message: error.toString(),
              onRetry: () => ref.invalidate(servicePackagesProvider(serviceId)),
            ),
            data: (items) {
              final package = _firstMatchingPackage(
                mapCatalogPackages(items),
                packageId,
              );
              if (package == null) {
                return const GlowEmptyState(
                  title: 'Paket bulunamadı',
                  message: 'Bu bağlantıdaki paket aktif katalogda görünmüyor.',
                  icon: Icons.inventory_2_outlined,
                );
              }
              return _PackageDetailContent(package: package);
            },
          ),
        ),
      ),
    );
  }
}

CatalogPackage? _firstMatchingPackage(
  List<CatalogPackage> packages,
  int packageId,
) {
  for (final package in packages) {
    if (package.id == packageId) return package;
  }
  return null;
}

class _PackageDetailContent extends StatelessWidget {
  const _PackageDetailContent({required this.package});

  final CatalogPackage package;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            GlowIconButton(
              icon: Icons.chevron_left,
              tooltip: 'Geri',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            const GlowBrand(compact: true),
          ],
        ),
        const SizedBox(height: 18),
        GlowCatalogImage(
          semanticLabel: package.name,
          image: package.image,
          icon: Icons.inventory_2_outlined,
          width: double.infinity,
          height: 220,
          radius: 30,
        ),
        const SizedBox(height: 22),
        const GlowEyebrow('Paket detayı'),
        const SizedBox(height: 8),
        Text(package.name, style: Theme.of(context).textTheme.headlineMedium),
        if (package.serviceName != null) ...[
          const SizedBox(height: 6),
          Text(
            package.serviceName!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (package.description != null) ...[
          const SizedBox(height: 12),
          Text(
            package.description!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (package.totalSession != null)
              GlowPill(label: '${package.totalSession} seans'),
            if (package.priceText != null)
              GlowPill(
                label: package.priceText!,
                color: AppColors.action,
                background: AppColors.roseTint,
              ),
          ],
        ),
        const SizedBox(height: 22),
        GlowButton(
          label: 'Randevu Oluştur',
          icon: Icons.calendar_today_outlined,
          fullWidth: true,
          onPressed: () => AppNavigation.go(context, AppRoutes.appointment),
        ),
      ],
    );
  }
}
