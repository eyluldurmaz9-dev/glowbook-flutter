import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../catalog/catalog_models.dart';
import 'booking_models.dart';

class AppointmentPage extends ConsumerStatefulWidget {
  const AppointmentPage({super.key});

  @override
  ConsumerState<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends ConsumerState<AppointmentPage> {
  final _guestFormKey = GlobalKey<FormState>();
  final _guestNameController = TextEditingController();
  final _guestSurnameController = TextEditingController();
  final _guestPhoneController = TextEditingController();

  var _step = 0;
  CatalogService? _service;
  CatalogOption? _option;
  CustomerPackageOption? _customerPackage;
  var _candidateDates = <DateTime>[
    BookingDateUtils.today().add(const Duration(days: 1)),
  ];
  DateTime _date = BookingDateUtils.today().add(const Duration(days: 1));
  String? _time;
  BookingSlot? _slot;
  bool _submitting = false;
  bool _joiningWaitlist = false;
  BookingResult? _result;

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestSurnameController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final session = auth.asData?.value;
    final customerId = session?.customerId;
    final services = ref.watch(servicesProvider);
    final slotDates = _candidateDates
        .map(BookingDateUtils.formatDate)
        .toSet()
        .toList()
      ..sort();
    final slots = _service == null || _option == null
        ? null
        : ref.watch(
            availableSlotsForDatesProvider(
              AvailableSlotsBatchQuery(
                serviceId: _service!.id ?? 0,
                optionId: _option!.id ?? 0,
                dates: slotDates,
              ),
            ),
          );

    return Scaffold(
      body: SafeArea(
        child: GlowResponsivePage(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
          child: Form(
            key: _guestFormKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlowPageTop(
                    title: 'Randevu oluştur',
                    subtitle: 'Hizmetini seç, uygun saati backend’den doğrula.',
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
                  BookingStepper(currentStep: _step),
                  const SizedBox(height: 18),
                  if (_result != null) ...[
                    BookingResultCard(result: _result!),
                    const SizedBox(height: 18),
                  ],
                  _StepSurface(
                    title: _stepTitle,
                    child: _buildStep(
                      services: services,
                      slots: slots,
                      customerId: customerId,
                      signedIn: customerId != null,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ActionBar(
                    step: _step,
                    canContinue: _canContinue(customerId),
                    submitting: _submitting,
                    onBack: _step == 0 ? null : () => setState(() => _step--),
                    onNext: _step < 5 ? _goNext : null,
                    onSubmit:
                        _step == 5 ? () => _confirmAndSubmit(customerId) : null,
                  ),
                  const SizedBox(height: 28),
                  _UpcomingAppointments(customerId: customerId),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: GlowBottomNavigationBar(
        currentIndex: 2,
        onTap: (index) => AppNavigation.goBottomTab(context, index),
      ),
    );
  }

  String get _stepTitle {
    return const [
      'Hizmet seçimi',
      'Alt hizmet ve paket',
      'Tarih seçimi',
      'Uygun zaman aralığı',
      'Personel seçimi',
      'Randevu özeti',
    ][_step];
  }

  Widget _buildStep({
    required AsyncValue<List<Map<String, dynamic>>> services,
    required AsyncValue<List<Map<String, dynamic>>>? slots,
    required int? customerId,
    required bool signedIn,
  }) {
    switch (_step) {
      case 0:
        return services.when(
          loading: () => const GlowLoading(message: 'Hizmetler yükleniyor'),
          error: (error, _) => GlowError(
            message: bookingErrorMessage(error) ?? error.toString(),
            onRetry: () => ref.invalidate(servicesProvider),
          ),
          data: (items) => _ServicePicker(
            services: mapCatalogServices(items),
            selected: _service,
            onSelected: _selectService,
          ),
        );
      case 1:
        if (_service?.id == null) {
          return const GlowEmptyState(title: 'Hizmet seç');
        }
        final options = ref.watch(serviceOptionsProvider(_service!.id!));
        final servicePackages =
            ref.watch(servicePackagesProvider(_service!.id!));
        final customerPackages = customerId == null
            ? const AsyncValue<List<Map<String, dynamic>>>.data([])
            : ref.watch(customerPackagesProvider(customerId));
        return _OptionAndPackageStep(
          options: options,
          servicePackages: servicePackages,
          customerPackages: customerPackages,
          selectedOption: _option,
          selectedPackage: _customerPackage,
          customerId: customerId,
          onOptionSelected: (option) => setState(() => _option = option),
          onPackageSelected: (package) =>
              setState(() => _customerPackage = package),
          onPackageCleared: () => setState(() => _customerPackage = null),
          onPackagePurchase: (package) => _purchasePackage(customerId, package),
        );
      case 2:
        return _DateStep(
          selectedDates: _candidateDates,
          onSelected: (date) {
            if (BookingDateUtils.isPast(date)) return;
            final normalized = BookingDateUtils.normalize(date);
            setState(() {
              _candidateDates = _toggleDate(_candidateDates, normalized);
              _date = _candidateDates.first;
              _time = null;
              _slot = null;
            });
          },
        );
      case 3:
        return _TimeStep(
          slots: slots,
          selectedDate: _date,
          selectedTime: _time,
          selectedEmployeeId: _slot?.employeeId,
          onTimeSelected: (choice) => setState(() {
            _date = choice.date;
            _time = choice.time;
            _slot = choice.slot;
          }),
          onRetry: _refreshSlots,
          onJoinWaitlist: () => _joinWaitlist(customerId),
          joiningWaitlist: _joiningWaitlist,
        );
      case 4:
        return _EmployeeStep(
          slots: slots,
          selectedDate: _date,
          selectedTime: _time,
          selectedSlot: _slot,
          onSelected: (slot) => setState(() => _slot = slot),
          onRetry: _refreshSlots,
        );
      case 5:
        return _SummaryStep(
          signedIn: signedIn,
          service: _service,
          option: _option,
          package: _customerPackage,
          date: _date,
          time: _time,
          slot: _slot,
          guestNameController: _guestNameController,
          guestSurnameController: _guestSurnameController,
          guestPhoneController: _guestPhoneController,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _selectService(CatalogService service) {
    setState(() {
      _service = service;
      _option = null;
      _customerPackage = null;
      _time = null;
      _slot = null;
      _result = null;
    });
  }

  List<DateTime> _toggleDate(List<DateTime> dates, DateTime date) {
    final exists = dates.any((item) =>
        BookingDateUtils.formatDate(item) == BookingDateUtils.formatDate(date));
    if (exists && dates.length == 1) {
      return dates;
    }
    final updated = exists
        ? dates
            .where((item) =>
                BookingDateUtils.formatDate(item) !=
                BookingDateUtils.formatDate(date))
            .toList()
        : [...dates, date];
    updated.sort((a, b) => a.compareTo(b));
    return updated;
  }

  void _goNext() {
    if (!_canContinue(null)) return;
    setState(() => _step++);
  }

  bool _canContinue(int? customerId) {
    switch (_step) {
      case 0:
        return _service?.id != null;
      case 1:
        return _option?.id != null;
      case 2:
        return _candidateDates.isNotEmpty &&
            _candidateDates.every((date) => !BookingDateUtils.isPast(date));
      case 3:
        return _time != null;
      case 4:
        return _slot?.employeeId.isNotEmpty == true;
      case 5:
        return _service?.id != null &&
            _option?.id != null &&
            _time != null &&
            _slot?.employeeId.isNotEmpty == true &&
            (customerId != null ||
                (_guestFormKey.currentState?.validate() ?? false));
      default:
        return false;
    }
  }

  void _refreshSlots() {
    final serviceId = _service?.id;
    final optionId = _option?.id;
    if (serviceId == null || optionId == null) return;
    ref.invalidate(
      availableSlotsForDatesProvider(
        AvailableSlotsBatchQuery(
          serviceId: serviceId,
          optionId: optionId,
          dates: (_candidateDates.map(BookingDateUtils.formatDate).toList()
            ..sort()),
        ),
      ),
    );
  }

  Future<void> _confirmAndSubmit(int? customerId) async {
    if (_submitting) return;
    if (customerId == null &&
        !(_guestFormKey.currentState?.validate() ?? false)) {
      GlowSnackBar.showError(context, 'Misafir bilgilerini tamamla.');
      return;
    }
    final confirmed = await GlowDialog.showConfirmation(
      context,
      title: 'Randevuyu onayla',
      message: 'Seçtiğin saat backend tarafından tekrar kontrol edilecek.',
      confirmLabel: 'Onayla',
    );
    if (confirmed != true) return;
    await _submitAppointment(customerId);
  }

  Future<void> _submitAppointment(int? customerId) async {
    final serviceId = _service?.id;
    final optionId = _option?.id;
    final employeeId = _slot?.employeeId;
    final time = _time;
    if (serviceId == null ||
        optionId == null ||
        employeeId == null ||
        time == null) {
      GlowSnackBar.showError(context, 'Randevu seçimlerini tamamla.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final query = AvailableSlotsQuery(
        serviceId: serviceId,
        optionId: optionId,
        date: BookingDateUtils.formatDate(_date),
      );
      final freshSlots = mapBookingSlots(
        await ref.refresh(availableSlotsProvider(query).future),
      );
      final stillAvailable = freshSlots.any(
        (slot) => slot.employeeId == employeeId && slot.hasTime(time),
      );
      if (!stillAvailable) {
        throw Exception('Selected slot is not available');
      }

      final payload = <String, dynamic>{
        if (customerId != null) 'customerId': customerId,
        if (_customerPackage?.customerPackageId != null)
          'customerPackageId': _customerPackage!.customerPackageId,
        'employeeId': employeeId,
        'serviceId': serviceId,
        'optionId': optionId,
        if (customerId == null) ...{
          'customerName': _guestNameController.text.trim(),
          'customerSurname': _guestSurnameController.text.trim(),
          'phone': _guestPhoneController.text.trim(),
        },
        'appointmentDate': BookingDateUtils.formatDate(_date),
        'appointmentTime': time,
      };

      final response =
          await ref.read(glowBackendServiceProvider).createAppointment(payload);
      if (customerId != null) {
        ref.invalidate(customerUpcomingAppointmentsProvider(customerId));
        ref.invalidate(customerPackagesProvider(customerId));
      }
      if (!mounted) return;
      setState(() {
        _result = BookingResult.appointment(response);
      });
      GlowSnackBar.showSuccess(
          context, 'Randevun backend tarafından oluşturuldu.');
    } catch (error) {
      if (!mounted) return;
      GlowSnackBar.showError(
        context,
        bookingErrorMessage(error) ?? 'Randevu oluşturulamadı.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _purchasePackage(
    int? customerId,
    CatalogPackage package,
  ) async {
    if (customerId == null) {
      GlowSnackBar.showError(context,
          'Paket satın almak veya mevcut paketinizi kullanmak için giriş yapmanız gerekir.');
      return;
    }
    if (package.id == null) return;
    final confirmed = await GlowDialog.showConfirmation(
      context,
      title: 'Paketi satın al',
      message:
          '${package.name} demo/rezervasyon satın alımı olarak hesabınıza eklenecek. Gerçek ödeme alınmayacaktır.',
      confirmLabel: 'Satın Al',
    );
    if (confirmed != true) return;
    try {
      final response = await ref
          .read(glowBackendServiceProvider)
          .purchasePackage(customerId, package.id!);
      ref.invalidate(customerPackagesProvider(customerId));
      if (!mounted) return;
      setState(() {
        _customerPackage = CustomerPackageOption.fromJson(response);
      });
      GlowSnackBar.showSuccess(
          context, 'Paket eklendi. Randevu seçimlerin korundu.');
    } catch (error) {
      if (!mounted) return;
      GlowSnackBar.showError(context, bookingErrorMessage(error)!);
    }
  }

  Future<void> _joinWaitlist(int? customerId) async {
    if (_joiningWaitlist) return;
    final serviceId = _service?.id;
    final optionId = _option?.id;
    if (serviceId == null || optionId == null) {
      GlowSnackBar.showError(
          context, 'Bekleme listesi için hizmet ve alt hizmet seç.');
      return;
    }
    if (customerId == null &&
        !(_guestFormKey.currentState?.validate() ?? false)) {
      setState(() => _step = 5);
      GlowSnackBar.showError(context, 'Misafir bilgilerini tamamla.');
      return;
    }

    setState(() => _joiningWaitlist = true);
    try {
      final response =
          await ref.read(glowBackendServiceProvider).createWaitingListRecord({
        if (customerId != null) 'customerId': customerId,
        'serviceId': serviceId,
        'optionId': optionId,
        if (customerId == null) ...{
          'customerName': _guestNameController.text.trim(),
          'customerSurname': _guestSurnameController.text.trim(),
          'phone': _guestPhoneController.text.trim(),
        },
        'preferredDate': BookingDateUtils.formatDate(_date),
        if (_time != null) 'preferredStartTime': _time,
        if (_time != null) 'preferredEndTime': _time,
      });
      if (customerId != null) {
        ref.invalidate(customerWaitingListProvider(customerId));
      }
      if (!mounted) return;
      setState(() {
        _result = BookingResult.waitingList(response);
      });
      GlowSnackBar.showSuccess(context, 'Bekleme listesine eklendin.');
    } catch (error) {
      if (!mounted) return;
      GlowSnackBar.showError(
        context,
        bookingErrorMessage(error) ?? 'Bekleme listesine eklenemedi.',
      );
    } finally {
      if (mounted) setState(() => _joiningWaitlist = false);
    }
  }
}

class BookingStepper extends StatelessWidget {
  const BookingStepper({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Hizmet',
      'Seçenek',
      'Tarih',
      'Saat',
      'Personel',
      'Özet',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Semantics(
              label: '${steps[i]} adımı',
              selected: i == currentStep,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: i <= currentStep
                        ? AppColors.action
                        : AppColors.softBorder,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i <= currentStep
                            ? AppColors.white
                            : AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 68,
                    child: Text(
                      steps[i],
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: i <= currentStep
                                ? AppColors.action
                                : AppColors.secondaryText,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != steps.length - 1)
              Container(width: 22, height: 1, color: AppColors.softBorder),
          ],
        ],
      ),
    );
  }
}

class _StepSurface extends StatelessWidget {
  const _StepSurface({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ServicePicker extends StatelessWidget {
  const _ServicePicker({
    required this.services,
    required this.selected,
    required this.onSelected,
  });

  final List<CatalogService> services;
  final CatalogService? selected;
  final ValueChanged<CatalogService> onSelected;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const GlowEmptyState(title: 'Hizmet bulunamadı');
    }
    return Column(
      children: [
        for (final service in services) ...[
          _SelectableTile(
            title: service.name,
            subtitle: service.description ?? 'Ayrıntılar için dokun.',
            icon: Icons.spa_outlined,
            image: service.image,
            selected: selected?.id == service.id,
            onTap: service.id == null ? null : () => onSelected(service),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OptionAndPackageStep extends StatelessWidget {
  const _OptionAndPackageStep({
    required this.options,
    required this.servicePackages,
    required this.customerPackages,
    required this.selectedOption,
    required this.selectedPackage,
    required this.onOptionSelected,
    required this.onPackageSelected,
    required this.onPackageCleared,
    required this.customerId,
    required this.onPackagePurchase,
  });

  final AsyncValue<List<Map<String, dynamic>>> options;
  final AsyncValue<List<Map<String, dynamic>>> servicePackages;
  final AsyncValue<List<Map<String, dynamic>>> customerPackages;
  final CatalogOption? selectedOption;
  final CustomerPackageOption? selectedPackage;
  final ValueChanged<CatalogOption> onOptionSelected;
  final ValueChanged<CustomerPackageOption> onPackageSelected;
  final VoidCallback onPackageCleared;
  final int? customerId;
  final ValueChanged<CatalogPackage> onPackagePurchase;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alt hizmet', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        options.when(
          loading: () => const GlowLoading(message: 'Alt hizmetler yükleniyor'),
          error: (error, _) => GlowError(message: bookingErrorMessage(error)!),
          data: (items) {
            final mapped = mapCatalogOptions(items);
            if (mapped.isEmpty) {
              return const GlowEmptyState(title: 'Alt hizmet bulunamadı');
            }
            return Column(
              children: [
                for (final option in mapped) ...[
                  _SelectableTile(
                    title: option.name,
                    subtitle: option.priceText ?? 'Fiyat yok',
                    icon: Icons.schedule,
                    selected: selectedOption?.id == option.id,
                    onTap: option.id == null
                        ? null
                        : () => onOptionSelected(option),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Text('Paket seçenekleri',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        servicePackages.when(
          loading: () => const GlowSkeleton(height: 72),
          error: (error, _) => GlowError(message: bookingErrorMessage(error)!),
          data: (packageItems) => customerPackages.when(
            loading: () => const GlowSkeleton(height: 72),
            error: (error, _) =>
                GlowError(message: bookingErrorMessage(error)!),
            data: (customerItems) {
              final servicePackageModels = mapCatalogPackages(packageItems);
              final usable = mapCustomerPackageOptions(customerItems)
                  .where((item) => item.canUseFor(servicePackageModels))
                  .toList();
              final ownedIds = usable.map((item) => item.packageId).toSet();
              final purchasable = servicePackageModels
                  .where(
                      (item) => item.id != null && !ownedIds.contains(item.id))
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mevcut paketlerim',
                      style: Theme.of(context).textTheme.titleSmall),
                  if (usable.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                          'Bu hizmet için henüz satın aldığınız bir paket yok.'),
                    ),
                  for (final item in usable) ...[
                    _SelectableTile(
                      title: item.name,
                      subtitle: _packageUsageText(item),
                      icon: Icons.inventory_2_outlined,
                      selected: selectedPackage?.customerPackageId ==
                          item.customerPackageId,
                      onTap: item.customerPackageId == null
                          ? null
                          : () => onPackageSelected(item),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text('Bu hizmet için paketler',
                      style: Theme.of(context).textTheme.titleSmall),
                  if (purchasable.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('Bu hizmet için paket bulunmuyor.'),
                    ),
                  for (final item in purchasable) ...[
                    _SelectableTile(
                      title: item.name,
                      subtitle: _purchasablePackageText(item),
                      icon: Icons.shopping_bag_outlined,
                      image: item.image,
                      selected: false,
                      onTap: () => onPackagePurchase(item),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _SelectableTile(
                    title: 'Tek seans olarak devam et',
                    subtitle:
                        'Randevu seçilen alt hizmet fiyatıyla oluşturulur.',
                    icon: Icons.event_available_outlined,
                    selected: selectedPackage == null,
                    onTap: onPackageCleared,
                  ),
                  if (customerId == null &&
                      servicePackageModels.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Paket satın almak veya mevcut paketinizi kullanmak için giriş yapmanız gerekir.',
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _packageUsageText(CustomerPackageOption item) {
    final used = item.usedSession;
    final remaining = item.remainingSession ?? 0;
    if (used == null || item.totalSession == null) {
      return '$remaining seans kaldı';
    }
    return 'Bu randevuda 1 seans kullanılır • Kullanılan $used/${item.totalSession}, kalan $remaining';
  }

  String _purchasablePackageText(CatalogPackage item) =>
      '${item.totalSession ?? '-'} seans • ${item.priceText ?? 'Fiyat belirtilmedi'} • ${item.validityDays ?? 365} gün geçerli${item.description == null ? '' : '\n${item.description}'}';
}

class _DateStep extends StatelessWidget {
  const _DateStep({required this.selectedDates, required this.onSelected});

  final List<DateTime> selectedDates;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = BookingDateUtils.today();
    final lastDate = today.add(const Duration(days: 90));
    final initialDate = selectedDates.isEmpty ? today : selectedDates.first;
    final calendarDate = initialDate.isBefore(today)
        ? today
        : initialDate.isAfter(lastDate)
            ? lastDate
            : initialDate;
    final dates =
        List.generate(14, (index) => today.add(Duration(days: index)));
    final selectedLabels =
        selectedDates.map(BookingDateUtils.formatDate).toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birden fazla tarih secebilirsin. Uygun saatler sonraki adimda birlikte listelenir.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        GlowCard(
          padding: const EdgeInsets.all(8),
          backgroundColor: AppColors.petal,
          borderColor: AppColors.softBorder,
          child: CalendarDatePicker(
            initialDate: calendarDate,
            firstDate: today,
            lastDate: lastDate,
            currentDate: calendarDate,
            onDateChanged: onSelected,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final date in dates) ...[
                _DateChip(
                  date: date,
                  selected: selectedLabels
                      .contains(BookingDateUtils.formatDate(date)),
                  onTap: () => onSelected(date),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlowButton(
          label: 'Takvimden seç',
          icon: Icons.calendar_today_outlined,
          variant: GlowButtonVariant.secondary,
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: today,
              lastDate: lastDate,
              initialDate: calendarDate,
              locale: const Locale('tr'),
            );
            if (picked != null) onSelected(picked);
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in selectedLabels)
              Chip(
                label: Text(label),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: selectedDates.length == 1
                    ? null
                    : () => onSelected(DateTime.parse(label)),
              ),
          ],
        ),
      ],
    );
  }
}

class _TimeStep extends StatelessWidget {
  const _TimeStep({
    required this.slots,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedEmployeeId,
    required this.onTimeSelected,
    required this.onRetry,
    required this.onJoinWaitlist,
    required this.joiningWaitlist,
  });

  final AsyncValue<List<Map<String, dynamic>>>? slots;
  final DateTime selectedDate;
  final String? selectedTime;
  final String? selectedEmployeeId;
  final ValueChanged<BookingTimeChoice> onTimeSelected;
  final VoidCallback onRetry;
  final VoidCallback onJoinWaitlist;
  final bool joiningWaitlist;

  @override
  Widget build(BuildContext context) {
    if (slots == null) return const GlowEmptyState(title: 'Önce hizmet seç');
    return slots!.when(
      loading: () => const GlowLoading(message: 'Uygun saatler alınıyor'),
      error: (error, _) => GlowError(
        message: bookingErrorMessage(error)!,
        onRetry: onRetry,
      ),
      data: (items) {
        final choices = _bookingChoices(mapBookingSlots(items));
        if (choices.isEmpty) {
          return Column(
            children: [
              const GlowEmptyState(
                title: 'Uygun saat yok',
                message: 'Bu tarih için backend uygun zaman döndürmedi.',
                icon: Icons.event_busy_outlined,
              ),
              const SizedBox(height: 12),
              GlowButton(
                label: 'Bekleme Listesine Katıl',
                icon: Icons.hourglass_bottom_outlined,
                loading: joiningWaitlist,
                fullWidth: true,
                onPressed: onJoinWaitlist,
              ),
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final choice in choices)
              FilterChip(
                label: Text(
                  '${BookingDateUtils.formatDate(choice.date)}  ${choice.time} — ${choice.slot.employeeName}',
                ),
                selected: selectedTime == choice.time &&
                    choice.slot.employeeId == selectedEmployeeId &&
                    BookingDateUtils.formatDate(selectedDate) ==
                        BookingDateUtils.formatDate(choice.date),
                onSelected: (_) => onTimeSelected(choice),
              ),
          ],
        );
      },
    );
  }

  List<BookingTimeChoice> _bookingChoices(List<BookingSlot> slots) {
    final choices = <BookingTimeChoice>[];
    for (final slot in slots) {
      for (final time in slot.availableTimes) {
        choices.add(BookingTimeChoice(date: slot.date, time: time, slot: slot));
      }
    }
    choices.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      final timeCompare = a.time.compareTo(b.time);
      return timeCompare != 0
          ? timeCompare
          : a.slot.employeeName.compareTo(b.slot.employeeName);
    });
    return choices;
  }
}

class BookingTimeChoice {
  const BookingTimeChoice({
    required this.date,
    required this.time,
    required this.slot,
  });

  final DateTime date;
  final String time;
  final BookingSlot slot;
}

class _EmployeeStep extends StatelessWidget {
  const _EmployeeStep({
    required this.slots,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedSlot,
    required this.onSelected,
    required this.onRetry,
  });

  final AsyncValue<List<Map<String, dynamic>>>? slots;
  final DateTime selectedDate;
  final String? selectedTime;
  final BookingSlot? selectedSlot;
  final ValueChanged<BookingSlot> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (selectedTime == null) {
      return const GlowEmptyState(title: 'Önce saat seç');
    }
    if (slots == null) return const GlowEmptyState(title: 'Önce hizmet seç');
    return slots!.when(
      loading: () => const GlowLoading(message: 'Personel uygunluğu alınıyor'),
      error: (error, _) => GlowError(
        message: bookingErrorMessage(error)!,
        onRetry: onRetry,
      ),
      data: (items) {
        final employees = mapBookingSlots(items)
            .where((slot) =>
                BookingDateUtils.formatDate(slot.date) ==
                    BookingDateUtils.formatDate(selectedDate) &&
                slot.hasTime(selectedTime!))
            .toList(growable: false);
        if (employees.isEmpty) {
          return const GlowEmptyState(
            title: 'Personel bulunamadı',
            message: 'Seçilen saat için backend personel döndürmedi.',
          );
        }
        return Column(
          children: [
            for (final slot in employees) ...[
              _SelectableTile(
                title: slot.employeeName,
                subtitle:
                    '${BookingDateUtils.formatDate(selectedDate)} - $selectedTime',
                icon: Icons.person_outline,
                selected: selectedSlot?.employeeId == slot.employeeId,
                onTap: () => onSelected(slot),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.signedIn,
    required this.service,
    required this.option,
    required this.package,
    required this.date,
    required this.time,
    required this.slot,
    required this.guestNameController,
    required this.guestSurnameController,
    required this.guestPhoneController,
  });

  final bool signedIn;
  final CatalogService? service;
  final CatalogOption? option;
  final CustomerPackageOption? package;
  final DateTime date;
  final String? time;
  final BookingSlot? slot;
  final TextEditingController guestNameController;
  final TextEditingController guestSurnameController;
  final TextEditingController guestPhoneController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryRow(label: 'Hizmet', value: service?.name ?? '-'),
        _SummaryRow(label: 'Alt hizmet', value: option?.name ?? '-'),
        _SummaryRow(label: 'Fiyat', value: option?.priceText ?? 'Fiyat yok'),
        _SummaryRow(label: 'Paket', value: package?.name ?? 'Paket yok'),
        _SummaryRow(label: 'Tarih', value: BookingDateUtils.formatDate(date)),
        _SummaryRow(label: 'Saat', value: time ?? '-'),
        _SummaryRow(label: 'Personel', value: slot?.employeeName ?? '-'),
        if (!signedIn) ...[
          const SizedBox(height: 14),
          GlowTextField(
            label: 'Ad',
            controller: guestNameController,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 10),
          GlowTextField(
            label: 'Soyad',
            controller: guestSurnameController,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 10),
          GlowTextField(
            label: 'Telefon',
            controller: guestPhoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: _required,
          ),
        ],
      ],
    );
  }

  static String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Bu alan zorunludur.' : null;
  }
}

class BookingResultCard extends StatelessWidget {
  const BookingResultCard({super.key, required this.result});

  final BookingResult result;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      backgroundColor: AppColors.roseTint,
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowMark(
            icon: result.waitingList
                ? Icons.hourglass_bottom_outlined
                : Icons.check_circle_outline,
          ),
          const SizedBox(height: 12),
          Text(
            result.waitingList
                ? 'Bekleme listesine eklendin'
                : 'Randevun oluşturuldu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Hizmet', value: result.serviceName ?? '-'),
          _SummaryRow(label: 'Alt hizmet', value: result.optionName ?? '-'),
          if (!result.waitingList)
            _SummaryRow(label: 'Personel', value: result.employeeName ?? '-'),
          _SummaryRow(label: 'Tarih', value: result.date ?? '-'),
          _SummaryRow(label: 'Saat', value: result.time ?? '-'),
          if (result.price != null)
            _SummaryRow(label: 'Fiyat', value: result.price!),
          _SummaryRow(label: 'Durum', value: result.status ?? '-'),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.step,
    required this.canContinue,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  final int step;
  final bool canContinue;
  final bool submitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlowButton(
            label: 'Geri',
            icon: Icons.chevron_left,
            variant: GlowButtonVariant.outlined,
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GlowButton(
            label: step == 5 ? 'Onayla' : 'Devam',
            icon: step == 5 ? Icons.check : Icons.chevron_right,
            loading: submitting,
            onPressed: canContinue ? (onSubmit ?? onNext) : null,
          ),
        ),
      ],
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    this.image,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final String? image;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.roseTint : AppColors.white,
            border: Border.all(
              color: selected ? AppColors.action : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              if (image == null)
                GlowMark(icon: icon, size: 40)
              else
                GlowCatalogImage(
                  semanticLabel: '$title görseli',
                  image: image,
                  icon: icon,
                  width: 48,
                  height: 48,
                  radius: 13,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.action : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${date.day} ${BookingDateUtils.dayLabel(date)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.action : AppColors.white,
            border: Border.all(
              color: selected ? AppColors.action : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                BookingDateUtils.dayLabel(date),
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 12),
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

class _UpcomingAppointments extends ConsumerWidget {
  const _UpcomingAppointments({required this.customerId});

  final int? customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (customerId == null) {
      return const GlowEmptyState(
        title: 'Misafir randevusu',
        message: 'Randevularını listelemek için müşteri hesabıyla giriş yap.',
        icon: Icons.lock_outline,
      );
    }
    final appointments =
        ref.watch(customerUpcomingAppointmentsProvider(customerId!));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Yaklaşan Randevularım',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        appointments.when(
          loading: () => const GlowLoading(message: 'Randevular yükleniyor'),
          error: (error, _) => GlowError(
            message: bookingErrorMessage(error)!,
            onRetry: () => ref
                .invalidate(customerUpcomingAppointmentsProvider(customerId!)),
          ),
          data: (items) => items.isEmpty
              ? const GlowEmptyState(title: 'Yaklaşan randevu yok')
              : Column(
                  children: [
                    for (final appointment in items) ...[
                      GlowAppointmentCard(
                        title:
                            appointment['serviceName']?.toString() ?? 'Randevu',
                        time:
                            '${appointment['appointmentDate'] ?? ''} ${BookingDateUtils.normalizeTime(appointment['appointmentTime']) ?? ''}',
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
