import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';

class EmployeeSelectionPage extends ConsumerWidget {
  const EmployeeSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);

    return Scaffold(
      appBar: const GlowAppBar(title: 'Personel Secimi'),
      body: employees.when(
        loading: () => const GlowLoading(message: 'Personel yukleniyor'),
        error: (error, _) => GlowError(
          message: error.toString(),
          onRetry: () => ref.invalidate(employeesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const GlowEmptyState(title: 'Personel bulunamadi');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final employee = items[index];
              final name = [
                employee['firstName'],
                employee['lastName'],
              ].where((value) => value != null).join(' ');
              return GlowEmployeeCard(
                name: name.isEmpty
                    ? employee['employeeId']?.toString() ?? 'Personel'
                    : name,
                role: employee['phone']?.toString() ?? 'Uygun personel',
              );
            },
          );
        },
      ),
    );
  }
}
