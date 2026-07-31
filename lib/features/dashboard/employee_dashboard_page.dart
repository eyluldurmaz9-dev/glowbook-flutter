import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../appointment/booking_models.dart';
import '../employee/employee_dashboard_models.dart';

class EmployeeDashboardPage extends ConsumerStatefulWidget {
  const EmployeeDashboardPage({super.key});

  @override
  ConsumerState<EmployeeDashboardPage> createState() =>
      _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends ConsumerState<EmployeeDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedDate = BookingDateUtils.today();
  int? _updatingAppointmentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: SafeArea(child: GlowLoading(message: 'Oturum kontrol ediliyor')),
      ),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: GlowError(
            title: 'Oturum kontrol edilemedi',
            message: employeeAppointmentSafeError(error),
            onRetry: () =>
                ref.read(authControllerProvider.notifier).loadSession(),
          ),
        ),
      ),
      data: (session) {
        final role = session?.role?.toUpperCase();
        final employeeId = session?.employeeId;
        final allowed = role == 'EMPLOYEE' || role == 'ADMIN';
        if (!allowed || employeeId == null || employeeId.isEmpty) {
          return Scaffold(
            body: SafeArea(
              child: GlowResponsivePage(
                child: GlowError(
                  title: 'Personel yetkisi gerekli',
                  message:
                      'Bu alan yalnızca yetkili personel hesaplarıyla açılabilir.',
                  onRetry: () => context.go(AppRoutes.login),
                ),
              ),
            ),
          );
        }
        return _EmployeeDashboardShell(
          employeeId: employeeId,
          employeeName: session?.fullName ?? 'Personel',
          selectedDate: _selectedDate,
          tabController: _tabController,
          updatingAppointmentId: _updatingAppointmentId,
          onDateChanged: (date) => setState(() => _selectedDate = date),
          onStatusUpdate: _updateAppointmentStatus,
          onLogout: _logout,
        );
      },
    );
  }

  Future<void> _updateAppointmentStatus(
    EmployeeAppointmentsQuery query,
    Map<String, dynamic> appointment,
    String action,
  ) async {
    final appointmentId = _intValue(appointment['appointmentId']);
    if (appointmentId == null || _updatingAppointmentId != null) return;
    setState(() => _updatingAppointmentId = appointmentId);
    try {
      final backend = ref.read(glowBackendServiceProvider);
      if (action == 'approve') {
        await backend.approveAppointment(appointmentId);
      } else if (action == 'complete') {
        await backend.completeAppointment(appointmentId);
      }
      ref.invalidate(employeeAppointmentsProvider(query));
      if (!mounted) return;
      GlowSnackBar.showSuccess(
        context,
        action == 'approve' ? 'Randevu onaylandı' : 'Randevu tamamlandı',
      );
    } catch (error) {
      if (!mounted) return;
      GlowSnackBar.showError(context, employeeAppointmentSafeError(error));
    } finally {
      if (mounted) setState(() => _updatingAppointmentId = null);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.welcome);
  }
}

class _EmployeeDashboardShell extends ConsumerWidget {
  const _EmployeeDashboardShell({
    required this.employeeId,
    required this.employeeName,
    required this.selectedDate,
    required this.tabController,
    required this.updatingAppointmentId,
    required this.onDateChanged,
    required this.onStatusUpdate,
    required this.onLogout,
  });

  final String employeeId;
  final String employeeName;
  final DateTime selectedDate;
  final TabController tabController;
  final int? updatingAppointmentId;
  final ValueChanged<DateTime> onDateChanged;
  final Future<void> Function(
    EmployeeAppointmentsQuery query,
    Map<String, dynamic> appointment,
    String action,
  ) onStatusUpdate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = EmployeeWeekRange.from(selectedDate);
    final query = EmployeeAppointmentsQuery(
      employeeId: employeeId,
      startDate: week.startText,
      endDate: week.endText,
    );
    final appointmentsState = ref.watch(employeeAppointmentsProvider(query));
    final workingHoursState = ref.watch(workingHoursProvider);

