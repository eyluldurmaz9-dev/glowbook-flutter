import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../appointment/booking_models.dart';

class CustomerDashboardPage extends ConsumerStatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  ConsumerState<CustomerDashboardPage> createState() =>
      _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends ConsumerState<CustomerDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).asData?.value;
    final customerId = session?.customerId;

    return Scaffold(
      body: SafeArea(
        child: customerId == null
            ? GlowResponsivePage(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 28),
                child: GlowError(
                  message: 'Müşteri oturumu bulunamadı.',
                  onRetry: () => AppNavigation.go(context, AppRoutes.login),
                ),
              )
            : GlowResponsivePage(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 28),
                child: RefreshIndicator(
                  onRefresh: () async => _refresh(customerId),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlowPageTop(
                          title: 'Müşteri Paneli',
                          subtitle:
                              'Randevuların, paketlerin ve bildirimlerin tek yerde.',
                          action: GlowIconButton(
                            tooltip: 'Yenile',
                            icon: Icons.refresh,
                            onPressed: () => _refresh(customerId),
                          ),
                        ),
                        _StatsGrid(customerId: customerId),
                        const SizedBox(height: 16),
                        GlowCard(
                          padding: const EdgeInsets.all(8),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabs: const [
                              Tab(text: 'Yaklaşan'),
                              Tab(text: 'Geçmiş'),
                              Tab(text: 'Paketlerim'),
                              Tab(text: 'Bildirimler'),
                              Tab(text: 'Profil'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 620,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _AppointmentList(
                                value: ref.watch(
                                  customerUpcomingAppointmentsProvider(
                                    customerId,
                                  ),
                                ),
                                emptyTitle: 'Yaklaşan randevu yok',
                                canCancel: true,
                                busy: _busy,
                                onRefresh: () => _refresh(customerId),
                                onCancel: _cancelAppointment,
                              ),
                              _AppointmentList(
                                value: ref.watch(
                                  customerPastAppointmentsProvider(customerId),
                                ),
                                emptyTitle: 'Geçmiş randevu yok',
                                canCancel: false,
                                busy: _busy,
                                onRefresh: () => _refresh(customerId),
                                onCancel: _cancelAppointment,
                              ),
                              _PackageList(
                                value: ref.watch(
                                  customerPackagesProvider(customerId),
                                ),
                                onRefresh: () => ref.invalidate(
                                  customerPackagesProvider(customerId),
                                ),
                              ),
                              _NotificationList(
                                value: ref
                                    .watch(notificationsProvider(customerId)),
                                onRefresh: () => _refresh(customerId),
                                onMarkRead: _markNotificationRead,
                              ),
                              _ProfileSummary(
                                value: ref.watch(profileProvider),
                                onOpenProfile: () => AppNavigation.go(
                                  context,
                                  AppRoutes.profile,
                                ),
                                onLogout: () async {
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .logout();
                                  if (context.mounted) {
                                    AppNavigation.go(context, AppRoutes.login);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _refresh(int customerId) async {
    ref.invalidate(customerUpcomingAppointmentsProvider(customerId));
    ref.invalidate(customerPastAppointmentsProvider(customerId));
    ref.invalidate(customerPackagesProvider(customerId));
    ref.invalidate(notificationsProvider(customerId));
    ref.invalidate(unreadNotificationsProvider(customerId));
    ref.invalidate(profileProvider);
  }

  Future<void> _cancelAppointment(Map<String, dynamic> appointment) async {
    final appointmentId = _intValue(appointment['appointmentId']);
    final customerId =
        ref.read(authControllerProvider).asData?.value?.customerId;
    if (appointmentId == null || customerId == null) return;

    final confirmed = await GlowDialog.showConfirmation(
      context,
      title: 'Randevuyu iptal et',
      message: 'Bu randevuyu iptal etmek istediğine emin misin?',
      confirmLabel: 'İptal Et',
      danger: true,
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(glowBackendServiceProvider).cancelAppointment(
            appointmentId,
            cancellationReason: 'Müşteri panelinden iptal edildi',
          );
      ref.invalidate(customerUpcomingAppointmentsProvider(customerId));
      ref.invalidate(customerPastAppointmentsProvider(customerId));
      if (mounted) {
        GlowSnackBar.showSuccess(context, 'Randevu iptal edildi.');
      }
    } catch (error) {
      if (mounted) {
        GlowSnackBar.showError(context, bookingErrorMessage(error) ?? '$error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markNotificationRead(Map<String, dynamic> notification) async {
    final notificationId = _intValue(notification['notificationId']);
    final customerId =
        ref.read(authControllerProvider).asData?.value?.customerId;
    if (notificationId == null || customerId == null) return;

    try {
      await ref
          .read(glowBackendServiceProvider)
          .markNotificationAsRead(notificationId);
      ref.invalidate(notificationsProvider(customerId));
      ref.invalidate(unreadNotificationsProvider(customerId));
      if (mounted) {
        GlowSnackBar.showSuccess(
            context, 'Bildirim okundu olarak işaretlendi.');
      }
    } catch (error) {
      if (mounted) {
        GlowSnackBar.showError(context, bookingErrorMessage(error) ?? '$error');
      }
    }
  }
}

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid({required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming =
        ref.watch(customerUpcomingAppointmentsProvider(customerId));
    final past = ref.watch(customerPastAppointmentsProvider(customerId));
    final packages = ref.watch(customerPackagesProvider(customerId));
    final unread = ref.watch(unreadNotificationsProvider(customerId));

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 760;
        return GridView.count(
          crossAxisCount: wide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: wide ? 2.2 : 1.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _AsyncStat(
              value: upcoming,
              title: 'Yaklaşan',
              icon: Icons.calendar_today_outlined,
            ),
            _AsyncStat(
              value: past,
              title: 'Geçmiş',
              icon: Icons.history,
            ),
            _AsyncStat(
              value: packages,
              title: 'Paketlerim',
              icon: Icons.inventory_2_outlined,
            ),
            _AsyncStat(
              value: unread,
              title: 'Okunmamış',
              icon: Icons.notifications_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.value,
    required this.emptyTitle,
    required this.canCancel,
    required this.busy,
    required this.onRefresh,
    required this.onCancel,
  });

  final AsyncValue<List<Map<String, dynamic>>> value;
  final String emptyTitle;
  final bool canCancel;
  final bool busy;
  final VoidCallback onRefresh;
  final ValueChanged<Map<String, dynamic>> onCancel;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const GlowLoading(message: 'Randevular yükleniyor'),
      error: (error, _) => GlowError(
        message: bookingErrorMessage(error) ?? '$error',
        onRetry: onRefresh,
      ),
      data: (items) => items.isEmpty
          ? GlowEmptyState(title: emptyTitle)
          : ListView(
              children: [
                for (final item in items) ...[
                  GlowCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const GlowMark(
                              icon: Icons.calendar_today_outlined,
                              size: 40,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['serviceName']?.toString() ??
                                        'Randevu',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${item['appointmentDate'] ?? ''} ${BookingDateUtils.normalizeTime(item['appointmentTime']) ?? ''}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            GlowPill(
                              label: item['status']?.toString() ?? '-',
                              color: AppColors.action,
                              background: AppColors.roseTint,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            GlowButton(
                              label: 'Detay',
                              icon: Icons.info_outline,
                              variant: GlowButtonVariant.secondary,
                              onPressed: () =>
                                  _showAppointmentDetail(context, item),
                            ),
                            if (canCancel)
                              GlowButton(
                                label: 'İptal Et',
                                icon: Icons.cancel_outlined,
                                variant: GlowButtonVariant.outlined,
                                loading: busy,
                                onPressed: busy ? null : () => onCancel(item),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  void _showAppointmentDetail(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    GlowDialog.showInfo(
      context,
      'Randevu Detayı',
      [
        'Hizmet: ${item['serviceName'] ?? '-'}',
        'Alt hizmet: ${item['optionName'] ?? '-'}',
        'Personel: ${item['employeeName'] ?? '-'}',
        'Tarih: ${item['appointmentDate'] ?? '-'}',
        'Saat: ${BookingDateUtils.normalizeTime(item['appointmentTime']) ?? '-'}',
        'Fiyat: ${item['price'] ?? '-'}',
        'Durum: ${item['status'] ?? '-'}',
      ].join('\n'),
    );
  }
}

class _PackageList extends StatelessWidget {
  const _PackageList({required this.value, required this.onRefresh});

  final AsyncValue<List<Map<String, dynamic>>> value;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const GlowLoading(message: 'Paketler yükleniyor'),
      error: (error, _) => GlowError(
        message: bookingErrorMessage(error) ?? '$error',
        onRetry: onRefresh,
      ),
      data: (items) => items.isEmpty
          ? const GlowEmptyState(title: 'Aktif paket yok')
          : ListView(
              children: [
                for (final item in items) ...[
                  GlowCard(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const GlowMark(
                              icon: Icons.inventory_2_outlined,
                              size: 42,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['packageName']?.toString() ?? 'Paket',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    _packageSessionText(item),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (item['active'] == true)
                              const GlowPill(label: 'Aktif'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _DashboardRow(
                          label: 'Satın alma',
                          value: item['purchaseDate']?.toString() ?? '-',
                        ),
                        _DashboardRow(
                          label: 'Tutar',
                          value: item['purchasePrice']?.toString() ?? '-',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  String _packageSessionText(Map<String, dynamic> item) {
    final total = _intValue(item['totalSession']);
    final remaining = _intValue(item['remainingSession']);
    if (total == null || remaining == null) {
      return 'Kalan seans: ${item['remainingSession'] ?? '-'}';
    }
    final used = total - remaining;
    return 'Kullanılan: $used / $total • Kalan: $remaining seans';
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.value,
    required this.onRefresh,
    required this.onMarkRead,
  });

  final AsyncValue<List<Map<String, dynamic>>> value;
  final VoidCallback onRefresh;
  final ValueChanged<Map<String, dynamic>> onMarkRead;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const GlowLoading(message: 'Bildirimler yükleniyor'),
      error: (error, _) => GlowError(
        message: bookingErrorMessage(error) ?? '$error',
        onRetry: onRefresh,
      ),
      data: (items) => items.isEmpty
          ? const GlowEmptyState(title: 'Yeni bildirim yok')
          : ListView(
              children: [
                for (final item in items) ...[
                  GlowCard(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: item['read'] == true
                        ? AppColors.white
                        : AppColors.roseTint,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlowMark(
                          icon: item['read'] == true
                              ? Icons.notifications_none
                              : Icons.notifications_active_outlined,
                          size: 38,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title']?.toString() ?? 'Bildirim',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item['message']?.toString() ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                item['createdAt']?.toString() ?? '',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              if (item['read'] != true) ...[
                                const SizedBox(height: 8),
                                GlowButton(
                                  label: 'Okundu Yap',
                                  icon: Icons.done,
                                  variant: GlowButtonVariant.secondary,
                                  onPressed: () => onMarkRead(item),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.value,
    required this.onOpenProfile,
    required this.onLogout,
  });

  final AsyncValue<Map<String, dynamic>?> value;
  final VoidCallback onOpenProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const GlowLoading(message: 'Profil yükleniyor'),
      error: (error, _) =>
          GlowError(message: bookingErrorMessage(error) ?? '$error'),
      data: (profile) {
        if (profile == null) {
          return const GlowEmptyState(title: 'Profil bulunamadı');
        }
        final name = [
          profile['firstName'],
          profile['lastName'],
        ].where((value) => value != null).join(' ');
        return ListView(
          children: [
            GlowCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.blush,
                        child: Icon(
                          Icons.person_outline,
                          color: AppColors.action,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name.isEmpty ? 'GlowBook Üyesi' : name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DashboardRow(
                    label: 'Telefon',
                    value: profile['phone']?.toString() ?? '-',
                  ),
                  _DashboardRow(
                    label: 'E-posta',
                    value: profile['email']?.toString() ?? '-',
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GlowButton(
                        label: 'Profili Düzenle',
                        icon: Icons.edit_outlined,
                        onPressed: onOpenProfile,
                      ),
                      GlowButton(
                        label: 'Oturumu Kapat',
                        icon: Icons.logout,
                        variant: GlowButtonVariant.outlined,
                        onPressed: onLogout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
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
        title: title,
        value: items.length.toString(),
        icon: icon,
      ),
    );
  }
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
