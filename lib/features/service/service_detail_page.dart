import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../catalog/catalog_models.dart';

class ServiceDetailPage extends ConsumerWidget {
  const ServiceDetailPage({super.key, required this.serviceId});

  final int serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final options = ref.watch(serviceOptionsProvider(serviceId));
    final packages = ref.watch(servicePackagesProvider(serviceId));
    final employees = ref.watch(employeesByServiceProvider(serviceId));

    return Scaffold(
      body: SafeArea(
        child: GlowResponsivePage(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: ListView(
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
              services.when(
                loading: () => const GlowSkeleton(height: 320, radius: 28),
                error: (error, _) => GlowError(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(servicesProvider),
                ),
                data: (items) {
                  final service = _firstMatchingService(
                    mapCatalogServices(items),
                    serviceId,
                  );
                  if (service == null) {
                    return const GlowEmptyState(
                      title: 'Hizmet bulunamadı',
                      message:
                          'Bu bağlantıdaki hizmet aktif katalogda görünmüyor.',
                      icon: Icons.spa_outlined,
                    );
                  }
                  return _ServiceHeader(service: service);
                },
              ),
              const SizedBox(height: 22),
              _Section(
                title: 'Alt hizmetler',
                child: options.when(
                  loading: () => const GlowLoading(message: 'Seçenekler'),
                  error: (error, _) => GlowError(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(serviceOptionsProvider(serviceId)),
                  ),
                  data: (items) => _OptionList(
                    options: mapCatalogOptions(items),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Bu hizmet için paketler',
                child: packages.when(
                  loading: () => const GlowLoading(message: 'Paketler'),
                  error: (error, _) => GlowError(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(servicePackagesProvider(serviceId)),
                  ),
                  data: (items) => _PackageList(
                    packages: mapCatalogPackages(items)
                        .where((item) =>
                            item.serviceId == null ||
                            item.serviceId == serviceId)
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Uygun personel',
                child: employees.when(
                  loading: () => const GlowLoading(message: 'Personel'),
                  error: (error, _) => GlowError(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(employeesByServiceProvider(serviceId)),
                  ),
                  data: (items) => _EmployeeList(items: items),
                ),
              ),
              const SizedBox(height: 24),
              GlowButton(
                key: const Key('service_detail_book'),
                label: 'Randevu Al',
                icon: Icons.calendar_today_outlined,
                fullWidth: true,
                onPressed: () =>
                    AppNavigation.go(context, AppRoutes.appointment),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

CatalogService? _firstMatchingService(
  List<CatalogService> services,
  int serviceId,
) {
  for (final service in services) {
    if (service.id == serviceId) return service;
  }
  return null;
}

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader({required this.service});

  final CatalogService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlowDetailHeroImage(
          key: Key('service_detail_hero_${service.id}'),
          semanticLabel: service.name,
          image: service.image,
          radius: 30,
        ),
        const SizedBox(height: 22),
        const GlowEyebrow('Hizmet detayı'),
        const SizedBox(height: 8),
        Text(service.name, style: Theme.of(context).textTheme.headlineMedium),
        if (service.description != null) ...[
          const SizedBox(height: 10),
          Text(
            service.description!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({required this.options});

  final List<CatalogOption> options;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const GlowEmptyState(title: 'Alt hizmet bulunamadı');
    }
    return Column(
      children: [
        for (final option in options) ...[
          GlowCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const GlowMark(icon: Icons.schedule, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  option.priceText ?? 'Fiyat yok',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.action,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PackageList extends StatelessWidget {
  const _PackageList({required this.packages});

  final List<CatalogPackage> packages;

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) {
      return const GlowEmptyState(title: 'Paket bulunamadı');
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const Key('service_detail_packages'),
            onPressed:
                packages.first.id == null || packages.first.serviceId == null
                    ? null
                    : () => AppNavigation.go(
                          context,
                          '/packages/${packages.first.serviceId}/${packages.first.id}',
                        ),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Bu hizmet için paketleri gör'),
          ),
        ),
        const SizedBox(height: 10),
        for (final package in packages) ...[
          GlowPackageCard(
            title: package.name,
            description: package.description ?? 'Ayrıntılar için dokun.',
            image: package.image,
            semanticLabel: '${package.name} görseli',
            price: package.priceText,
            sessions: package.totalSession == null
                ? null
                : '${package.totalSession} seans',
            onTap: package.id == null || package.serviceId == null
                ? null
                : () => AppNavigation.go(
                      context,
                      '/packages/${package.serviceId}/${package.id}',
                    ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const GlowEmptyState(title: 'Personel bulunamadı');
    }
    return Column(
      children: [
        for (final item in items) ...[
          GlowEmployeeCard(
            name: item['employeeName']?.toString() ??
                item['fullName']?.toString() ??
                'Personel',
            role: item['employeeId']?.toString() ?? 'Uzman',
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
