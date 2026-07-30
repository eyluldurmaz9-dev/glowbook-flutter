import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class ServiceDetailPage extends ConsumerWidget {
  const ServiceDetailPage({super.key, required this.serviceId});

  final int serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Container(
                height: 210,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blush, AppColors.petal],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 72),
              ),
              const SizedBox(height: 22),
              const GlowEyebrow('Hizmet detayı'),
              const SizedBox(height: 8),
              Text(
                'Premium bakım deneyimi',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Uzmanlarımızın özenli dokunuşlarıyla kendine ayırdığın zamanı güzelleştir. Paket seçeneklerini ve uygun personeli aşağıda inceleyebilirsin.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GlowPill(label: '60 dk'),
                  GlowPill(label: 'Ödeme salonda'),
                  GlowPill(
                    label: 'Popüler',
                    color: Color(0xFF96751F),
                    background: Color(0xFFFFF7DF),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _Section(
                title: 'Alt hizmet',
                child: options.when(
                  loading: () => const GlowLoading(message: 'Seçenekler'),
                  error: (error, _) => GlowError(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(serviceOptionsProvider(serviceId)),
                  ),
                  data: (items) => _ListBlock(
                    items: items,
                    emptyTitle: 'Seçenek bulunamadı',
                    titleKey: 'optionName',
                    icon: Icons.schedule,
                    subtitleBuilder: (item) => '${item['price'] ?? '-'} TL',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Paket seçenekleri',
                child: packages.when(
                  loading: () => const GlowLoading(message: 'Paketler'),
                  error: (error, _) => GlowError(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(servicePackagesProvider(serviceId)),
                  ),
                  data: (items) => _ListBlock(
                    items: items,
                    emptyTitle: 'Paket bulunamadı',
                    titleKey: 'packageName',
                    icon: Icons.inventory_2_outlined,
                    subtitleBuilder: (item) =>
                        '${item['totalSession'] ?? '-'} seans · ${item['price'] ?? '-'} TL',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Personel',
                child: employees.when(
                  loading: () => const GlowLoading(message: 'Personel'),
                  error: (error, _) => GlowError(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(employeesByServiceProvider(serviceId)),
                  ),
                  data: (items) => _ListBlock(
                    items: items,
                    emptyTitle: 'Personel bulunamadı',
                    titleKey: 'employeeName',
                    icon: Icons.badge_outlined,
                    subtitleBuilder: (item) =>
                        item['employeeId']?.toString() ?? '',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GlowButton(
                label: 'Randevu Oluştur',
                icon: Icons.calendar_today_outlined,
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

class _ListBlock extends StatelessWidget {
  const _ListBlock({
    required this.items,
    required this.emptyTitle,
    required this.titleKey,
    required this.subtitleBuilder,
    required this.icon,
  });

  final List<Map<String, dynamic>> items;
  final String emptyTitle;
  final String titleKey;
  final IconData icon;
  final String Function(Map<String, dynamic>) subtitleBuilder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return GlowEmptyState(title: emptyTitle);
    }
    return Column(
      children: [
        for (final item in items) ...[
          GlowCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GlowMark(icon: icon, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item[titleKey]?.toString() ?? '-',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(subtitleBuilder(item),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 19),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
