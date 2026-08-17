import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/glow_widgets.dart';
import '../../providers/app_providers.dart';
import '../catalog/catalog_models.dart';
import 'booking_models.dart';

/// Ordered stages of the booking wizard. The concrete sequence depends on how
/// much the customer already chose before entering — see [_AppointmentPageState._stepKinds].
enum BookingStepKind { service, option, employee, date, time, summary }

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

/// Explicit submission outcomes for the final confirmation. Exactly one of
/// [success] or [failure] is ever reached per submission — never both — which
/// is what keeps a stale success state from coexisting with a later conflict.
enum _BookingSubmission { idle, submitting, success, failure }

class AppointmentPage extends ConsumerStatefulWidget {
  const AppointmentPage({super.key, this.packageContext});

  /// Set when the customer arrived from a package: the package already fixes the
  /// service, so the wizard skips straight to employee → tarih → saat → özet.
  final PackageBookingContext? packageContext;

  @override
  ConsumerState<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends ConsumerState<AppointmentPage> {
  final _guestFormKey = GlobalKey<FormState>();
  final _guestNameController = TextEditingController();
  final _guestSurnameController = TextEditingController();
  final _guestPhoneController = TextEditingController();

  /// The wizard is one long [SingleChildScrollView] shared by every step, so
  /// its scroll offset otherwise carries over between steps. Advancing from a
  /// long step (e.g. the package list) to a short one (e.g. the calendar)
  /// then just clamps that old offset to the new, smaller content — leaving
  /// the calendar's month header scrolled above the viewport, its navigation
  /// arrows unreachable. Resetting to the top on every step change keeps each
  /// step's content, including that header, visible from the start.
  final _scrollController = ScrollController();

  var _step = 0;
  PackageBookingContext? _packageContext;
  CatalogService? _service;
  CatalogOption? _option;
  CustomerPackageOption? _customerPackage;
  String? _packageEmployeeId;
  String? _packageEmployeeName;
  var _candidateDates = <DateTime>[
    BookingDateUtils.today().add(const Duration(days: 1)),
  ];
  DateTime _date = BookingDateUtils.today().add(const Duration(days: 1));
  String? _time;
  BookingSlot? _slot;
  _BookingSubmission _submission = _BookingSubmission.idle;
  bool _joiningWaitlist = false;
  BookingResult? _result;

  bool get _submitting => _submission == _BookingSubmission.submitting;

  @override
  void initState() {
    super.initState();
    final context = widget.packageContext;
    if (context == null) return;
    _packageContext = context;
    // Carry the already chosen service (and sub-service, when unambiguous) forward
    // instead of asking for them a second time.
    _service = CatalogService(
      id: context.serviceId,
      name: context.serviceName ?? 'Seçilen hizmet',
    );
    if (context.optionId != null) {
      _option = CatalogOption(
        id: context.optionId,
        serviceId: context.serviceId,
        name: 'Paket kapsamındaki hizmet',
      );
    }
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestSurnameController.dispose();
    _guestPhoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls the wizard back to the top so the new step's content — including
  /// a header like the calendar's month navigation — starts fully in view.
  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  /// Normal booking keeps its original order. Package booking drops the service
  /// step entirely and asks for the covered sub-service only when the package
  /// genuinely covers more than one.
  List<BookingStepKind> get _stepKinds {
    final context = _packageContext;
    if (context == null) {
      return const [
        BookingStepKind.service,
        BookingStepKind.option,
        BookingStepKind.date,
        BookingStepKind.time,
        BookingStepKind.employee,
        BookingStepKind.summary,
      ];
    }
    return [
      if (!context.hasKnownOption) BookingStepKind.option,
      BookingStepKind.employee,
      BookingStepKind.date,
      BookingStepKind.time,
      BookingStepKind.summary,
    ];
  }

  bool get _packageMode => _packageContext != null;

  BookingStepKind get _currentStep =>
      _stepKinds[_step.clamp(0, _stepKinds.length - 1)];

  int get _lastStepIndex => _stepKinds.length - 1;

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

    // Android's hardware back button and iOS's swipe-back gesture must step
    // through the wizard exactly like the in-page "Geri" button — not jump
    // straight out of the page, which would skip the required
    // Summary → Time → Date → Employee sequence. Only the first step (and a
    // submission in flight, so an in-progress request is never abandoned)
    // lets the system gesture leave the page.
    return PopScope(
      canPop: _step == 0 && !_submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _submitting) return;
        setState(() => _step--);
        _scrollToTop();
      },
      child: Scaffold(
        body: SafeArea(
          child: GlowResponsivePage(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 106),
            child: Form(
              key: _guestFormKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlowPageTop(
                      title: _packageMode
                          ? 'Paketinle randevu al'
                          : 'Randevu oluştur',
                      subtitle: _packageMode
                          ? '${_packageContext!.packageName ?? 'Paketin'} için personelini, tarihini ve saatini seç.'
                          : 'Hizmetini seç, sana uygun saati kolayca planla.',
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
                    BookingStepper(currentStep: _step, steps: _stepLabels),
                    const SizedBox(height: 18),
                    if (_packageMode) ...[
                      _PackageContextBanner(context: _packageContext!),
                      const SizedBox(height: 18),
                    ],
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
                      isLastStep: _step == _lastStepIndex,
                      canContinue: _canContinue(customerId),
                      submitting: _submitting,
                      onBack: _step == 0
                          ? null
                          : () {
                              setState(() => _step--);
                              _scrollToTop();
                            },
                      onNext: _step < _lastStepIndex ? _goNext : null,
                      onSubmit: _step == _lastStepIndex
                          ? () => _confirmAndSubmit(customerId)
                          : null,
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
      ),
    );
  }

  List<String> get _stepLabels =>
      _stepKinds.map(_shortLabelFor).toList(growable: false);

  static String _shortLabelFor(BookingStepKind kind) {
    switch (kind) {
      case BookingStepKind.service:
        return 'Hizmet';
      case BookingStepKind.option:
        return 'Seçenek';
      case BookingStepKind.employee:
        return 'Personel';
      case BookingStepKind.date:
        return 'Tarih';
      case BookingStepKind.time:
        return 'Saat';
      case BookingStepKind.summary:
        return 'Özet';
    }
  }

  String get _stepTitle {
    switch (_currentStep) {
      case BookingStepKind.service:
        return 'Hizmet seçimi';
      case BookingStepKind.option:
        return _packageMode
            ? 'Paket kapsamındaki hizmeti seç'
            : 'Alt hizmet ve paket';
      case BookingStepKind.employee:
        return 'Personel seçimi';
      case BookingStepKind.date:
        return 'Tarih seçimi';
      case BookingStepKind.time:
        return 'Uygun zaman aralığı';
      case BookingStepKind.summary:
        return 'Randevu özeti';
    }
  }

  Widget _buildStep({
    required AsyncValue<List<Map<String, dynamic>>> services,
    required AsyncValue<List<Map<String, dynamic>>>? slots,
    required int? customerId,
    required bool signedIn,
  }) {
    switch (_currentStep) {
      case BookingStepKind.service:
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
      case BookingStepKind.option:
        if (_service?.id == null) {
          return const GlowEmptyState(title: 'Hizmet seç');
        }
        final options = ref.watch(serviceOptionsProvider(_service!.id!));
        if (_packageMode) {
          // The package already fixed the service; only its own covered
          // sub-services are offered — never the wider service catalog, which
          // is what previously let an unrelated sub-service (e.g. Akne
          // Bakımı under a Hydrafacial-only package) slip through.
          final coveredIds = _packageContext!.coveredOptionIds.toSet();
          return _CoveredOptionStep(
            options: options.whenData(
              (items) => items
                  .where(
                      (item) => coveredIds.contains(_asInt(item['optionId'])))
                  .toList(growable: false),
            ),
            selectedOption: _option,
            onSelected: _selectCoveredOption,
          );
        }
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
      case BookingStepKind.date:
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
      case BookingStepKind.time:
        return _TimeStep(
          slots: slots,
          selectedDate: _date,
          selectedTime: _time,
          selectedEmployeeId: _slot?.employeeId,
          onlyEmployeeId: _packageMode ? _packageEmployeeId : null,
          onTimeSelected: (choice) => setState(() {
            _date = choice.date;
            _time = choice.time;
            _slot = choice.slot;
          }),
          onRetry: _refreshSlots,
          onJoinWaitlist: () => _joinWaitlist(customerId),
          joiningWaitlist: _joiningWaitlist,
        );
      case BookingStepKind.employee:
        if (_packageMode) {
          final serviceId = _service?.id;
          final optionId = _option?.id;
          if (serviceId == null || optionId == null) {
            return const GlowEmptyState(title: 'Önce paket hizmetini seç');
          }
          return _PackageEmployeeStep(
            employees: ref.watch(employeesByServiceOptionProvider(
              EmployeeServiceOptionQuery(
                serviceId: serviceId,
                optionId: optionId,
              ),
            )),
            selectedEmployeeId: _packageEmployeeId,
            onSelected: (id, name) => setState(() {
              _packageEmployeeId = id;
              _packageEmployeeName = name;
              _time = null;
              _slot = null;
            }),
          );
        }
        return _EmployeeStep(
          slots: slots,
          selectedDate: _date,
          selectedTime: _time,
          selectedSlot: _slot,
          onSelected: (slot) => setState(() => _slot = slot),
          onRetry: _refreshSlots,
        );
      case BookingStepKind.summary:
        return _SummaryStep(
          signedIn: signedIn,
          service: _service,
          option: _displayOption(),
          package: _customerPackage,
          packageContext: _packageContext,
          date: _date,
          time: _time,
          employeeName:
              _packageMode ? _packageEmployeeName : _slot?.employeeName,
          slot: _slot,
          guestNameController: _guestNameController,
          guestSurnameController: _guestSurnameController,
          guestPhoneController: _guestPhoneController,
        );
    }
  }

  /// In package mode the option name is only a placeholder until the catalog
  /// loads; show the real one when it is available.
  CatalogOption? _displayOption() {
    final serviceId = _service?.id;
    final optionId = _option?.id;
    if (!_packageMode || serviceId == null || optionId == null) return _option;
    final loaded = ref.watch(serviceOptionsProvider(serviceId)).asData?.value;
    if (loaded == null) return _option;
    for (final option in mapCatalogOptions(loaded)) {
      if (option.id == optionId) return option;
    }
    return _option;
  }

  void _selectCoveredOption(CatalogOption option) {
    final optionId = option.id;
    if (optionId == null) return;
    setState(() {
      _option = option;
      _packageContext = _packageContext?.withOption(optionId);
      _packageEmployeeId = null;
      _packageEmployeeName = null;
      _time = null;
      _slot = null;
    });
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
    _scrollToTop();
  }

  bool _canContinue(int? customerId) {
    switch (_currentStep) {
      case BookingStepKind.service:
        return _service?.id != null;
      case BookingStepKind.option:
        return _option?.id != null;
      case BookingStepKind.date:
        return _candidateDates.isNotEmpty &&
            _candidateDates.every((date) => !BookingDateUtils.isPast(date));
      case BookingStepKind.time:
        return _time != null;
      case BookingStepKind.employee:
        return _packageMode
            ? _packageEmployeeId?.isNotEmpty == true
            : _slot?.employeeId.isNotEmpty == true;
      case BookingStepKind.summary:
        return _service?.id != null &&
            _option?.id != null &&
            _time != null &&
            _slot?.employeeId.isNotEmpty == true &&
            // A package booking always belongs to a signed-in customer.
            (customerId != null ||
                (!_packageMode &&
                    (_guestFormKey.currentState?.validate() ?? false)));
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
    if (_submission == _BookingSubmission.submitting) return;
    if (customerId == null &&
        !(_guestFormKey.currentState?.validate() ?? false)) {
      GlowSnackBar.showError(context, 'Misafir bilgilerini tamamla.');
      return;
    }
    final confirmed = await GlowDialog.showConfirmation(
      context,
      title: _packageContext?.needsPurchase == true
          ? 'Paketi al ve randevuyu onayla'
          : 'Randevuyu onayla',
      message: _packageContext?.needsPurchase == true
          ? 'Paketin hesabına eklenecek ve ilk randevun oluşturulacak.'
          : 'Seçtiğin saatin uygunluğu son kez kontrol edilecek.',
      confirmLabel: 'Onayla',
    );
    if (confirmed != true) return;
    await _submitAppointment(customerId);
  }

  Future<void> _submitAppointment(int? customerId) async {
    // A double tap that lands here while the previous submission is still in
    // flight must not fire a second request. GlowButton's `loading` state
    // already disables the confirm button for the same reason.
    if (_submission == _BookingSubmission.submitting) return;

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

    setState(() => _submission = _BookingSubmission.submitting);

    // Only the request itself is a candidate for "booking failed" — anything
    // that happens after a genuine backend success (navigation, resetting
    // wizard state) must never be reinterpreted as a failed booking.
    final packageContext = _packageContext;
    late final Map<String, dynamic> response;
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

      if (packageContext != null &&
          packageContext.needsPurchase &&
          customerId != null) {
        // One call buys the package and books its first appointment atomically,
        // so a failure never leaves a paid package without a booking.
        response = await ref
            .read(glowBackendServiceProvider)
            .purchasePackageWithFirstAppointment(
              customerId: customerId,
              packageId: packageContext.packageId,
              employeeId: employeeId,
              optionId: optionId,
              appointmentDate: BookingDateUtils.formatDate(_date),
              appointmentTime: time,
            );
      } else {
        response =
            await ref.read(glowBackendServiceProvider).createAppointment({
          if (customerId != null) 'customerId': customerId,
          if (_customerPackage?.customerPackageId != null)
            'customerPackageId': _customerPackage!.customerPackageId
          else if (packageContext?.customerPackageId != null)
            'customerPackageId': packageContext!.customerPackageId,
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
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _submission = _BookingSubmission.failure);
      if (isStaleSlotError(error)) {
        // Send the customer back to the time step, keeping package, service,
        // employee and date selections intact.
        final timeStep = _stepKinds.indexOf(BookingStepKind.time);
        setState(() {
          if (timeStep >= 0) _step = timeStep;
          _time = null;
          _slot = null;
        });
        _scrollToTop();
      }
      GlowSnackBar.showError(
        context,
        bookingErrorMessage(error) ?? 'Randevu oluşturulamadı.',
      );
      setState(() => _submission = _BookingSubmission.idle);
      return;
    }

    // The backend confirmed the booking. From here on this is exactly one
    // success outcome — no later step may downgrade it back to a failure.
    if (!mounted) return;
    setState(() => _submission = _BookingSubmission.success);
    await _completeBookingSuccess(
      customerId: customerId,
      response: response,
      packageContext: packageContext,
    );
  }

  /// Runs exactly once, right after the backend confirms the booking. Shows a
  /// short toast, refreshes the customer's appointment/package state so the
  /// new booking is visible without a manual refresh, clears every temporary
  /// wizard selection, and leaves the booking wizard entirely — a registered
  /// customer lands on Randevularım, a guest sees a concise confirmation and
  /// is sent to a page that does not require an account.
  Future<void> _completeBookingSuccess({
    required int? customerId,
    required Map<String, dynamic> response,
    required PackageBookingContext? packageContext,
  }) async {
    if (customerId != null) {
      ref.invalidate(customerUpcomingAppointmentsProvider(customerId));
      ref.invalidate(customerPastAppointmentsProvider(customerId));
      ref.invalidate(customerPackagesProvider(customerId));
    }
    if (!mounted) return;

    final appointmentJson = response['appointment'];
    final result = BookingResult.appointment(
      appointmentJson is Map<String, dynamic> ? appointmentJson : response,
    );

    GlowSnackBar.showSuccess(
      context,
      packageContext?.needsPurchase == true
          ? 'Paketin eklendi ve ilk randevun oluşturuldu.'
          : 'Randevun başarıyla oluşturuldu.',
    );

    _resetBookingState();
    if (!mounted) return;

    if (customerId != null) {
      AppNavigation.go(context, AppRoutes.profile);
      return;
    }

    // Guests have no persistent Randevularım account page — show a concise
    // confirmation instead, then land on a destination that needs no login.
    await _showGuestBookingConfirmation(result);
    if (!mounted) return;
    AppNavigation.go(context, AppRoutes.home);
  }

  Future<void> _showGuestBookingConfirmation(BookingResult result) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Randevun oluşturuldu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(label: 'Hizmet', value: result.serviceName ?? '-'),
            _SummaryRow(label: 'Alt Hizmet', value: result.optionName ?? '-'),
            _SummaryRow(label: 'Personel', value: result.employeeName ?? '-'),
            _SummaryRow(label: 'Tarih', value: result.date ?? '-'),
            _SummaryRow(label: 'Saat', value: result.time ?? '-'),
          ],
        ),
        actions: [
          GlowButton(
            label: 'Tamam',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  /// Clears every transient wizard selection. Only ever called after the
  /// backend has confirmed success — a failed request must leave the
  /// customer's in-progress selections untouched so they can simply retry.
  void _resetBookingState() {
    if (!mounted) return;
    final tomorrow = BookingDateUtils.today().add(const Duration(days: 1));
    setState(() {
      _step = 0;
      _packageContext = null;
      _service = null;
      _option = null;
      _customerPackage = null;
      _packageEmployeeId = null;
      _packageEmployeeName = null;
      _candidateDates = [tomorrow];
      _date = tomorrow;
      _time = null;
      _slot = null;
      _result = null;
      _submission = _BookingSubmission.idle;
    });
    _guestNameController.clear();
    _guestSurnameController.clear();
    _guestPhoneController.clear();
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
      _scrollToTop();
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
  const BookingStepper({
    super.key,
    required this.currentStep,
    this.steps = const [
      'Hizmet',
      'Seçenek',
      'Tarih',
      'Saat',
      'Personel',
      'Özet'
    ],
  });

  final int currentStep;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
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

/// Shows what the customer already chose, so the skipped steps stay visible.
class _PackageContextBanner extends StatelessWidget {
  const _PackageContextBanner({required this.context});

  final PackageBookingContext context;

  @override
  Widget build(BuildContext buildContext) {
    return GlowCard(
      key: const Key('package_booking_context'),
      backgroundColor: AppColors.roseTint,
      borderColor: AppColors.primary,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.packageName ?? 'Seçtiğin paket',
            style: Theme.of(buildContext).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${context.serviceName ?? 'Hizmetin'} seçildi'
            '${context.totalSession == null ? '' : ' • ${context.totalSession} seans'}',
            style: Theme.of(buildContext).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Hizmetini tekrar seçmene gerek yok.',
            style: Theme.of(buildContext).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Sub-service picker used only when a package covers more than one option.
class _CoveredOptionStep extends StatelessWidget {
  const _CoveredOptionStep({
    required this.options,
    required this.selectedOption,
    required this.onSelected,
  });

  final AsyncValue<List<Map<String, dynamic>>> options;
  final CatalogOption? selectedOption;
  final ValueChanged<CatalogOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return options.when(
      loading: () => const GlowLoading(message: 'Seçenekler yükleniyor'),
      error: (error, _) => GlowError(message: bookingErrorMessage(error)!),
      data: (items) {
        final mapped = mapCatalogOptions(items);
        if (mapped.isEmpty) {
          return const GlowEmptyState(title: 'Paket kapsamında seçenek yok');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paketin birden fazla seçeneği kapsıyor. Hangisiyle başlamak istersin?',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            for (final option in mapped) ...[
              _SelectableTile(
                title: option.name,
                subtitle: option.priceText ?? 'Paket kapsamında',
                icon: Icons.spa_outlined,
                selected: selectedOption?.id == option.id,
                onTap: option.id == null ? null : () => onSelected(option),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

/// Employee picker for the package flow, shown before tarih/saat.
class _PackageEmployeeStep extends StatelessWidget {
  const _PackageEmployeeStep({
    required this.employees,
    required this.selectedEmployeeId,
    required this.onSelected,
  });

  final AsyncValue<List<Map<String, dynamic>>> employees;
  final String? selectedEmployeeId;
  final void Function(String employeeId, String employeeName) onSelected;

  @override
  Widget build(BuildContext context) {
    return employees.when(
      loading: () => const GlowLoading(message: 'Personeller yükleniyor'),
      error: (error, _) => GlowError(message: bookingErrorMessage(error)!),
      data: (items) {
        final people = items
            .map(_toEmployeeChoice)
            .whereType<_EmployeeChoice>()
            .toList(growable: false);
        if (people.isEmpty) {
          return const GlowEmptyState(
            title: 'Personel bulunamadı',
            message: 'Bu hizmet için şu an uygun personel yok.',
            icon: Icons.person_off_outlined,
          );
        }
        return Column(
          key: const Key('package_employee_step'),
          children: [
            for (final person in people) ...[
              _SelectableTile(
                title: person.name,
                subtitle: 'Bu personelle devam et',
                icon: Icons.person_outline,
                selected: selectedEmployeeId == person.id,
                onTap: () => onSelected(person.id, person.name),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  static _EmployeeChoice? _toEmployeeChoice(Map<String, dynamic> json) {
    final id = json['employeeId']?.toString().trim();
    if (id == null || id.isEmpty) return null;
    final name = [json['firstName'], json['lastName']]
        .where((item) => item != null && item.toString().trim().isNotEmpty)
        .join(' ')
        .trim();
    final fallback = json['employeeName']?.toString().trim();
    return _EmployeeChoice(
      id,
      name.isNotEmpty
          ? name
          : (fallback == null || fallback.isEmpty ? 'Personel' : fallback),
    );
  }
}

class _EmployeeChoice {
  const _EmployeeChoice(this.id, this.name);

  final String id;
  final String name;
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
          'Birden fazla tarih seçebilirsin. Uygun saatler sonraki adımda birlikte listelenir.',
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
    this.onlyEmployeeId,
  });

  final AsyncValue<List<Map<String, dynamic>>>? slots;
  final DateTime selectedDate;
  final String? selectedTime;
  final String? selectedEmployeeId;

  /// Package booking picks the employee first, so only that employee's hours show.
  final String? onlyEmployeeId;
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
                message: 'Bu tarih için uygun bir saat bulunamadı.',
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
      if (onlyEmployeeId != null && slot.employeeId != onlyEmployeeId) continue;
      for (final time in slot.availableTimes) {
        if (BookingDateUtils.isFutureFullHourSlot(slot.date, time)) {
          choices
              .add(BookingTimeChoice(date: slot.date, time: time, slot: slot));
        }
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
            message: 'Seçilen saat için uygun personel bulunamadı.',
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
    required this.packageContext,
    required this.date,
    required this.time,
    required this.employeeName,
    required this.slot,
    required this.guestNameController,
    required this.guestSurnameController,
    required this.guestPhoneController,
  });

  final bool signedIn;
  final CatalogService? service;
  final CatalogOption? option;
  final CustomerPackageOption? package;
  final PackageBookingContext? packageContext;
  final DateTime date;
  final String? time;
  final String? employeeName;
  final BookingSlot? slot;
  final TextEditingController guestNameController;
  final TextEditingController guestSurnameController;
  final TextEditingController guestPhoneController;

  @override
  Widget build(BuildContext context) {
    final packageLabel = packageContext?.packageName ?? package?.name;
    return Column(
      children: [
        _SummaryRow(label: 'Hizmet', value: service?.name ?? '-'),
        _SummaryRow(label: 'Alt Hizmet', value: option?.name ?? '-'),
        _SummaryRow(label: 'Fiyat', value: option?.priceText ?? 'Fiyat yok'),
        _SummaryRow(label: 'Paket', value: packageLabel ?? 'Paket yok'),
        if (packageContext != null)
          _SummaryRow(
            label: 'Seans',
            value: 'Bu randevu 1 seans kullanır'
                '${packageContext!.totalSession == null ? '' : ' (toplam ${packageContext!.totalSession} seans)'}',
          ),
        _SummaryRow(label: 'Tarih', value: BookingDateUtils.formatDate(date)),
        _SummaryRow(label: 'Saat', value: time ?? '-'),
        _SummaryRow(
            label: 'Personel',
            value: employeeName ?? slot?.employeeName ?? '-'),
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
          _SummaryRow(label: 'Alt Hizmet', value: result.optionName ?? '-'),
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
    required this.isLastStep,
    required this.canContinue,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  final bool isLastStep;
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
            label: isLastStep ? 'Onayla' : 'Devam',
            icon: isLastStep ? Icons.check : Icons.chevron_right,
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

/// One label/value line for a summary list (Randevu Özeti, booking result
/// cards, confirmation dialogs). Both columns use [Expanded] with a fixed
/// flex ratio, never [Flexible] — a loosely-fit value shrinks to its own
/// content width instead of the space it was allocated, which is what let
/// short values (a time, a price) start flush after the label while a long
/// one (a service/package name) rendered as if it belonged to a different
/// column. With both sides [Expanded], every row's label starts at the same
/// x, every row's value starts at the same x, and a long value wraps inside
/// its own fixed-width column instead of resizing that column.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
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
