import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  String _category = 'Tümü';

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final categories = [
      'Tümü',
      'Cilt bakımı',
      'Tırnak',
      'Kaş & kirpik',
      'Vücut'
    ];

    return Scaffold(
      body: SafeArea(
        child: services.when(
          loading: () => const GlowLoading(message: 'Hizmetler yükleniyor'),
          error: (error, _) => GlowError(
            message: error.toString(),
            onRetry: () => ref.invalidate(servicesProvider),
          ),
          data: (items) {
            return GlowResponsivePage(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
              child: ListView(
                children: [
                  GlowPageTop(
                    title: 'Hizmetleri keşfet',
                    subtitle: 'Kendin için iyi hissettiren dokunuşu bul.',
                    action: GlowIconButton(
                      icon: Icons.tune,
                      tooltip: 'Filtreler',
                      onPressed: () {},
                    ),
                  ),
                  const GlowSearchBar(hintText: 'Hizmet veya salon ara'),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final category in categories) ...[
                          ChoiceChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (_) =>
                                setState(() => _category = category),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "İstanbul'da ${items.length} hizmet",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Önerilen'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (items.isEmpty)
                    const GlowEmptyState(title: 'Hizmet bulunamadı')
                  else
                    for (final service in items) ...[
                      _ServiceRow(service: service),
                      const SizedBox(height: 12),
                    ],
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

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final Map<String, dynamic> service;

  @override
  Widget build(BuildContext context) {
    final serviceId = service['serviceId'];
    final title = service['serviceName']?.toString() ?? 'Hizmet';
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap:
          serviceId == null ? null : () => context.go('/services/$serviceId'),
      child: GlowCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.petal,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.spa_outlined,
                  color: AppColors.primary, size: 34),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 5),
                  Text(
                    service['description']?.toString() ??
                        'Uzman dokunuşuyla premium bakım deneyimi.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          color: AppColors.secondaryText, size: 12),
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
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Detay',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.primary),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
