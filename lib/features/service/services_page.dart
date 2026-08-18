import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../catalog/catalog_models.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    return Scaffold(
      body: SafeArea(
        child: services.when(
          loading: () => const GlowLoading(message: 'Hizmetler yükleniyor'),
          error: (error, _) => ServicesCatalogError(
            message: error.toString(),
            onRetry: () => ref.invalidate(servicesProvider),
          ),
          data: (items) => ServicesCatalogContent(
            services: mapCatalogServices(items),
            searchController: _searchController,
            query: _query,
            onQueryChanged: (value) => setState(() => _query = value),
          ),
        ),
      ),
      bottomNavigationBar: GlowBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) => AppNavigation.goBottomTab(context, index),
      ),
    );
  }
}

class ServicesCatalogContent extends StatelessWidget {
  const ServicesCatalogContent({
    super.key,
    required this.services,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
  });

  final List<CatalogService> services;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final visible =
        services.where((service) => service.matches(query)).toList();
    return GlowResponsivePage(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
      child: ListView(
        children: [
          Row(
            children: [
              GlowIconButton(
                key: const Key('services_public_home'),
                icon: Icons.home_outlined,
                tooltip: 'Ana Sayfaya Dön',
                onPressed: () =>
                    AppNavigation.go(context, AppRoutes.welcome),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlowPageTop(
            title: 'Hizmetleri keşfet',
            subtitle: 'Aktif hizmet kataloğu.',
            action: GlowIconButton(
              icon: Icons.inventory_2_outlined,
              tooltip: 'Paketler',
              onPressed: () => AppNavigation.go(context, AppRoutes.packages),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('services_open_packages'),
            onPressed: () => AppNavigation.go(context, AppRoutes.packages),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Paketleri Gör'),
          ),
          const SizedBox(height: 14),
          GlowSearchBar(
            hintText: 'Hizmet ara',
            controller: searchController,
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 18),
          GlowSectionHeader(
            title: 'Hizmet listesi',
            subtitle: '${visible.length} hizmet gösteriliyor',
          ),
          const SizedBox(height: 12),
          if (services.isEmpty)
            const ServicesCatalogEmpty()
          else if (visible.isEmpty)
            const GlowEmptyState(
              title: 'Aramana uygun hizmet yok',
              message: 'Arama metnini değiştirerek tekrar dene.',
              icon: Icons.search_off,
            )
          else
            for (final service in visible) ...[
              GlowServiceCard(
                title: service.name,
                subtitle: service.description ?? 'Ayrıntılar için dokun.',
                imageAsset: service.image,
                onTap: service.id == null
                    ? null
                    : () =>
                        AppNavigation.go(context, '/services/${service.id}'),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class ServicesCatalogEmpty extends StatelessWidget {
  const ServicesCatalogEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlowEmptyState(
      title: 'Hizmet bulunamadı',
      message: 'Aktif hizmet geldiğinde burada görünür.',
      icon: Icons.spa_outlined,
    );
  }
}

class ServicesCatalogError extends StatelessWidget {
  const ServicesCatalogError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GlowError(message: message, onRetry: onRetry);
  }
}
