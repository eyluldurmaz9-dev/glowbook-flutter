import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../catalog/catalog_models.dart';

class PackagesPage extends ConsumerStatefulWidget {
  const PackagesPage({super.key});

  @override
  ConsumerState<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends ConsumerState<PackagesPage> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packages = ref.watch(allServicePackagesProvider);

    return Scaffold(
      body: SafeArea(
        child: packages.when(
          loading: () => const GlowLoading(message: 'Paketler yükleniyor'),
          error: (error, _) => PackagesCatalogError(
            message: error.toString(),
            onRetry: () => ref.invalidate(allServicePackagesProvider),
          ),
          data: (items) => PackagesCatalogContent(
            packages: mapCatalogPackages(items),
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

class PackagesCatalogContent extends StatelessWidget {
  const PackagesCatalogContent({
    super.key,
    required this.packages,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
  });

  final List<CatalogPackage> packages;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final visible = packages.where((item) => item.matches(query)).toList();
    return GlowResponsivePage(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
      child: ListView(
        children: [
          const GlowPageTop(
            title: 'Paketler',
            subtitle: 'Seanslarını gerçek katalog paketleriyle planla.',
            action: GlowMark(icon: Icons.inventory_2_outlined),
          ),
          GlowSearchBar(
            hintText: 'Paket veya hizmet ara',
            controller: searchController,
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 14),
          GlowSectionHeader(
            title: 'Paket listesi',
            subtitle: '${visible.length} paket gösteriliyor',
          ),
          const SizedBox(height: 12),
          if (packages.isEmpty)
            const PackagesCatalogEmpty()
          else if (visible.isEmpty)
            const GlowEmptyState(
              title: 'Aramana uygun paket yok',
              message: 'Arama metnini değiştirerek tekrar dene.',
              icon: Icons.search_off,
            )
          else
            for (final package in visible) ...[
              GlowPackageCard(
                title: package.name,
                description: package.description ?? 'Ayrıntılar için dokun.',
                price: package.priceText,
                sessions: package.totalSession == null
                    ? null
                    : '${package.totalSession} seans',
                image: package.image,
                semanticLabel: '${package.name} görseli',
                onTap: package.id == null || package.serviceId == null
                    ? null
                    : () => AppNavigation.go(
                          context,
                          '/packages/${package.serviceId}/${package.id}'
                          '?origin=catalog',
                        ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class PackagesCatalogEmpty extends StatelessWidget {
  const PackagesCatalogEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlowEmptyState(
      title: 'Paket bulunamadı',
      message: 'Aktif paket geldiğinde burada görünür.',
      icon: Icons.inventory_2_outlined,
    );
  }
}

class PackagesCatalogError extends StatelessWidget {
  const PackagesCatalogError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GlowError(message: message, onRetry: onRetry);
  }
}
