import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class AppointmentPage extends ConsumerStatefulWidget {
  const AppointmentPage({super.key});

  @override
  ConsumerState<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends ConsumerState<AppointmentPage> {
  bool _quick = true;
  String _time = '14:30';

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final customerId = auth.valueOrNull?.customerId;
    final appointments = customerId == null
        ? null
        : ref.watch(customerUpcomingAppointmentsProvider(customerId));

    return Scaffold(
      body: SafeArea(
        child: GlowResponsivePage(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
          child: ListView(
            children: [
              GlowPageTop(
                title: 'Randevu oluştur',
                subtitle: 'Kendin için ayırdığın zaman.',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlowIconButton(
                      icon: Icons.calendar_month_outlined,
                      tooltip: 'Takvim',
                      onPressed: () =>
                          AppNavigation.go(context, AppRoutes.calendar),
                    ),
                    const SizedBox(width: 8),
                    GlowIconButton(
                      icon: Icons.badge_outlined,
                      tooltip: 'Personel seç',
                      onPressed: () => AppNavigation.go(
                        context,
                        AppRoutes.employeeSelection,
                      ),
                    ),
                  ],
                ),
              ),
              const _BookingFlow(),
              const SizedBox(height: 18),
              const GlowSoftNotice(
                title: 'Seçimini istediğin zaman değiştirebilirsin.',
                message: 'Çalışma saatleri 09:00-18:00 arasındadır.',
              ),
              const SizedBox(height: 18),
              const _SelectionTile(
                title: 'Hydrafacial',
                subtitle: '60 dk · Ödeme salonda yapılır',
                icon: Icons.spa_outlined,
                selected: true,
              ),
              const SizedBox(height: 10),
              const _SelectionTile(
                title: 'Klasik Hydrafacial',
                subtitle: 'Temizleme · Peeling · Nemlendirme',
                icon: Icons.schedule,
              ),
              const SizedBox(height: 10),
              const _SelectionTile(
                title: 'Tek seans',
                subtitle: 'Paket kullanmadan randevu',
                icon: Icons.inventory_2_outlined,
                selected: true,
              ),
              const SizedBox(height: 10),
              const _SelectionTile(
                title: 'Elif Yılmaz',
                subtitle: 'Uzman estetisyen · 4.9 puan',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              Text('Tarih', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              const _DateRow(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      const TextSpan(
                        text: 'Çalışma saatleri ',
                        children: [
                          TextSpan(
                            text: '09:00-18:00',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Switch(
                    value: _quick,
                    activeThumbColor: AppColors.white,
                    activeTrackColor: AppColors.primary,
                    onChanged: (value) => setState(() => _quick = value),
                  ),
                  Text('İlk müsait',
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 12),
              _TimeGrid(
                selected: _time,
                onSelected: (value) => setState(() => _time = value),
              ),
              const SizedBox(height: 18),
              GlowButton(
                label: 'Randevuyu Onayla',
                icon: Icons.calendar_today_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Randevunuz başarıyla oluşturuldu.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text('Yaklaşan Randevularım',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (customerId == null)
                const GlowEmptyState(
                  title: 'Oturum gerekli',
                  message: 'Randevularını görmek için giriş yapmalısın.',
                  icon: Icons.lock_outline,
                )
              else
                appointments!.when(
                  loading: () =>
                      const GlowLoading(message: 'Randevular yükleniyor'),
                  error: (error, _) => GlowError(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(
                      customerUpcomingAppointmentsProvider(customerId),
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? const GlowEmptyState(title: 'Yaklaşan randevu yok')
                      : Column(
                          children: [
                            for (final appointment in items) ...[
                              GlowAppointmentCard(
                                title: appointment['serviceName']?.toString() ??
                                    'Randevu',
                                time:
                                    '${appointment['appointmentDate'] ?? ''} ${appointment['appointmentTime'] ?? ''}',
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GlowBottomNavigationBar(
        currentIndex: 2,
        onTap: (index) => AppNavigation.goBottomTab(context, index),
      ),
    );
  }
}

class _BookingFlow extends StatelessWidget {
  const _BookingFlow();

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Hizmet',
      'Alt hizmet',
      'Paket',
      'Personel',
      'Tarih',
      'Saat'
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor:
                      i <= 3 ? AppColors.primary : const Color(0xFFF6EDF1),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i <= 3 ? AppColors.white : AppColors.secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  steps[i],
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: i <= 3
                            ? AppColors.primary
                            : AppColors.secondaryText,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: GlowCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GlowMark(icon: icon, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow();

  @override
  Widget build(BuildContext context) {
    final days = ['Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            Container(
              width: 55,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: i == 1 ? AppColors.primary : AppColors.white,
                border: Border.all(
                  color: i == 1 ? AppColors.primary : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    '${12 + i}',
                    style: TextStyle(
                      color: i == 1 ? AppColors.white : AppColors.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    days[i],
                    style: TextStyle(
                      color: i == 1 ? AppColors.white : AppColors.secondaryText,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _TimeGrid extends StatelessWidget {
  const _TimeGrid({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final times = ['09:00', '10:30', '12:00', '13:30', '14:30', '16:00'];
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      children: [
        for (final time in times)
          OutlinedButton(
            onPressed: () => onSelected(time),
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  selected == time ? AppColors.primary : AppColors.white,
              foregroundColor:
                  selected == time ? AppColors.white : AppColors.secondaryText,
              side: BorderSide(
                color: selected == time ? AppColors.primary : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(time),
          ),
      ],
    );
  }
}