    return Scaffold(
      appBar: GlowAppBar(
        title: 'Personel Paneli',
        actions: [
          IconButton(
            tooltip: 'Oturumu kapat',
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: GlowResponsivePage(
          maxWidth: 1180,
          child: appointmentsState.when(
            loading: () => const GlowLoading(message: 'Takvim yükleniyor'),
            error: (error, _) => GlowError(
              title: 'Program yüklenemedi',
              message: employeeAppointmentSafeError(error),
              onRetry: () =>
                  ref.invalidate(employeeAppointmentsProvider(query)),
            ),
            data: (appointments) {
              final daily = employeeAppointmentsForDate(
                appointments,
                selectedDate,
              );
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(employeeAppointmentsProvider(query));
                  ref.invalidate(workingHoursProvider);
                },
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    GlowPageTop(
                      title: 'Hoş geldin, $employeeName',
                      subtitle:
                          'Günlük randevularını, haftalık takvimini ve çalışma düzenini buradan yönet.',
                      action: const GlowMark(icon: Icons.badge_outlined),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _EmployeeStats(
                      dailyCount: daily.length,
                      weeklyCount: appointments.length,
                      pendingCount: appointments
                          .where((item) =>
                              item['status']?.toString().toUpperCase() ==
                              'PENDING')
                          .length,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _DateStrip(
                      days: week.days,
                      selectedDate: selectedDate,
                      appointments: appointments,
                      onDateChanged: onDateChanged,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TabBar(
                      controller: tabController,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Bugün'),
                        Tab(text: 'Haftalık'),
                        Tab(text: 'Çalışma Saatleri'),
                        Tab(text: 'Profil'),
                      ],
                    ),
                    SizedBox(
                      height:
                          MediaQuery.sizeOf(context).width > 760 ? 620 : 720,
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          _AppointmentList(
                            title: 'Günlük randevular',
                            emptyTitle: 'Bugün için randevu yok',
                            appointments: daily,
                            query: query,
                            updatingAppointmentId: updatingAppointmentId,
                            onStatusUpdate: onStatusUpdate,
                          ),
                          _WeeklyCalendar(
                            week: week,
                            appointments: appointments,
                            query: query,
                            updatingAppointmentId: updatingAppointmentId,
                            onStatusUpdate: onStatusUpdate,
                          ),
                          _WorkingHoursPanel(state: workingHoursState),
                          _EmployeeProfilePanel(
                            employeeId: employeeId,
                            employeeName: employeeName,
                            onLogout: onLogout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmployeeStats extends StatelessWidget {
  const _EmployeeStats({
    required this.dailyCount,
    required this.weeklyCount,
    required this.pendingCount,
  });

  final int dailyCount;
  final int weeklyCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return GridView.count(
          crossAxisCount: wide ? 3 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: wide ? 2.2 : 3.0,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          children: [
            GlowStatCard(
              title: 'Bugünkü Randevular',
              value: dailyCount.toString(),
              icon: Icons.event_available_outlined,
            ),
            GlowStatCard(
              title: 'Haftalık Program',
              value: weeklyCount.toString(),
              icon: Icons.calendar_month_outlined,
            ),
            GlowStatCard(
              title: 'Onay Bekleyen',
              value: pendingCount.toString(),
              icon: Icons.pending_actions_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.days,
    required this.selectedDate,
    required this.appointments,
    required this.onDateChanged,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final List<Map<String, dynamic>> appointments;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = BookingDateUtils.formatDate(day) ==
              BookingDateUtils.formatDate(selectedDate);
          final count = employeeAppointmentsForDate(appointments, day).length;
          return Semantics(
            button: true,
            selected: selected,
            label: '${BookingDateUtils.dayLabel(day)} günü, $count randevu',
            child: ChoiceChip(
              selected: selected,
              onSelected: (_) => onDateChanged(day),
              label: SizedBox(
                width: 72,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(BookingDateUtils.dayLabel(day)),
                    Text(day.day.toString().padLeft(2, '0')),
                    Text('$count randevu'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WeeklyCalendar extends StatelessWidget {
  const _WeeklyCalendar({
    required this.week,
    required this.appointments,
    required this.query,
    required this.updatingAppointmentId,
    required this.onStatusUpdate,
  });

  final EmployeeWeekRange week;
  final List<Map<String, dynamic>> appointments;
  final EmployeeAppointmentsQuery query;
  final int? updatingAppointmentId;
  final Future<void> Function(
    EmployeeAppointmentsQuery query,
    Map<String, dynamic> appointment,
    String action,
  ) onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      itemCount: week.days.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final day = week.days[index];
        final dayItems = employeeAppointmentsForDate(appointments, day);
        return GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${BookingDateUtils.dayLabel(day)} ${BookingDateUtils.formatDate(day)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (dayItems.isEmpty)
                const Text('Bu gün için randevu yok')
              else
                for (final item in dayItems) ...[
                  _AppointmentTile(
                    appointment: item,
                    query: query,
                    updatingAppointmentId: updatingAppointmentId,
                    onStatusUpdate: onStatusUpdate,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.title,
    required this.emptyTitle,
    required this.appointments,
    required this.query,
    required this.updatingAppointmentId,
    required this.onStatusUpdate,
  });

  final String title;
  final String emptyTitle;
  final List<Map<String, dynamic>> appointments;
  final EmployeeAppointmentsQuery query;
  final int? updatingAppointmentId;
  final Future<void> Function(
    EmployeeAppointmentsQuery query,
    Map<String, dynamic> appointment,
    String action,
  ) onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return GlowEmptyState(title: emptyTitle);
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      itemCount: appointments.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(title, style: Theme.of(context).textTheme.titleMedium);
        }
        return _AppointmentTile(
          appointment: appointments[index - 1],
          query: query,
          updatingAppointmentId: updatingAppointmentId,
          onStatusUpdate: onStatusUpdate,
        );
      },
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({
    required this.appointment,
    required this.query,
    required this.updatingAppointmentId,
    required this.onStatusUpdate,
  });

  final Map<String, dynamic> appointment;
  final EmployeeAppointmentsQuery query;
  final int? updatingAppointmentId;
  final Future<void> Function(
    EmployeeAppointmentsQuery query,
    Map<String, dynamic> appointment,
    String action,
  ) onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    final appointmentId = _intValue(appointment['appointmentId']);
    final status = appointment['status']?.toString().toUpperCase();
    final loading =
        appointmentId != null && updatingAppointmentId == appointmentId;
    final customerName = [
      appointment['customerName'],
      appointment['customerSurname'],
    ]
        .where((item) => item != null && item.toString().trim().isNotEmpty)
        .join(' ');
    final time = [
      appointment['appointmentDate'],
      BookingDateUtils.normalizeTime(appointment['appointmentTime']),
    ].whereType<String>().join(' ');
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GlowMark(icon: Icons.calendar_today_outlined, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['serviceName']?.toString() ?? 'Randevu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      customerName.isEmpty
                          ? appointment['optionName']?.toString() ?? 'Hizmet'
                          : '$customerName • ${appointment['optionName'] ?? 'Hizmet'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.action,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  GlowPill(label: employeeAppointmentStatusLabel(status)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (status == 'PENDING')
                GlowButton(
                  label: 'Onayla',
                  icon: Icons.check_circle_outline,
                  loading: loading,
                  onPressed: loading
                      ? null
                      : () => onStatusUpdate(query, appointment, 'approve'),
                ),
              if (status == 'APPROVED')
                GlowButton(
                  label: 'Tamamlandı',
                  icon: Icons.done_all_outlined,
                  loading: loading,
                  onPressed: loading
                      ? null
                      : () => onStatusUpdate(query, appointment, 'complete'),
                ),
              GlowButton(
                label: 'Detay',
                icon: Icons.info_outline,
                variant: GlowButtonVariant.outlined,
                onPressed: () => _showAppointmentDetail(context, appointment),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetail(
    BuildContext context,
    Map<String, dynamic> appointment,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevu Detayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailLine('Hizmet', appointment['serviceName']),
            _DetailLine('Seçenek', appointment['optionName']),
            _DetailLine('Müşteri', appointment['customerName']),
            _DetailLine('Telefon', appointment['phone']),
            _DetailLine('Tarih', appointment['appointmentDate']),
            _DetailLine(
              'Saat',
              BookingDateUtils.normalizeTime(appointment['appointmentTime']),
            ),
            _DetailLine(
              'Durum',
              employeeAppointmentStatusLabel(appointment['status']),
            ),
          ],
        ),
        actions: [
          GlowButton(
            label: 'Kapat',
            variant: GlowButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final text = value?.toString().trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text('$label: ${text == null || text.isEmpty ? '-' : text}'),
    );
  }
}

class _WorkingHoursPanel extends StatelessWidget {
  const _WorkingHoursPanel({required this.state});

  final AsyncValue<List<Map<String, dynamic>>> state;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const GlowLoading(message: 'Çalışma saatleri yükleniyor'),
      error: (error, _) => GlowError(
        title: 'Çalışma saatleri alınamadı',
        message: employeeAppointmentSafeError(error),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const GlowEmptyState(title: 'Çalışma saati bulunamadı');
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                'Çalışma saatleri',
                style: Theme.of(context).textTheme.titleMedium,
              );
            }
            final item = items[index - 1];
            final active = item['active'] != false;
            return GlowCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  active ? Icons.schedule : Icons.event_busy_outlined,
                  color: active ? AppColors.action : AppColors.secondaryText,
                ),
                title: Text(item['dayOfWeek']?.toString() ?? 'Gün'),
                subtitle: Text(
                  '${item['startTime'] ?? '-'} - ${item['endTime'] ?? '-'}',
                ),
                trailing: Text(active ? 'Aktif' : 'Kapalı'),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmployeeProfilePanel extends StatelessWidget {
  const _EmployeeProfilePanel({
    required this.employeeId,
    required this.employeeName,
    required this.onLogout,
  });

  final String employeeId;
  final String employeeName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      children: [
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GlowMark(icon: Icons.person_outline, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(employeeName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Personel ID: $employeeId',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GlowButton(
                label: 'Oturumu kapat',
                icon: Icons.logout,
                variant: GlowButtonVariant.outlined,
                onPressed: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
