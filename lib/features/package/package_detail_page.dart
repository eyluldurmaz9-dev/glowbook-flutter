import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../appointment/booking_models.dart';
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

class _PackageDetailContent extends ConsumerStatefulWidget {
  const _PackageDetailContent({required this.package});

  final CatalogPackage package;

  @override
  ConsumerState<_PackageDetailContent> createState() =>
      _PackageDetailContentState();
}

class _PackageDetailContentState extends ConsumerState<_PackageDetailContent> {
  /// Continues straight into the booking wizard carrying the package (and
  /// therefore the service) forward — the customer already deliberately chose
  /// both by reaching this screen, so no extra "continue?" confirmation is
  /// needed. The purchase itself happens together with the first appointment,
  /// so nothing is charged without a booking.
  void _continueToBooking() {
    final customerId =
        ref.read(authControllerProvider).asData?.value?.customerId;
    final packageId = widget.package.id;
    final serviceId = widget.package.serviceId;
    if (customerId == null) {
      GlowSnackBar.showInfo(
        context,
        'Paketini kullanmak için üye girişi yapmalısın.',
      );
      AppNavigation.go(context, AppRoutes.login);
      return;
    }
    if (packageId == null || serviceId == null) {
      GlowSnackBar.showError(context, 'Paket bilgisi eksik.');
      return;
    }

    final bookingContext = PackageBookingContext(
      packageId: packageId,
      serviceId: serviceId,
      packageName: widget.package.name,
      serviceName: widget.package.serviceName,
      totalSession: widget.package.totalSession,
    );
    AppNavigation.go(context, bookingContext.toRoute(AppRoutes.appointment));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).asData?.value;
    final signedIn = session?.customerId != null;
    final package = widget.package;
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
        GlowDetailHeroImage(
          key: Key('package_detail_hero_${package.id}'),
          semanticLabel: package.name,
          image: package.image,
          icon: Icons.inventory_2_outlined,
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
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const Key('package_detail_service'),
          onPressed: package.serviceId == null
              ? () => AppNavigation.go(context, AppRoutes.services)
              : () => AppNavigation.go(
                    context,
                    '/services/${package.serviceId}',
                  ),
          icon: const Icon(Icons.spa_outlined),
          label: Text(package.serviceName == null
              ? 'Hizmetlere Dön'
              : '${package.serviceName} hizmetini gör'),
        ),
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
            GlowPill(label: '${package.validityDays ?? 365} gün geçerli'),
          ],
        ),
        const SizedBox(height: 18),
        Text('Paket avantajları',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          package.description ??
              'Paket kapsamındaki seansları geçerlilik süresi boyunca kullanabilirsin.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Paketin ilk randevunla birlikte hesabına eklenir; ödeme salonda alınır.',
        ),
        const SizedBox(height: 22),
        GlowButton(
          key: const Key('package_detail_book'),
          label: signedIn
              ? 'Bu paketle randevu al'
              : 'Üye Girişi ile Paketi Kullan',
          icon: signedIn ? Icons.calendar_today_outlined : Icons.login,
          fullWidth: true,
          onPressed: _continueToBooking,
        ),
        const SizedBox(height: 10),
        GlowButton(
          label: 'Paket Almadan Randevu Oluştur',
          icon: Icons.calendar_today_outlined,
          variant: GlowButtonVariant.outlined,
          fullWidth: true,
          onPressed: () => AppNavigation.go(context, AppRoutes.appointment),
        ),
      ],
    );
  }
}
