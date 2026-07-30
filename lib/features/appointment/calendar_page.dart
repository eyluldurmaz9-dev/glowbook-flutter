import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);

    return Scaffold(
      appBar: const GlowAppBar(title: 'Takvim'),
      body: GlowResponsivePage(
        child: ListView(
          children: [
            CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 120)),
              onDateChanged: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 16),
            services.when(
              loading: () => const GlowLoading(message: 'Hizmetler yukleniyor'),
              error: (error, _) => GlowError(
                message: error.toString(),
                onRetry: () => ref.invalidate(servicesProvider),
              ),
              data: (items) {
                final firstServiceId =
                    items.isEmpty ? null : items.first['serviceId'];
                if (firstServiceId is! int) {
                  return const GlowEmptyState(title: 'Musaitlik bulunamadi');
                }
                final date = _selectedDate.toIso8601String().split('T').first;
                final slots = ref.watch(
                  availableSlotsProvider(
                    AvailableSlotsQuery(serviceId: firstServiceId, date: date),
                  ),
                );
                return slots.when(
                  loading: () =>
                      const GlowLoading(message: 'Saatler yukleniyor'),
                  error: (error, _) => GlowError(message: error.toString()),
                  data: (items) {
                    if (items.isEmpty) {
                      return const GlowEmptyState(title: 'Musait saat yok');
                    }
                    return Column(
                      children: [
                        for (final item in items) ...[
                          GlowCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item['employeeName']?.toString() ?? 'Personel',
                              ),
                              subtitle: Text(
                                (item['availableTimes'] as List?)?.join(', ') ??
                                    '',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
