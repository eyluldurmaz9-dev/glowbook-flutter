import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class CustomerDashboardPage extends ConsumerWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final customerId = session?.customerId;

    return Scaffold(
      body: SafeArea(
        child: customerId == null
            ? const GlowEmptyState(title: 'Müşteri oturumu bulunamadı')
            : GlowResponsivePage(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 28),
                child: _CustomerStats(customerId: customerId),
              ),
      ),
    );
  }
}

class _CustomerStats extends ConsumerWidget {
  const _CustomerStats({required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments =
        ref.watch(customerUpcomingAppointmentsProvider(customerId));
    final packages = ref.watch(customerPackagesProvider(customerId));
    final notifications = ref.watch(notificationsProvider(customerId));

    return ListView(
      children: [
        const GlowPageTop(
          title: 'Müşteri Paneli',
          subtitle: 'Randevuların, paketlerin ve bildirimlerin tek yerde.',
          action: GlowMark(icon: Icons.notifications_outlined),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 700;
            return GridView.count(
              crossAxisCount: wide ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: wide ? 2.6 : 3.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _AsyncStat(
                  value: appointments,
                  title: 'Yaklaşan Randevularım',
                  icon: Icons.calendar_today_outlined,
                ),
                _AsyncStat(
                  value: packages,
                  title: 'Paketlerim',
                  icon: Icons.inventory_2_outlined,
                ),
                _AsyncStat(
                  value: notifications,
                  title: 'Bildirimler',
                  icon: Icons.notifications_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        GlowCard(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const GlowMark(icon: Icons.inventory_2_outlined, size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Işıltı Paketi',
                            style: Theme.of(context).textTheme.titleSmall),
                        Text('Hydrafacial · 6 seans',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const GlowPill(
                    label: 'Aktif',
                    color: Color(0xFF96751F),
                    background: Color(0xFFFFF7DF),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(child: _MiniStat(value: '6', label: 'Toplam Seans')),
                  Expanded(child: _MiniStat(value: '2', label: 'Kullanılan')),
                  Expanded(
                    child: _MiniStat(
                      value: '4',
                      label: 'Kalan',
                      highlight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  value: .33,
                  minHeight: 8,
                  backgroundColor: Color(0xFFF7E9EE),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text('Paketinizin %33’ünü tamamladınız.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 18),
        appointments.when(
          loading: () => const GlowLoading(message: 'Randevular yükleniyor'),
          error: (error, _) => GlowError(message: error.toString()),
          data: (items) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yaklaşan Randevularım',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const GlowEmptyState(title: 'Yaklaşan randevu yok')
              else
                for (final item in items) ...[
                  GlowAppointmentCard(
                    title: item['serviceName']?.toString() ?? 'Randevu',
                    time:
                        '${item['appointmentDate'] ?? ''} ${item['appointmentTime'] ?? ''}',
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: highlight ? AppColors.primary : AppColors.primaryText,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _AsyncStat extends StatelessWidget {
  const _AsyncStat({
    required this.value,
    required this.title,
    required this.icon,
  });

  final AsyncValue<List<Map<String, dynamic>>> value;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => GlowStatCard(title: title, value: '...', icon: icon),
      error: (error, _) =>
          GlowStatCard(title: title, value: '!', icon: Icons.error_outline),
      data: (items) => GlowStatCard(
          title: title, value: items.length.toString(), icon: icon),
    );
  }
}
