import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../appointment/booking_models.dart';
import '../catalog/catalog_models.dart';
import '../employee/employee_dashboard_models.dart';

enum _AdminSection {
  overview('Genel Bakış', Icons.dashboard_outlined),
  services('Hizmetler', Icons.spa_outlined),
  packages('Paketler', Icons.inventory_2_outlined),
  employees('Personel', Icons.badge_outlined),
  schedule('Çalışma Saatleri', Icons.schedule_outlined),
  appointments('Randevular', Icons.calendar_month_outlined),
  customers('Müşteriler', Icons.people_outline);

  const _AdminSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  _AdminSection _section = _AdminSection.overview;
  String? _selectedEmployeeId;
  DateTime _selectedWeek = BookingDateUtils.today();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: SafeArea(child: GlowLoading(message: 'Yetki kontrol ediliyor')),
      ),
      error: (error, _) => Scaffold(
        body: SafeArea(
          child: GlowError(
            title: 'Oturum kontrol edilemedi',
            message: _safeAdminError(error),
            onRetry: () =>
                ref.read(authControllerProvider.notifier).loadSession(),
          ),
        ),
      ),
      data: (session) {
        if (session?.role?.toUpperCase() != 'ADMIN') {
          return Scaffold(
            body: SafeArea(
              child: GlowResponsivePage(
                child: GlowError(
                  title: 'Admin yetkisi gerekli',
                  message:
                      'Bu yönetim alanı yalnızca admin hesabıyla kullanılabilir.',
                  onRetry: () => context.go(AppRoutes.login),
                ),
              ),
            ),
          );
        }
        return _buildAdminShell(context);
      },
    );
  }

  Widget _buildAdminShell(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 980;
    return Scaffold(
      backgroundColor: AppColors.petal,
      appBar: wide
          ? null
          : GlowAppBar(
              title: 'Yönetim',
              actions: [
                IconButton(
                  key: const Key('admin_mobile_logout'),
                  tooltip: 'Çıkış Yap',
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                ),
                PopupMenuButton<_AdminSection>(
                  tooltip: 'Bölüm seç',
                  onSelected: (section) => setState(() => _section = section),
                  itemBuilder: (context) => [
                    for (final section in _AdminSection.values)
                      PopupMenuItem(
                        value: section,
                        child: Text(section.label),
                      ),
                  ],
                ),
              ],
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              _AdminSidebar(
                selected: _section,
                onSelected: (section) => setState(() => _section = section),
                onLogout: _logout,
              ),
            Expanded(
              child: GlowResponsivePage(
                maxWidth: 1280,
                padding: EdgeInsets.all(wide ? 28 : 16),
                child: _sectionBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionBody() {
    switch (_section) {
      case _AdminSection.overview:
        return _OverviewSection(
            onOpen: (section) => setState(() => _section = section));
      case _AdminSection.services:
        return _ServicesSection(
          busy: _busy,
          onCreate: () => _openServiceForm(),
          onEdit: (item) => _openServiceForm(item: item),
          onDelete: _deactivateService,
          onOptionCreate: _openOptionForm,
          onOptionEdit: (serviceId, item) =>
              _openOptionForm(serviceId: serviceId, item: item),
        );
      case _AdminSection.packages:
        return _PackagesSection(
          busy: _busy,
          onCreate: (serviceId) => _openPackageForm(serviceId: serviceId),
          onEdit: (serviceId, item) =>
              _openPackageForm(serviceId: serviceId, item: item),
        );
      case _AdminSection.employees:
        return _EmployeesSection(
          busy: _busy,
          onCreate: () => _openEmployeeForm(),
          onEdit: (item) => _openEmployeeForm(item: item),
          onDeactivate: _deactivateEmployee,
        );
      case _AdminSection.schedule:
        return _ScheduleSection(
          busy: _busy,
          onCreateWorkingHour: () => _openWorkingHourForm(),
          onEditWorkingHour: (item) => _openWorkingHourForm(item: item),
          onCreateHoliday: _openHolidayForm,
        );
      case _AdminSection.appointments:
        return _AppointmentsSection(
          selectedEmployeeId: _selectedEmployeeId,
          selectedWeek: _selectedWeek,
          busy: _busy,
          onEmployeeChanged: (id) => setState(() => _selectedEmployeeId = id),
          onWeekChanged: (date) => setState(() => _selectedWeek = date),
          onApprove: (query, item) =>
              _updateAppointment(query, item, 'approve'),
          onComplete: (query, item) =>
              _updateAppointment(query, item, 'complete'),
          onCancel: _cancelAppointment,
        );
      case _AdminSection.customers:
        return const _CustomersSection();
    }
  }

  Future<void> _runAdminAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) GlowSnackBar.showError(context, _safeAdminError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openServiceForm({Map<String, dynamic>? item}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ServiceFormDialog(item: item),
    );
    if (result == null) return;
    await _runAdminAction(() async {
      final service = ref.read(glowBackendServiceProvider);
      final id = _intValue(item?['serviceId']);
      if (id == null) {
        await service.createService(result);
      } else {
        await service.updateService(id, result);
      }
      ref.invalidate(servicesProvider);
      ref.invalidate(allServicePackagesProvider);
      if (mounted) GlowSnackBar.showSuccess(context, 'Hizmet kaydedildi');
    });
  }

  Future<void> _deactivateService(Map<String, dynamic> item) async {
    final id = _intValue(item['serviceId']);
    if (id == null) return;
    final confirmed = await _confirm(
      title: 'Hizmeti pasifleştir',
      message: '${item['serviceName'] ?? 'Bu hizmet'} pasifleştirilsin mi?',
    );
    if (!confirmed) return;
    await _runAdminAction(() async {
      await ref.read(glowBackendServiceProvider).deactivateService(id);
      ref.invalidate(servicesProvider);
      ref.invalidate(allServicePackagesProvider);
      if (mounted) GlowSnackBar.showSuccess(context, 'Hizmet pasifleştirildi');
    });
  }

  Future<void> _openOptionForm({
    required int serviceId,
    Map<String, dynamic>? item,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _OptionFormDialog(item: item),
    );
    if (result == null) return;
    await _runAdminAction(() async {
      final service = ref.read(glowBackendServiceProvider);
      final id = _intValue(item?['optionId']);
      if (id == null) {
        await service.createServiceOption(serviceId, result);
      } else {
        await service.updateServiceOption(id, result);
      }
      ref.invalidate(serviceOptionsProvider(serviceId));
      if (mounted) {
        GlowSnackBar.showSuccess(context, 'Fiyat seçeneği kaydedildi');
      }
    });
  }

  Future<void> _openPackageForm({
    required int serviceId,
    Map<String, dynamic>? item,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PackageFormDialog(item: item),
    );
    if (result == null) return;
    await _runAdminAction(() async {
      final service = ref.read(glowBackendServiceProvider);
      final id = _intValue(item?['packageId']);
      if (id == null) {
        await service.createPackage(serviceId, result);
      } else {
        await service.updatePackage(id, result);
      }
      ref.invalidate(servicePackagesProvider(serviceId));
      ref.invalidate(allServicePackagesProvider);
      if (mounted) GlowSnackBar.showSuccess(context, 'Paket kaydedildi');
    });
  }

  Future<void> _openEmployeeForm({Map<String, dynamic>? item}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EmployeeFormDialog(item: item),
    );
    if (result == null) return;
    await _runAdminAction(() async {
      final service = ref.read(glowBackendServiceProvider);
      final id = item?['employeeId']?.toString();
      if (id == null || id.isEmpty) {
        await service.createEmployee(result);
      } else {
        await service.updateEmployee(id, result);
      }
      ref.invalidate(employeesProvider);
      if (mounted) GlowSnackBar.showSuccess(context, 'Personel kaydedildi');
    });
  }

  Future<void> _deactivateEmployee(Map<String, dynamic> item) async {
    final id = item['employeeId']?.toString();
    if (id == null || id.isEmpty) return;
    final confirmed = await _confirm(
      title: 'Personeli Sil',
      message: 'Bu personeli silmek istediğinize emin misiniz? '
          'Geçmiş randevuları korunacak; kayıt pasifleştirilerek yeni randevulara kapatılacaktır.',
    );
    if (!confirmed) return;
    await _runAdminAction(() async {
      await ref.read(glowBackendServiceProvider).deactivateEmployee(id);
      ref.invalidate(employeesProvider);
      if (mounted) {
        GlowSnackBar.showSuccess(
          context,
          'Personel pasifleştirildi; geçmiş randevular korundu.',
        );
      }
    });
  }

  Future<void> _openWorkingHourForm({Map<String, dynamic>? item}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _WorkingHourFormDialog(item: item),
    );
    if (result == null) return;
    await _runAdminAction(() async {
      final id = _intValue(item?['workingHourId']);
      final service = ref.read(glowBackendServiceProvider);
      if (id == null) {
        await service.createWorkingHour(result);
      } else {
        await service.updateWorkingHour(id, result);
      }
      ref.invalidate(workingHoursProvider);
      if (mounted) {
        GlowSnackBar.showSuccess(context, 'Çalışma saati kaydedildi');
      }
    });
  }

  Future<void> _openHolidayForm() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _HolidayFormDialog(),
    );
    if (result == null) return;
    await _runAdminAction(() async {
      await ref.read(glowBackendServiceProvider).createHoliday(result);
      ref.invalidate(holidaysProvider(_adminHolidayQuery()));
      if (mounted) GlowSnackBar.showSuccess(context, 'Tatil günü eklendi');
    });
  }

  Future<void> _updateAppointment(
    EmployeeAppointmentsQuery query,
    Map<String, dynamic> item,
    String action,
  ) async {
    final id = _intValue(item['appointmentId']);
    if (id == null) return;
    await _runAdminAction(() async {
      final service = ref.read(glowBackendServiceProvider);
      if (action == 'approve') {
        await service.approveAppointment(id);
      } else {
        await service.completeAppointment(id);
      }
      ref.invalidate(employeeAppointmentsProvider(query));
      if (mounted) {
        GlowSnackBar.showSuccess(
          context,
          action == 'approve' ? 'Randevu onaylandı' : 'Randevu tamamlandı',
        );
      }
    });
  }

  Future<void> _cancelAppointment(
    EmployeeAppointmentsQuery query,
    Map<String, dynamic> item,
  ) async {
    final id = _intValue(item['appointmentId']);
    if (id == null) return;
    final confirmed = await _confirm(
      title: 'Randevuyu iptal et',
      message: '${item['serviceName'] ?? 'Randevu'} iptal edilsin mi?',
    );
    if (!confirmed) return;
    await _runAdminAction(() async {
      await ref.read(glowBackendServiceProvider).cancelAppointment(id,
          cancellationReason: 'Admin tarafından iptal edildi');
      ref.invalidate(employeeAppointmentsProvider(query));
      if (mounted) GlowSnackBar.showSuccess(context, 'Randevu iptal edildi');
    });
  }

  Future<bool> _confirm(
      {required String title, required String message}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              GlowButton(
                label: 'Vazgeç',
                variant: GlowButtonVariant.text,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              GlowButton(
                label: 'Onayla',
                icon: Icons.check,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.welcome);
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selected,
    required this.onSelected,
    required this.onLogout,
  });

  final _AdminSection selected;
  final ValueChanged<_AdminSection> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: GlowBrand(),
          ),
          for (final section in _AdminSection.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: TextButton.icon(
                key: Key('admin_nav_${section.name}'),
                onPressed: () => onSelected(section),
                icon: Icon(section.icon, size: 18),
                label: Text(section.label),
                style: TextButton.styleFrom(
                  foregroundColor: selected == section
                      ? AppColors.action
                      : AppColors.secondaryText,
                  backgroundColor: selected == section
                      ? AppColors.roseTint
                      : Colors.transparent,
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ),
          const Spacer(),
          GlowButton(
            label: 'Çıkış Yap',
            icon: Icons.logout,
            variant: GlowButtonVariant.outlined,
            fullWidth: true,
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _OverviewSection extends ConsumerWidget {
  const _OverviewSection({required this.onOpen});

  final ValueChanged<_AdminSection> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final packages = ref.watch(allServicePackagesProvider);
    final employees = ref.watch(employeesProvider);
    final customers = ref.watch(customersProvider);
    return ListView(
      children: [
        _AdminHeader(
          title: 'Genel Bakış',
          subtitle: 'Gerçek API verilerine bağlı yönetim özeti.',
          actions: [
            GlowButton(
              key: const Key('admin_service_create'),
              label: 'Hizmet Ekle',
              icon: Icons.add,
              onPressed: () => onOpen(_AdminSection.services),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 940
                ? 4
                : constraints.maxWidth > 560
                    ? 2
                    : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: columns == 1 ? 3.0 : 2.25,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              children: [
                _AsyncStat(
                    title: 'Hizmetler', state: services, icon: Icons.spa),
                _AsyncStat(
                  title: 'Paketler',
                  state: packages,
                  icon: Icons.inventory_2_outlined,
                ),
                _AsyncStat(
                  title: 'Personel',
                  state: employees,
                  icon: Icons.badge_outlined,
                ),
                _AsyncStat(
                  title: 'Müşteriler',
                  state: customers,
                  icon: Icons.people_outline,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _UnsupportedPanel(),
      ],
    );
  }
}

class _ServicesSection extends ConsumerWidget {
  const _ServicesSection({
    required this.busy,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onOptionCreate,
    required this.onOptionEdit,
  });

  final bool busy;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;
  final void Function({required int serviceId}) onOptionCreate;
  final void Function(int serviceId, Map<String, dynamic> item) onOptionEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    return ListView(
      children: [
        _AdminHeader(
          title: 'Hizmet Yönetimi',
          subtitle: 'Hizmetler ve fiyat seçenekleri.',
          actions: [
            GlowButton(
              key: const Key('admin_service_create_form'),
              label: 'Hizmet Ekle',
              icon: Icons.add,
              onPressed: busy ? null : onCreate,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        services.when(
          loading: () => const GlowLoading(message: 'Hizmetler yükleniyor'),
          error: (error, _) => GlowError(
            message: _safeAdminError(error),
            onRetry: () => ref.invalidate(servicesProvider),
          ),
          data: (items) => items.isEmpty
              ? const GlowEmptyState(title: 'Hizmet bulunamadı')
              : Column(
                  children: [
                    for (final item in items) ...[
                      _ServiceAdminCard(
                        item: item,
                        busy: busy,
                        onEdit: () => onEdit(item),
                        onDelete: () => onDelete(item),
                        onOptionCreate: () {
                          final id = _intValue(item['serviceId']);
                          if (id != null) onOptionCreate(serviceId: id);
                        },
                        onOptionEdit: (option) {
                          final id = _intValue(item['serviceId']);
                          if (id != null) onOptionEdit(id, option);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ServiceAdminCard extends ConsumerWidget {
  const _ServiceAdminCard({
    required this.item,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onOptionCreate,
    required this.onOptionEdit,
  });

  final Map<String, dynamic> item;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOptionCreate;
  final ValueChanged<Map<String, dynamic>> onOptionEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceId = _intValue(item['serviceId']);
    final options = serviceId == null
        ? const AsyncValue<List<Map<String, dynamic>>>.data([])
        : ref.watch(serviceOptionsProvider(serviceId));
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: GlowCatalogImage(
              semanticLabel:
                  '${item['serviceName']?.toString() ?? 'Hizmet'} görseli',
              image: CatalogService.fromJson(item).image,
              width: double.infinity,
              height: double.infinity,
              radius: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _RowHeader(
            title: item['serviceName']?.toString() ?? 'Hizmet',
            subtitle: item['description']?.toString(),
            trailing: Wrap(
              spacing: AppSpacing.sm,
              children: [
                GlowButton(
                  label: 'Düzenle',
                  icon: Icons.edit_outlined,
                  variant: GlowButtonVariant.outlined,
                  onPressed: busy ? null : onEdit,
                ),
                GlowButton(
                  key: const Key('admin_service_delete'),
                  label: 'Sil',
                  icon: Icons.delete_outline,
                  variant: GlowButtonVariant.outlined,
                  onPressed: busy ? null : onDelete,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Fiyat seçenekleri',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: busy ? null : onOptionCreate,
                icon: const Icon(Icons.add),
                label: const Text('Seçenek Ekle'),
              ),
            ],
          ),
          options.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: LinearProgressIndicator(),
            ),
            error: (error, _) => Text(_safeAdminError(error)),
            data: (items) => items.isEmpty
                ? const Text('Fiyat seçeneği yok')
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final option in items)
                        ActionChip(
                          label: Text(
                            '${option['optionName'] ?? 'Seçenek'} • ${option['price'] ?? '-'}',
                          ),
                          onPressed: busy ? null : () => onOptionEdit(option),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PackagesSection extends ConsumerWidget {
  const _PackagesSection({
    required this.busy,
    required this.onCreate,
    required this.onEdit,
  });

  final bool busy;
  final ValueChanged<int> onCreate;
  final void Function(int serviceId, Map<String, dynamic> item) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final packages = ref.watch(allServicePackagesProvider);
    return ListView(
      children: [
        _AdminHeader(
          title: 'Paket Yönetimi',
          subtitle: 'Paket oluşturma, fiyat ve seans yönetimi.',
          actions: [
            services.maybeWhen(
              data: (items) => DropdownButton<int>(
                hint: const Text('Paket Ekle'),
                items: [
                  for (final service in items)
                    if (_intValue(service['serviceId']) != null)
                      DropdownMenuItem(
                        value: _intValue(service['serviceId']),
                        child: Text(
                            service['serviceName']?.toString() ?? 'Hizmet'),
                      ),
                ],
                onChanged: busy || items.isEmpty
                    ? null
                    : (id) {
                        if (id != null) onCreate(id);
                      },
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        packages.when(
          loading: () => const GlowLoading(message: 'Paketler yükleniyor'),
          error: (error, _) => GlowError(
            message: _safeAdminError(error),
            onRetry: () => ref.invalidate(allServicePackagesProvider),
          ),
          data: (items) => items.isEmpty
              ? const GlowEmptyState(title: 'Paket bulunamadı')
              : _AdminTable(
                  columns: const [
                    DataColumn(label: Text('Paket')),
                    DataColumn(label: Text('Hizmet')),
                    DataColumn(label: Text('Seans')),
                    DataColumn(label: Text('Fiyat')),
                    DataColumn(label: Text('Durum')),
                    DataColumn(label: Text('İşlem')),
                  ],
                  rows: [
                    for (final item in items)
                      DataRow(
                        cells: [
                          DataCell(
                              Text(item['packageName']?.toString() ?? '-')),
                          DataCell(
                              Text(item['serviceName']?.toString() ?? '-')),
                          DataCell(
                              Text(item['totalSession']?.toString() ?? '-')),
                          DataCell(Text(item['price']?.toString() ?? '-')),
                          DataCell(Text(
                              item['active'] == false ? 'Pasif' : 'Aktif')),
                          DataCell(
                            TextButton(
                              key: const Key('admin_package_edit'),
                              onPressed: busy
                                  ? null
                                  : () {
                                      final serviceId =
                                          _intValue(item['serviceId']);
                                      if (serviceId != null) {
                                        onEdit(serviceId, item);
                                      }
                                    },
                              child: const Text('Düzenle'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _EmployeesSection extends ConsumerWidget {
  const _EmployeesSection({
    required this.busy,
    required this.onCreate,
    required this.onEdit,
    required this.onDeactivate,
  });

  final bool busy;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDeactivate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);
    return ListView(
      children: [
        _AdminHeader(
          title: 'Personel Yönetimi',
          subtitle: 'Personel listesi ve hesap durumu.',
          actions: [
            GlowButton(
              label: 'Personel Ekle',
              icon: Icons.add,
              onPressed: busy ? null : onCreate,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        employees.when(
          loading: () => const GlowLoading(message: 'Personel yükleniyor'),
          error: (error, _) => GlowError(
            message: _safeAdminError(error),
            onRetry: () => ref.invalidate(employeesProvider),
          ),
          data: (items) => items.isEmpty
              ? const GlowEmptyState(title: 'Personel bulunamadı')
              : _AdminTable(
                  columns: const [
                    DataColumn(label: Text('İşlem')),
                    DataColumn(label: Text('Ad Soyad')),
                    DataColumn(label: Text('İletişim')),
                    DataColumn(label: Text('Durum')),
                    DataColumn(label: Text('Yetkinlik')),
                  ],
                  rows: [
                    for (final item in items)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 240,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    onPressed: busy ? null : () => onEdit(item),
                                    style: _employeeActionButtonStyle(),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    label: const Text('Düzenle'),
                                  ),
                                  TextButton.icon(
                                    key: ValueKey(
                                      'admin_employee_delete_${item['employeeId']}',
                                    ),
                                    onPressed:
                                        busy ? null : () => onDeactivate(item),
                                    style: _employeeActionButtonStyle(),
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    label: const Text('Sil'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_employeeName(item)),
                              Text(
                                item['employeeId']?.toString() ?? '-',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          )),
                          DataCell(Text(
                              item['email']?.toString().trim().isNotEmpty ==
                                      true
                                  ? item['email'].toString()
                                  : item['phone']?.toString() ?? '-')),
                          DataCell(Text(
                              item['active'] == false ? 'Pasif' : 'Aktif')),
                          DataCell(Text(_employeeCompetencySummary(item))),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ScheduleSection extends ConsumerWidget {
  const _ScheduleSection({
    required this.busy,
    required this.onCreateWorkingHour,
    required this.onEditWorkingHour,
    required this.onCreateHoliday,
  });

  final bool busy;
  final VoidCallback onCreateWorkingHour;
  final ValueChanged<Map<String, dynamic>> onEditWorkingHour;
  final VoidCallback onCreateHoliday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hours = ref.watch(workingHoursProvider);
    final holidays = ref.watch(holidaysProvider(_adminHolidayQuery()));
    return ListView(
      children: [
        _AdminHeader(
          title: 'Çalışma Saatleri ve Tatiller',
          subtitle: 'İşletme takvimi yönetimi.',
          actions: [
            GlowButton(
              label: 'Tatil Ekle',
              icon: Icons.beach_access_outlined,
              variant: GlowButtonVariant.outlined,
              onPressed: busy ? null : onCreateHoliday,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final split = constraints.maxWidth >= 860;
            final panels = [
              _AsyncListPanel(
                title: 'Çalışma Saatleri',
                state: hours,
                itemBuilder: (item) => ListTile(
                  title: Text(item['dayOfWeek']?.toString() ?? '-'),
                  subtitle: Text(
                      '${item['startTime'] ?? '-'} - ${item['endTime'] ?? '-'}'),
                  trailing: TextButton(
                    onPressed: busy ? null : () => onEditWorkingHour(item),
                    child: const Text('Düzenle'),
                  ),
                ),
              ),
              _AsyncListPanel(
                title: 'Tatil Günleri',
                state: holidays,
                itemBuilder: (item) => ListTile(
                  title: Text(item['holidayName']?.toString() ?? 'Tatil'),
                  subtitle: Text(
                    '${item['holidayDate'] ?? '-'} ${item['description'] ?? ''}',
                  ),
                ),
              ),
            ];
            return split
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: panels[0]),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: panels[1]),
                    ],
                  )
                : Column(
                    children: [
                      panels[0],
                      const SizedBox(height: AppSpacing.lg),
                      panels[1],
                    ],
                  );
          },
        ),
      ],
    );
  }
}

class _AppointmentsSection extends ConsumerWidget {
  const _AppointmentsSection({
    required this.selectedEmployeeId,
    required this.selectedWeek,
    required this.busy,
    required this.onEmployeeChanged,
    required this.onWeekChanged,
    required this.onApprove,
    required this.onComplete,
    required this.onCancel,
  });

  final String? selectedEmployeeId;
  final DateTime selectedWeek;
  final bool busy;
  final ValueChanged<String?> onEmployeeChanged;
  final ValueChanged<DateTime> onWeekChanged;
  final void Function(
      EmployeeAppointmentsQuery query, Map<String, dynamic> item) onApprove;
  final void Function(
      EmployeeAppointmentsQuery query, Map<String, dynamic> item) onComplete;
  final void Function(
      EmployeeAppointmentsQuery query, Map<String, dynamic> item) onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);
    return ListView(
      children: [
        _AdminHeader(
          title: 'Randevu Yönetimi',
          subtitle: 'Backend sözleşmesine göre personel bazlı haftalık takvim.',
          actions: [
            GlowButton(
              label: 'Önceki Hafta',
              icon: Icons.chevron_left,
              variant: GlowButtonVariant.outlined,
              onPressed: () =>
                  onWeekChanged(selectedWeek.subtract(const Duration(days: 7))),
            ),
            GlowButton(
              label: 'Sonraki Hafta',
              icon: Icons.chevron_right,
              variant: GlowButtonVariant.outlined,
              onPressed: () =>
                  onWeekChanged(selectedWeek.add(const Duration(days: 7))),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        employees.when(
          loading: () => const GlowLoading(message: 'Personel yükleniyor'),
          error: (error, _) => GlowError(message: _safeAdminError(error)),
          data: (items) {
            final selected = selectedEmployeeId ??
                (items.isEmpty ? null : items.first['employeeId']?.toString());
            if (selected == null) {
              return const GlowEmptyState(
                  title: 'Randevu için personel bulunamadı');
            }
            final week = EmployeeWeekRange.from(selectedWeek);
            final query = EmployeeAppointmentsQuery(
              employeeId: selected,
              startDate: week.startText,
              endDate: week.endText,
            );
            final appointments = ref.watch(employeeAppointmentsProvider(query));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: selected,
                  items: [
                    for (final item in items)
                      DropdownMenuItem(
                        value: item['employeeId']?.toString(),
                        child: Text(_employeeName(item)),
                      ),
                  ],
                  onChanged: onEmployeeChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                appointments.when(
                  loading: () =>
                      const GlowLoading(message: 'Randevular yükleniyor'),
                  error: (error, _) => GlowError(
                    message: _safeAdminError(error),
                    onRetry: () =>
                        ref.invalidate(employeeAppointmentsProvider(query)),
                  ),
                  data: (items) => items.isEmpty
                      ? const GlowEmptyState(title: 'Bu hafta randevu yok')
                      : _AdminTable(
                          // The İşlem column can hold two buttons (Onayla/Tamamla
                          // + İptal) that wrap onto a second line on narrower
                          // widths; without an explicit range DataTable keeps
                          // every row at a fixed 48px regardless of content and
                          // that second line paints over the row below it.
                          dataRowMinHeight: 56,
                          dataRowMaxHeight: 112,
                          columns: const [
                            DataColumn(label: Text('Tarih')),
                            DataColumn(label: Text('Saat')),
                            DataColumn(label: Text('Hizmet')),
                            DataColumn(label: Text('Müşteri')),
                            DataColumn(label: Text('Durum')),
                            DataColumn(label: Text('İşlem')),
                          ],
                          rows: [
                            for (final item in items)
                              DataRow(
                                cells: [
                                  DataCell(Text(
                                      item['appointmentDate']?.toString() ??
                                          '-')),
                                  DataCell(Text(BookingDateUtils.normalizeTime(
                                          item['appointmentTime']) ??
                                      '-')),
                                  DataCell(Text(
                                      item['serviceName']?.toString() ?? '-')),
                                  DataCell(Text(
                                      '${item['customerName'] ?? ''} ${item['customerSurname'] ?? ''}'
                                          .trim())),
                                  DataCell(Text(
                                      employeeAppointmentStatusLabel(item))),
                                  DataCell(
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      children: [
                                        if (item['status']
                                                    ?.toString()
                                                    .toUpperCase() ==
                                                'PENDING' &&
                                            !appointmentIsPastDue(item))
                                          TextButton(
                                            onPressed: busy
                                                ? null
                                                : () => onApprove(query, item),
                                            child: const Text('Onayla'),
                                          ),
                                        if (item['status']
                                                    ?.toString()
                                                    .toUpperCase() ==
                                                'APPROVED' &&
                                            !appointmentIsPastDue(item))
                                          TextButton(
                                            onPressed: busy
                                                ? null
                                                : () => onComplete(query, item),
                                            child: const Text('Tamamla'),
                                          ),
                                        TextButton(
                                          onPressed: busy
                                              ? null
                                              : () => onCancel(query, item),
                                          child: const Text('İptal'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CustomersSection extends ConsumerWidget {
  const _CustomersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    return ListView(
      children: [
        const _AdminHeader(
          title: 'Müşteriler',
          subtitle: 'Backend tarafından desteklenen müşteri listesi.',
        ),
        const SizedBox(height: AppSpacing.lg),
        customers.when(
          loading: () => const GlowLoading(message: 'Müşteriler yükleniyor'),
          error: (error, _) => GlowError(
            message: _safeAdminError(error),
            onRetry: () => ref.invalidate(customersProvider),
          ),
          data: (items) => items.isEmpty
              ? const GlowEmptyState(title: 'Müşteri bulunamadı')
              : _AdminTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Ad Soyad')),
                    DataColumn(label: Text('Telefon')),
                    DataColumn(label: Text('E-posta')),
                    DataColumn(label: Text('Durum')),
                  ],
                  rows: [
                    for (final item in items)
                      DataRow(
                        cells: [
                          DataCell(Text(item['customerId']?.toString() ?? '-')),
                          DataCell(Text(
                              '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}'
                                  .trim())),
                          DataCell(Text(item['phone']?.toString() ?? '-')),
                          DataCell(Text(item['email']?.toString() ?? '-')),
                          DataCell(Text(
                              item['active'] == false ? 'Pasif' : 'Aktif')),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlowEyebrow('GlowBook Admin'),
            const SizedBox(height: AppSpacing.xs),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        );
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  Wrap(spacing: AppSpacing.sm, children: actions),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleBlock,
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: actions),
                ],
              );
      },
    );
  }
}

class _AdminTable extends StatelessWidget {
  const _AdminTable({
    required this.columns,
    required this.rows,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;

  /// Left null for every table whose cells are always a single line, which
  /// keeps DataTable's default fixed 48px row height (unchanged behavior).
  /// A table whose cells can wrap onto more than one line (e.g. an action
  /// column with more than one button) needs an explicit min/max range, or
  /// DataTable holds every row at that fixed height regardless of content
  /// and a wrapped second line paints into the row below instead of growing
  /// its own row.
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns,
          rows: rows,
          dataRowMinHeight: dataRowMinHeight,
          dataRowMaxHeight: dataRowMaxHeight,
        ),
      ),
    );
  }
}

class _AsyncStat extends StatelessWidget {
  const _AsyncStat({
    required this.title,
    required this.state,
    required this.icon,
  });

  final String title;
  final AsyncValue<List<Map<String, dynamic>>> state;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlowStatCard(
      title: title,
      value: state.when(
        data: (items) => items.length.toString(),
        error: (_, __) => '!',
        loading: () => '...',
      ),
      icon: icon,
    );
  }
}

class _AsyncListPanel extends StatelessWidget {
  const _AsyncListPanel({
    required this.title,
    required this.state,
    required this.itemBuilder,
  });

  final String title;
  final AsyncValue<List<Map<String, dynamic>>> state;
  final Widget Function(Map<String, dynamic> item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          state.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(_safeAdminError(error)),
            data: (items) => items.isEmpty
                ? const Text('Kayıt bulunamadı')
                : Column(
                    children: [for (final item in items) itemBuilder(item)]),
          ),
        ],
      ),
    );
  }
}

class _UnsupportedPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlowSoftNotice(
      title: 'Backend destek kapsamı',
      message:
          'Gelir grafiği, kategori CRUD, tüm randevular listesi ve bildirim yönetimi için ayrı admin endpoint’i bulunmadığı için sabit veri gösterilmiyor.',
    );
  }
}

class _RowHeader extends StatelessWidget {
  const _RowHeader({
    required this.title,
    this.subtitle,
    required this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null && subtitle!.trim().isNotEmpty)
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
        return wide
            ? Row(children: [Expanded(child: text), trailing])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  const SizedBox(height: AppSpacing.sm),
                  trailing
                ],
              );
      },
    );
  }
}

class _ServiceFormDialog extends StatefulWidget {
  const _ServiceFormDialog({this.item});

  final Map<String, dynamic>? item;

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.item?['serviceName']?.toString());
  late final _description =
      TextEditingController(text: widget.item?['description']?.toString());
  late final _image =
      TextEditingController(text: widget.item?['serviceImage']?.toString());
  late bool _active = widget.item?['active'] != false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormDialog(
      title: widget.item == null ? 'Hizmet Ekle' : 'Hizmeti Düzenle',
      formKey: _formKey,
      fields: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Hizmet adı'),
          validator: _required,
        ),
        TextFormField(
          controller: _description,
          decoration: const InputDecoration(labelText: 'Açıklama'),
          minLines: 2,
          maxLines: 3,
        ),
        TextFormField(
          controller: _image,
          decoration: const InputDecoration(labelText: 'Görsel URL'),
        ),
        SwitchListTile(
          value: _active,
          onChanged: (value) => setState(() => _active = value),
          title: const Text('Aktif'),
        ),
      ],
      onSubmit: () => {
        'serviceName': _name.text.trim(),
        'description': _description.text.trim(),
        'serviceImage': _image.text.trim(),
        'active': _active,
      },
    );
  }
}

class _OptionFormDialog extends StatefulWidget {
  const _OptionFormDialog({this.item});

  final Map<String, dynamic>? item;

  @override
  State<_OptionFormDialog> createState() => _OptionFormDialogState();
}

class _OptionFormDialogState extends State<_OptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.item?['optionName']?.toString());
  late final _price =
      TextEditingController(text: widget.item?['price']?.toString());
  late bool _active = widget.item?['active'] != false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormDialog(
      title: widget.item == null
          ? 'Fiyat Seçeneği Ekle'
          : 'Fiyat Seçeneğini Düzenle',
      formKey: _formKey,
      fields: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Seçenek adı'),
          validator: _required,
        ),
        TextFormField(
          controller: _price,
          decoration: const InputDecoration(labelText: 'Fiyat'),
          keyboardType: TextInputType.number,
          validator: _positiveNumber,
        ),
        SwitchListTile(
          value: _active,
          onChanged: (value) => setState(() => _active = value),
          title: const Text('Aktif'),
        ),
      ],
      onSubmit: () => {
        'optionName': _name.text.trim(),
        'price': double.tryParse(_price.text.trim().replaceAll(',', '.')),
        'active': _active,
      },
    );
  }
}

class _PackageFormDialog extends StatefulWidget {
  const _PackageFormDialog({this.item});

  final Map<String, dynamic>? item;

  @override
  State<_PackageFormDialog> createState() => _PackageFormDialogState();
}

class _PackageFormDialogState extends State<_PackageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.item?['packageName']?.toString());
  late final _description =
      TextEditingController(text: widget.item?['description']?.toString());
  late final _sessions =
      TextEditingController(text: widget.item?['totalSession']?.toString());
  late final _price =
      TextEditingController(text: widget.item?['price']?.toString());
  late final _image =
      TextEditingController(text: widget.item?['packageImage']?.toString());
  late bool _active = widget.item?['active'] != false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _sessions.dispose();
    _price.dispose();
    _image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormDialog(
      title: widget.item == null ? 'Paket Ekle' : 'Paketi Düzenle',
      formKey: _formKey,
      fields: [
        TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Paket adı'),
            validator: _required),
        TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Açıklama')),
        TextFormField(
            controller: _sessions,
            decoration: const InputDecoration(labelText: 'Seans sayısı'),
            keyboardType: TextInputType.number,
            validator: _positiveInt),
        TextFormField(
            controller: _price,
            decoration: const InputDecoration(labelText: 'Fiyat'),
            keyboardType: TextInputType.number,
            validator: _positiveNumber),
        TextFormField(
            controller: _image,
            decoration: const InputDecoration(labelText: 'Görsel URL')),
        SwitchListTile(
            value: _active,
            onChanged: (value) => setState(() => _active = value),
            title: const Text('Aktif')),
      ],
      onSubmit: () => {
        'packageName': _name.text.trim(),
        'description': _description.text.trim(),
        'totalSession': int.tryParse(_sessions.text.trim()),
        'price': double.tryParse(_price.text.trim().replaceAll(',', '.')),
        'packageImage': _image.text.trim(),
        'active': _active,
      },
    );
  }
}

class _EmployeeFormDialog extends StatefulWidget {
  const _EmployeeFormDialog({this.item});

  final Map<String, dynamic>? item;

  @override
  State<_EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<_EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _employeeId =
      TextEditingController(text: widget.item?['employeeId']?.toString());
  late final _firstName =
      TextEditingController(text: widget.item?['firstName']?.toString());
  late final _lastName =
      TextEditingController(text: widget.item?['lastName']?.toString());
  late final _phone =
      TextEditingController(text: widget.item?['phone']?.toString());
  late final _email =
      TextEditingController(text: widget.item?['email']?.toString());
  final _password = TextEditingController();
  late bool _active = widget.item?['active'] != false;
  late final Set<int> _selectedServiceIds =
      ((widget.item?['assignedServices'] as List?) ?? const [])
          .map((item) => _intValue((item as Map?)?['serviceId']))
          .whereType<int>()
          .toSet();

  @override
  void dispose() {
    _employeeId.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return _AdminFormDialog(
      title: editing ? 'Personeli Düzenle' : 'Personel Ekle',
      formKey: _formKey,
      fields: [
        TextFormField(
            controller: _employeeId,
            enabled: !editing,
            decoration: const InputDecoration(labelText: 'Personel ID'),
            validator: _required),
        TextFormField(
            controller: _firstName,
            decoration: const InputDecoration(labelText: 'Ad'),
            validator: _required),
        TextFormField(
            controller: _lastName,
            decoration: const InputDecoration(labelText: 'Soyad'),
            validator: _required),
        TextFormField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Telefon')),
        TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'E-posta')),
        TextFormField(
            controller: _password,
            decoration: InputDecoration(
                labelText:
                    editing ? 'Şifre (değiştirmek için doldurun)' : 'Şifre'),
            obscureText: true,
            validator: editing ? null : _required),
        SwitchListTile(
            value: _active,
            onChanged: (value) => setState(() => _active = value),
            title: const Text('Aktif')),
        _EmployeeCompetenciesField(
          selectedServiceIds: _selectedServiceIds,
          onChanged: (ids) => setState(() {
            _selectedServiceIds
              ..clear()
              ..addAll(ids);
          }),
        ),
      ],
      onSubmit: () => {
        'employeeId': _employeeId.text.trim(),
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text.trim(),
        'active': _active,
        'serviceIds': _selectedServiceIds.toList()..sort(),
      },
    );
  }
}

class _EmployeeCompetenciesField extends ConsumerWidget {
  const _EmployeeCompetenciesField({
    required this.selectedServiceIds,
    required this.onChanged,
  });

  final Set<int> selectedServiceIds;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(servicesProvider).when(
          loading: () => const GlowLoading(message: 'Hizmetler yükleniyor'),
          error: (error, _) => GlowError(
            message: _safeAdminError(error),
            onRetry: () => ref.invalidate(servicesProvider),
          ),
          data: (services) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hizmet Yetkinlikleri',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text('Personelin verebildiği ana hizmetleri seçin.'),
              const SizedBox(height: 10),
              for (final group in _deduplicatedActiveServices(services))
                CheckboxListTile(
                  key: ValueKey('employee_service_${group.name}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(group.name),
                  value: group.ids.every(selectedServiceIds.contains),
                  onChanged: (selected) {
                    final next = {...selectedServiceIds};
                    selected == true
                        ? next.addAll(group.ids)
                        : next.removeAll(group.ids);
                    onChanged(next);
                  },
                ),
            ],
          ),
        );
  }
}

class _ServiceSelectionGroup {
  const _ServiceSelectionGroup(this.name, this.ids);

  final String name;
  final Set<int> ids;
}

class _WorkingHourFormDialog extends StatefulWidget {
  const _WorkingHourFormDialog({this.item});

  final Map<String, dynamic>? item;

  @override
  State<_WorkingHourFormDialog> createState() => _WorkingHourFormDialogState();
}

class _WorkingHourFormDialogState extends State<_WorkingHourFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _day = widget.item?['dayOfWeek']?.toString() ?? 'MONDAY';
  late final _start = TextEditingController(
      text:
          BookingDateUtils.normalizeTime(widget.item?['startTime']) ?? '09:00');
  late final _end = TextEditingController(
      text: BookingDateUtils.normalizeTime(widget.item?['endTime']) ?? '18:00');
  late bool _closed = widget.item?['closed'] == true;

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormDialog(
      title: widget.item == null
          ? 'Çalışma Saati Ekle'
          : 'Çalışma Saatini Düzenle',
      formKey: _formKey,
      fields: [
        DropdownButtonFormField<String>(
          initialValue: _day,
          decoration: const InputDecoration(labelText: 'Gün'),
          items: const [
            'MONDAY',
            'TUESDAY',
            'WEDNESDAY',
            'THURSDAY',
            'FRIDAY',
            'SATURDAY',
            'SUNDAY',
          ]
              .map((day) => DropdownMenuItem(value: day, child: Text(day)))
              .toList(),
          onChanged: (value) => setState(() => _day = value ?? _day),
        ),
        TextFormField(
            controller: _start,
            decoration: const InputDecoration(labelText: 'Başlangıç'),
            validator: _required),
        TextFormField(
            controller: _end,
            decoration: const InputDecoration(labelText: 'Bitiş'),
            validator: _required),
        SwitchListTile(
            value: _closed,
            onChanged: (value) => setState(() => _closed = value),
            title: const Text('Kapalı')),
      ],
      onSubmit: () => {
        'dayOfWeek': _day,
        'startTime': _start.text.trim(),
        'endTime': _end.text.trim(),
        'closed': _closed,
      },
    );
  }
}

class _HolidayFormDialog extends StatefulWidget {
  const _HolidayFormDialog();

  @override
  State<_HolidayFormDialog> createState() => _HolidayFormDialogState();
}

class _HolidayFormDialogState extends State<_HolidayFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _date = TextEditingController(
      text: BookingDateUtils.formatDate(BookingDateUtils.today()));
  final _name = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _date.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AdminFormDialog(
      title: 'Tatil Günü Ekle',
      formKey: _formKey,
      fields: [
        TextFormField(
            controller: _date,
            decoration: const InputDecoration(labelText: 'Tarih'),
            validator: _required),
        TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Tatil adı'),
            validator: _required),
        TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Açıklama')),
      ],
      onSubmit: () => {
        'holidayDate': _date.text.trim(),
        'holidayName': _name.text.trim(),
        'description': _description.text.trim(),
      },
    );
  }
}

class _AdminFormDialog extends StatelessWidget {
  const _AdminFormDialog({
    required this.title,
    required this.formKey,
    required this.fields,
    required this.onSubmit,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final Map<String, dynamic> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fields) ...[
                  field,
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        GlowButton(
          label: 'Vazgeç',
          variant: GlowButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        GlowButton(
          label: 'Kaydet',
          icon: Icons.save_outlined,
          onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.of(context).pop(onSubmit());
          },
        ),
      ],
    );
  }
}

DateRangeQuery _adminHolidayQuery() {
  // The backend requires an explicit bounded range (no "all" mode) - this
  // window is wide enough to include every holiday an admin would realistically
  // enter, past or future, instead of silently dropping anything outside a
  // near-term window.
  final today = BookingDateUtils.today();
  return DateRangeQuery(
    startDate: BookingDateUtils.formatDate(
        today.subtract(const Duration(days: 3650))),
    endDate:
        BookingDateUtils.formatDate(today.add(const Duration(days: 3650))),
  );
}

String _safeAdminError(Object error) {
  final text = error.toString().replaceFirst('Exception:', '').trim();
  if (text.contains('401') || text.toLowerCase().contains('unauthorized')) {
    return 'Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap.';
  }
  if (text.contains('403') || text.toLowerCase().contains('forbidden')) {
    return 'Bu işlem için admin yetkisi gerekiyor.';
  }
  if (text.toLowerCase().contains('conflict')) {
    return 'Bu kayıt başka bir veriyle çakışıyor. Bilgileri kontrol et.';
  }
  if (text.toLowerCase().contains('validation') || text.contains('400')) {
    return 'Form bilgilerini kontrol edip tekrar dene.';
  }
  return text.isEmpty ? 'İşlem tamamlanamadı. Lütfen tekrar dene.' : text;
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Bu alan zorunludur.' : null;
}

String? _positiveNumber(String? value) {
  final parsed = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
  return parsed == null || parsed <= 0 ? 'Pozitif bir değer gir.' : null;
}

String? _positiveInt(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  return parsed == null || parsed <= 0 ? 'Pozitif bir sayı gir.' : null;
}

String _employeeName(Map<String, dynamic> item) {
  final fullName = item['fullName']?.toString();
  if (fullName != null && fullName.trim().isNotEmpty) return fullName;
  final text = '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}'.trim();
  return text.isEmpty ? item['employeeId']?.toString() ?? 'Personel' : text;
}

ButtonStyle _employeeActionButtonStyle() => TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

String _employeeCompetencySummary(Map<String, dynamic> item) {
  final assignments = (item['assignedServices'] as List?) ?? const [];
  final names = assignments
      .map((value) => (value as Map?)?['serviceName']?.toString())
      .whereType<String>()
      .where((name) => name.trim().isNotEmpty)
      .fold<Map<String, String>>({}, (result, name) {
        result.putIfAbsent(_serviceNameKey(name), () => name.trim());
        return result;
      })
      .values
      .toList();
  if (names.isEmpty) return '0 yetkinlik';
  final preview = names.take(2).join(', ');
  return names.length > 2
      ? '${names.length} • $preview…'
      : '${names.length} • $preview';
}

List<_ServiceSelectionGroup> _deduplicatedActiveServices(
  List<Map<String, dynamic>> services,
) {
  final grouped = <String, _ServiceSelectionGroup>{};
  for (final service in services) {
    if (service['active'] == false) continue;
    final id = _intValue(service['serviceId']);
    final name = service['serviceName']?.toString().trim() ?? '';
    if (id == null || name.isEmpty) continue;
    final key = _serviceNameKey(name);
    final current = grouped[key];
    grouped[key] = _ServiceSelectionGroup(
      current?.name ?? name,
      {...?current?.ids, id},
    );
  }
  final result = grouped.values.toList();
  result.sort((left, right) => left.name.compareTo(right.name));
  return result;
}

String _serviceNameKey(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'\s+'), ' ');

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
