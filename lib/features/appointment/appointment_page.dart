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
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final customerId = auth.valueOrNull?.customerId;
    final appointments = customerId == null
        ? null
        : ref.watch(customerUpcomingAppointmentsProvider(customerId));
    final services = ref.watch(servicesProvider);

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
              services.when(
                loading: () => const GlowSkeleton(height: 82),
                error: (error, _) => GlowError(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(servicesProvider),
                ),
                data: (items) => _SelectionTile(
                  title: _stringValue(items, 'serviceName') ?? 'Hizmet seç',
                  subtitle: 'Backend katalog servisinden alınır',
                  icon: Icons.spa_outlined,
                  selected: items.isNotEmpty,
                ),
              ),
              const SizedBox(height: 10),
              services.when(
                loading: () => const GlowSkeleton(height: 82),
                error: (error, _) => GlowError(message: error.toString()),
                data: (items) {
                  final serviceId = _intValue(items, 'serviceId');
                  if (serviceId == null) {
                    return const GlowEmptyState(title: 'Alt hizmet bulunamadı');
                  }
                  final options = ref.watch(serviceOptionsProvider(serviceId));
                  return options.when(
                    loading: () => const GlowSkeleton(height: 82),
                    error: (error, _) => GlowError(
                      message: error.toString(),
                      onRetry: () =>
                          ref.invalidate(serviceOptionsProvider(serviceId)),
                    ),
                    data: (options) => _SelectionTile(
                      title: _stringValue(options, 'optionName') ??
                          'Alt hizmet seç',
                      subtitle: 'Süre ve fiyat backend seçeneğinden alınır',
                      icon: Icons.schedule,
                      selected: options.isNotEmpty,
                    ),
                  );
                },
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
              _DateRow(
                selectedDate: _selectedDate,
                onSelected: (date) => setState(() => _selectedDate = date),
              ),
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
                    activeTrackColor: AppColors.action,
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
              services.when(
                loading: () => const GlowButton(
                  label: 'Hizmetler yükleniyor',
                  onPressed: null,
                  loading: true,
                  fullWidth: true,
                ),
                error: (error, _) => GlowButton(
                  label: 'Hizmetleri tekrar yükle',
                  icon: Icons.refresh,
                  fullWidth: true,
                  onPressed: () => ref.invalidate(servicesProvider),
                ),
                data: (items) {
                  final serviceId = _intValue(items, 'serviceId');
                  if (customerId == null || serviceId == null) {
                    return GlowButton(
                      label: customerId == null
                          ? 'Giriş yaparak randevu oluştur'
                          : 'Hizmet bulunamadı',
                      icon: Icons.lock_outline,
                      fullWidth: true,
                      onPressed: customerId == null
                          ? () => AppNavigation.go(context, AppRoutes.login)
                          : null,
                    );
                  }

                  final date = _dateString(_selectedDate);
                  final options = ref.watch(serviceOptionsProvider(serviceId));
                  final slots = ref.watch(
                    availableSlotsProvider(
                      AvailableSlotsQuery(serviceId: serviceId, date: date),
                    ),
                  );

                  return options.when(
                    loading: () => const GlowButton(
                      label: 'Alt hizmetler yükleniyor',
                      onPressed: null,
                      loading: true,
                      fullWidth: true,
                    ),
                    error: (error, _) => GlowButton(
                      label: 'Alt hizmetleri tekrar yükle',
                      icon: Icons.refresh,
                      fullWidth: true,
                      onPressed: () =>
                          ref.invalidate(serviceOptionsProvider(serviceId)),
                    ),
                    data: (options) => slots.when(
                      loading: () => const GlowButton(
                        label: 'Müsait saatler yükleniyor',
                        onPressed: null,
                        loading: true,
                        fullWidth: true,
                      ),
                      error: (error, _) => GlowButton(
                        label: 'Saatleri tekrar yükle',
                        icon: Icons.refresh,
                        fullWidth: true,
                        onPressed: () => ref.invalidate(
                          availableSlotsProvider(
                            AvailableSlotsQuery(
                              serviceId: serviceId,
                              date: date,
                            ),
                          ),
                        ),
                      ),
                      data: (slots) => GlowButton(
                        label: _isCreating
                            ? 'Randevu oluşturuluyor'
                            : 'Randevuyu Onayla',
                        icon: Icons.calendar_today_outlined,
                        loading: _isCreating,
                        fullWidth: true,
                        onPressed: _isCreating
                            ? null
                            : () => _createAppointment(
                                  customerId: customerId,
                                  serviceId: serviceId,
                                  optionId: _intValue(options, 'optionId'),
                                  slots: slots,
                                ),
                      ),
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

  Future<void> _createAppointment({
    required int customerId,
    required int serviceId,
    required int? optionId,
    required List<Map<String, dynamic>> slots,
  }) async {
    if (optionId == null) {
      GlowSnackBar.showError(context, 'Randevu için alt hizmet bulunamadı.');
      return;
    }

    final selectedSlot = _firstSlot(slots);
    if (selectedSlot == null) {
      GlowSnackBar.showError(context, 'Seçilen tarih için müsait saat yok.');
      return;
    }

    final employeeId = selectedSlot['employeeId']?.toString();
    final availableTimes = selectedSlot['availableTimes'] as List?;
    final fallbackTime = availableTimes?.isNotEmpty == true
        ? availableTimes!.first.toString()
        : _time;
    final appointmentTime =
        availableTimes?.map((item) => item.toString()).contains(_time) == true
            ? _time
            : fallbackTime;

    if (employeeId == null || employeeId.isEmpty) {
      GlowSnackBar.showError(context, 'Randevu için personel bulunamadı.');
      return;
    }

    setState(() => _isCreating = true);
    try {
      await ref.read(glowBackendServiceProvider).createAppointment({
        'customerId': customerId,
        'employeeId': employeeId,
        'serviceId': serviceId,
        'optionId': optionId,
        'appointmentDate': _dateString(_selectedDate),
        'appointmentTime': appointmentTime,
      });
      ref.invalidate(customerUpcomingAppointmentsProvider(customerId));
      if (!mounted) return;
      GlowSnackBar.showSuccess(context, 'Randevunuz başarıyla oluşturuldu.');
    } catch (error) {
      if (!mounted) return;
      GlowSnackBar.showError(context, error.toString());
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  static int? _intValue(List<Map<String, dynamic>> items, String key) {
    if (items.isEmpty) return null;
    final value = items.first[key];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _stringValue(List<Map<String, dynamic>> items, String key) {
    if (items.isEmpty) return null;
    final value = items.first[key]?.toString();
    return value == null || value.isEmpty ? null : value;
  }

  static Map<String, dynamic>? _firstSlot(List<Map<String, dynamic>> slots) {
    for (final slot in slots) {
      final times = slot['availableTimes'];
      if (times is List && times.isNotEmpty) {
        return slot;
      }
    }
    return slots.isEmpty ? null : slots.first;
  }

  static String _dateString(DateTime date) {
    return date.toIso8601String().split('T').first;
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
                      i <= 3 ? AppColors.action : AppColors.softBorder,
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
                        color:
                            i <= 3 ? AppColors.action : AppColors.secondaryText,
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
          color: selected ? AppColors.action : AppColors.border,
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
              color: selected ? AppColors.action : AppColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.selectedDate, required this.onSelected});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      5,
      (index) => DateTime.now().add(Duration(days: index + 1)),
    );
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final date in dates) ...[
            Semantics(
              button: true,
              selected: _sameDay(date, selectedDate),
              label: '${date.day} ${days[date.weekday - 1]}',
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => onSelected(date),
                child: Container(
                  width: 55,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _sameDay(date, selectedDate)
                        ? AppColors.action
                        : AppColors.white,
                    border: Border.all(
                      color: _sameDay(date, selectedDate)
                          ? AppColors.action
                          : AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: _sameDay(date, selectedDate)
                              ? AppColors.white
                              : AppColors.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        days[date.weekday - 1],
                        style: TextStyle(
                          color: _sameDay(date, selectedDate)
                              ? AppColors.white
                              : AppColors.secondaryText,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  static bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
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
                  selected == time ? AppColors.action : AppColors.white,
              foregroundColor:
                  selected == time ? AppColors.white : AppColors.secondaryText,
              side: BorderSide(
                color: selected == time ? AppColors.action : AppColors.border,
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
