import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final employees = ref.watch(employeesProvider);

    return Scaffold(
      appBar: const GlowAppBar(title: 'Yönetici Paneli'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlowButton(
            label: 'Personel Listesi',
            icon: Icons.badge_outlined,
            onPressed: () => AppNavigation.go(context, AppRoutes.employee),
          ),
          const SizedBox(height: 16),
          _SummaryTile(
            title: 'Hizmet API',
            value: services.when(
              data: (items) => '${items.length} hizmet',
              error: (error, _) => error.toString(),
              loading: () => 'Yükleniyor',
            ),
          ),
          const SizedBox(height: 12),
          _SummaryTile(
            title: 'Personel API',
            value: employees.when(
              data: (items) => '${items.length} personel',
              error: (error, _) => error.toString(),
              loading: () => 'Yükleniyor',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(value),
        ],
      ),
    );
  }
}
