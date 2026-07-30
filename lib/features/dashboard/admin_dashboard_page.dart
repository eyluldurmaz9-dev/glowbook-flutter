import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final employees = ref.watch(employeesProvider);
    final customers = ref.watch(customersProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAFC),
      body: SafeArea(
        child: Row(
          children: [
            if (wide) const _AdminSidebar(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(wide ? 30 : 18),
                child: ListView(
                  children: [
                    Row(
                      children: [
                        if (!wide) const GlowBrand(compact: true),
                        if (!wide) const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GlowEyebrow('Bugünün görünümü'),
                              const SizedBox(height: 3),
                              Text(
                                'Genel Bakış',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                'Lal Beauty Studio’nun güncel işletme özeti.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const GlowIconButton(
                          icon: Icons.notifications_outlined,
                          tooltip: 'Bildirimler',
                          onPressed: _noop,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth > 900
                            ? 4
                            : constraints.maxWidth > 560
                                ? 2
                                : 1;
                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: columns == 1 ? 3.4 : 2.15,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          children: [
                            const GlowStatCard(
                              title: 'Bugünkü randevular',
                              value: '28',
                              icon: Icons.calendar_today_outlined,
                            ),
                            const GlowStatCard(
                              title: 'Bu ay ciro',
                              value: '184K TL',
                              icon: Icons.payments_outlined,
                            ),
                            _StatFromAsync(
                              value: customers,
                              title: 'Müşteriler',
                              icon: Icons.people_outline,
                            ),
                            _StatFromAsync(
                              value: employees,
                              title: 'Personeller',
                              icon: Icons.badge_outlined,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final split = constraints.maxWidth > 820;
                        final panels = [
                          const _ChartPanel(),
                          const _SchedulePanel(),
                        ];
                        return split
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: panels[0]),
                                  const SizedBox(width: 18),
                                  Expanded(flex: 2, child: panels[1]),
                                ],
                              )
                            : Column(
                                children: [
                                  panels[0],
                                  const SizedBox(height: 18),
                                  panels[1],
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final split = constraints.maxWidth > 760;
                        return split
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _ListPanel(
                                      title: 'En çok tercih edilenler',
                                      asyncValue: services,
                                      titleKey: 'serviceName',
                                      icon: Icons.auto_awesome,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: _ListPanel(
                                      title: 'Personel performansı',
                                      asyncValue: employees,
                                      titleKey: 'firstName',
                                      icon: Icons.workspace_premium_outlined,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _ListPanel(
                                    title: 'En çok tercih edilenler',
                                    asyncValue: services,
                                    titleKey: 'serviceName',
                                    icon: Icons.auto_awesome,
                                  ),
                                  const SizedBox(height: 18),
                                  _ListPanel(
                                    title: 'Personel performansı',
                                    asyncValue: employees,
                                    titleKey: 'firstName',
                                    icon: Icons.workspace_premium_outlined,
                                  ),
                                ],
                              );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _noop() {}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar();

  @override
  Widget build(BuildContext context) {
    const items = [
      ['Genel Bakış', Icons.home_outlined],
      ['Randevular', Icons.calendar_today_outlined],
      ['Müşteriler', Icons.people_outline],
      ['Personeller', Icons.badge_outlined],
      ['Hizmetler', Icons.spa_outlined],
      ['Paketler', Icons.inventory_2_outlined],
      ['Çalışma Saatleri', Icons.schedule],
      ['Tatiller', Icons.beach_access_outlined],
      ['Bildirimler', Icons.notifications_outlined],
      ['Raporlar', Icons.bar_chart],
      ['Ayarlar', Icons.settings_outlined],
    ];
    return Container(
      width: 240,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(13, 0, 13, 30),
            child: GlowBrand(),
          ),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextButton.icon(
                onPressed: () {},
                icon: Icon(items[i][1] as IconData, size: 16),
                label: Text(items[i][0] as String),
                style: TextButton.styleFrom(
                  foregroundColor:
                      i == 0 ? AppColors.primary : AppColors.secondaryText,
                  backgroundColor:
                      i == 0 ? const Color(0xFFFFF0F5) : Colors.transparent,
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const Spacer(),
          const GlowSoftNotice(
            title: 'Yardım Merkezi',
            message: 'Desteğe mi ihtiyacınız var?',
          ),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel();

  @override
  Widget build(BuildContext context) {
    final values = [54, 67, 48, 82, 61, 93, 73];
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return GlowCard(
      padding: const EdgeInsets.all(21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Haftalık randevu görünümü',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 22),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FractionallySizedBox(
                          widthFactor: .55,
                          child: Container(
                            height: values[i] * 1.7,
                            decoration: BoxDecoration(
                              color:
                                  i == 5 ? AppColors.primary : AppColors.blush,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                                bottom: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(days[i],
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['09:30', 'İpek kirpik · Derya K.', 'Elif Yılmaz · 90 dk'],
      ['11:00', 'Hydrafacial · Zeynep A.', 'Dilara Şen · 60 dk'],
      ['14:30', 'Kalıcı oje · Melis T.', 'İrem Aydın · 45 dk'],
    ];
    return GlowCard(
      padding: const EdgeInsets.all(21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bugünün programı',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          for (final row in rows) ...[
            Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(row[0],
                      style: Theme.of(context).textTheme.labelSmall),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4F7),
                      border: const Border(
                        left: BorderSide(color: AppColors.primary, width: 3),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row[1],
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(row[2],
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({
    required this.title,
    required this.asyncValue,
    required this.titleKey,
    required this.icon,
  });

  final String title;
  final AsyncValue<List<Map<String, dynamic>>> asyncValue;
  final String titleKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(21),
      child: asyncValue.when(
        loading: () => const GlowLoading(message: 'Yükleniyor'),
        error: (error, _) => GlowError(message: error.toString()),
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            for (final item in items.take(4)) ...[
              Row(
                children: [
                  GlowMark(icon: icon, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item[titleKey]?.toString() ??
                          item['employeeId']?.toString() ??
                          '-',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const GlowPill(label: '+%12'),
                ],
              ),
              const SizedBox(height: 13),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatFromAsync extends StatelessWidget {
  const _StatFromAsync({
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
