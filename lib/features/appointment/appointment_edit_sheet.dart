import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import 'booking_models.dart';

/// Opens the edit sheet for an upcoming appointment. Returns `true` when the
/// reschedule succeeded (caller should refresh its appointment lists).
Future<bool?> showAppointmentEditSheet(
  BuildContext context, {
  required int appointmentId,
  required int serviceId,
  required int optionId,
  required String serviceLabel,
  required String currentEmployeeId,
  required String currentEmployeeName,
  required DateTime initialDate,
  required String initialTime,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AppointmentEditSheet(
      appointmentId: appointmentId,
      serviceId: serviceId,
      optionId: optionId,
      serviceLabel: serviceLabel,
      currentEmployeeId: currentEmployeeId,
      currentEmployeeName: currentEmployeeName,
      initialDate: initialDate,
      initialTime: initialTime,
    ),
  );
}

class AppointmentEditSheet extends ConsumerStatefulWidget {
  const AppointmentEditSheet({
    super.key,
    required this.appointmentId,
    required this.serviceId,
    required this.optionId,
    required this.serviceLabel,
    required this.currentEmployeeId,
    required this.currentEmployeeName,
    required this.initialDate,
    required this.initialTime,
  });

  final int appointmentId;
  final int serviceId;
  final int optionId;
  final String serviceLabel;
  final String currentEmployeeId;
  final String currentEmployeeName;
  final DateTime initialDate;
  final String initialTime;

  @override
  ConsumerState<AppointmentEditSheet> createState() =>
      _AppointmentEditSheetState();
}

class _AppointmentEditSheetState extends ConsumerState<AppointmentEditSheet> {
  late String _employeeId = widget.currentEmployeeId;
  late DateTime _date = widget.initialDate;
  late String? _time = widget.initialTime;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesByServiceOptionProvider(
      EmployeeServiceOptionQuery(
        serviceId: widget.serviceId,
        optionId: widget.optionId,
      ),
    ));
    final slotsAsync = ref.watch(availableSlotsProvider(AvailableSlotsQuery(
      serviceId: widget.serviceId,
      optionId: widget.optionId,
      date: BookingDateUtils.formatDate(_date),
    )));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Randevuyu Düzenle',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(widget.serviceLabel,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Text('Personel', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          employeesAsync.when(
            loading: () => const GlowSkeleton(height: 44),
            error: (error, _) => GlowError(
              message: bookingErrorMessage(error) ?? '$error',
              onRetry: () => ref.invalidate(employeesByServiceOptionProvider(
                EmployeeServiceOptionQuery(
                  serviceId: widget.serviceId,
                  optionId: widget.optionId,
                ),
              )),
            ),
            data: (items) {
              final employees = _mergeCurrentEmployee(items);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final employee in employees)
                    ChoiceChip(
                      key: Key('edit_employee_${employee.id}'),
                      label: Text(employee.name),
                      selected: employee.id == _employeeId,
                      onSelected: _saving
                          ? null
                          : (selected) {
                              if (!selected) return;
                              setState(() {
                                _employeeId = employee.id;
                                _time = null;
                              });
                            },
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Tarih', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('edit_date_picker'),
            onPressed: _saving ? null : _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(BookingDateUtils.formatDate(_date)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Saat', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          slotsAsync.when(
            loading: () => const GlowSkeleton(height: 44),
            error: (error, _) => GlowError(
              message: bookingErrorMessage(error) ?? '$error',
              onRetry: () => ref.invalidate(availableSlotsProvider(
                AvailableSlotsQuery(
                  serviceId: widget.serviceId,
                  optionId: widget.optionId,
                  date: BookingDateUtils.formatDate(_date),
                ),
              )),
            ),
            data: (items) {
              final times = _timesFor(items, _employeeId);
              if (times.isEmpty) {
                return const GlowEmptyState(
                  title: 'Bu personel için uygun saat yok',
                  message: 'Başka bir tarih veya personel seç.',
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in times)
                    ChoiceChip(
                      key: Key('edit_time_$time'),
                      label: Text(time),
                      selected: time == _time,
                      onSelected: _saving
                          ? null
                          : (selected) {
                              if (selected) setState(() => _time = time);
                            },
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: GlowButton(
                  label: 'Vazgeç',
                  variant: GlowButtonVariant.outlined,
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlowButton(
                  key: const Key('edit_confirm'),
                  label: 'Kaydet',
                  loading: _saving,
                  onPressed: _time == null || _saving ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The employee currently on the appointment must always be selectable even
  /// if a competency change since booking dropped them from the qualified
  /// list, otherwise "keep the same employee" would be impossible to submit.
  List<_EditEmployeeChoice> _mergeCurrentEmployee(
    List<Map<String, dynamic>> items,
  ) {
    final result = <_EditEmployeeChoice>[
      for (final item in items)
        _EditEmployeeChoice(
          item['employeeId']?.toString() ?? '',
          item['employeeName']?.toString() ??
              item['employeeId']?.toString() ??
              'Personel',
        ),
    ]..removeWhere((entry) => entry.id.isEmpty);
    if (!result.any((entry) => entry.id == widget.currentEmployeeId)) {
      result.insert(
        0,
        _EditEmployeeChoice(widget.currentEmployeeId, widget.currentEmployeeName),
      );
    }
    return result;
  }

  /// The slots endpoint reports the appointment's own current slot as
  /// occupied (it doesn't know which appointment is being edited), so the
  /// currently booked date/time never appears in the fetched list even
  /// though resubmitting it is valid. Splice it back in when relevant.
  List<String> _timesFor(List<Map<String, dynamic>> items, String employeeId) {
    final match = items.firstWhere(
      (item) => item['employeeId']?.toString() == employeeId,
      orElse: () => const {},
    );
    final raw = (match['availableTimes'] as List?) ?? const [];
    final times = raw
        .map((value) => BookingDateUtils.normalizeTime(value))
        .whereType<String>()
        .toSet();
    if (employeeId == widget.currentEmployeeId &&
        BookingDateUtils.formatDate(_date) ==
            BookingDateUtils.formatDate(widget.initialDate)) {
      times.add(widget.initialTime);
    }
    final sorted = times.toList()..sort();
    return sorted;
  }

  Future<void> _pickDate() async {
    final now = BookingDateUtils.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _time = null;
      });
    }
  }

  Future<void> _save() async {
    final time = _time;
    if (time == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(glowBackendServiceProvider).rescheduleAppointment(
        widget.appointmentId,
        {
          'employeeId': _employeeId,
          'appointmentDate': BookingDateUtils.formatDate(_date),
          'appointmentTime': time,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      GlowSnackBar.showError(
        context,
        bookingErrorMessage(error) ?? 'Randevu güncellenemedi.',
      );
    }
  }
}

class _EditEmployeeChoice {
  const _EditEmployeeChoice(this.id, this.name);

  final String id;
  final String name;
}
