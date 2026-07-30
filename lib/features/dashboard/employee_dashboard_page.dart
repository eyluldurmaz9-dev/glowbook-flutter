import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class EmployeeDashboardPage extends ConsumerWidget {
  const EmployeeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final employeeId = session?.employeeId;
    final today = DateTime.now().toIso8601String().split('T').first;
    final end = DateTime.now()
        .add(const Duration(days: 7))
        .toIso8601String()
        .split('T')
        .first;

    return Scaffold(
      body: SafeArea(
        child: employeeId == null
            ? const GlowEmptyState(title: 'Personel oturumu bulunamadı')
            : FutureBuilder<List<Map<String, dynamic>>>(
                future: ref
                    .watch(glowBackendServiceProvider)
                    .getEmployeeAppointments(
                      employeeId: employeeId,
                      startDate: today,
                      endDate: end,
                    ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const GlowLoading(message: 'Program yükleniyor');
                  }
                  if (snapshot.hasError) {
                    return GlowError(message: snapshot.error.toString());
                  }
                  final items = snapshot.data ?? const [];
                  return GlowResponsivePage(
                    padding: const EdgeInsets.fromLTRB(20, 25, 20, 28),
                    child: ListView(
                      children: [
                        const GlowPageTop(
                          title: 'Personel Paneli',
                          subtitle: 'Bugünün randevuları ve haftalık program.',
                          action: GlowMark(icon: Icons.badge_outlined),
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
                                GlowStatCard(
                                  title: 'Bugünkü Randevular',
                                  value: items.length.toString(),
                                  icon: Icons.event_available_outlined,
                                ),
                                const GlowStatCard(
                                  title: 'Müşteriler',
                                  value: 'Aktif',
                                  icon: Icons.people_outline,
                                ),
                                const GlowStatCard(
                                  title: 'Bildirimler',
                                  value: 'Yeni',
                                  icon: Icons.notifications_outlined,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Text('Takvim',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        if (items.isEmpty)
                          const GlowEmptyState(title: 'Programda randevu yok')
                        else
                          for (final item in items) ...[
                            GlowAppointmentCard(
                              title:
                                  item['serviceName']?.toString() ?? 'Randevu',
                              time:
                                  '${item['appointmentDate'] ?? ''} ${item['appointmentTime'] ?? ''}',
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
