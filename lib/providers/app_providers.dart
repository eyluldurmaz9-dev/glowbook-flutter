import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/services/api_service.dart';
import '../core/services/glow_backend_service.dart';
import '../core/storage/preferences_service.dart';
import '../core/storage/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final preferencesServiceProvider =
    FutureProvider<PreferencesService>((ref) async {
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return PreferencesService(preferences);
});

final apiClientProvider = Provider<GlowApiClient>((ref) {
  return GlowApiClient(secureStorage: ref.watch(secureStorageProvider));
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(apiClientProvider));
});

final glowBackendServiceProvider = Provider<GlowBackendService>((ref) {
  return GlowBackendService(
    ref.watch(apiServiceProvider),
    ref.watch(secureStorageProvider),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(ref.watch(glowBackendServiceProvider))..loadSession();
});

const _fallbackServices = <Map<String, dynamic>>[
  {
    'serviceId': 1,
    'serviceName': 'Cilt Bakimi',
    'description':
        "Cilt analizi, derin temizlik ve nem bakimi ile GlowBook'un imza bakim deneyimi.",
    'serviceImage':
        'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?auto=format&fit=crop&w=900&q=80',
    'active': true,
  },
  {
    'serviceId': 2,
    'serviceName': 'Lazer Epilasyon',
    'description':
        'Konforlu randevu akisiyla bolge bazli lazer epilasyon hizmetleri.',
    'serviceImage':
        'https://images.unsplash.com/photo-1515377905703-c4788e51af15?auto=format&fit=crop&w=900&q=80',
    'active': true,
  },
  {
    'serviceId': 3,
    'serviceName': 'Masaj ve Spa',
    'description': 'Rahatlatan masaj seanslari ve spa bakimlari.',
    'serviceImage':
        'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=900&q=80',
    'active': true,
  },
];

const _fallbackOptionsByService = <int, List<Map<String, dynamic>>>{
  1: [
    {'optionId': 101, 'serviceId': 1, 'optionName': 'Klasik Cilt Bakimi', 'price': 900.0, 'active': true},
    {'optionId': 102, 'serviceId': 1, 'optionName': 'Hydrafacial Bakim', 'price': 1500.0, 'active': true},
  ],
  2: [
    {'optionId': 201, 'serviceId': 2, 'optionName': 'Tum Vucut', 'price': 2200.0, 'active': true},
    {'optionId': 202, 'serviceId': 2, 'optionName': 'Yuz Bolgesi', 'price': 650.0, 'active': true},
  ],
  3: [
    {'optionId': 301, 'serviceId': 3, 'optionName': 'Aromaterapi Masaji', 'price': 1200.0, 'active': true},
    {'optionId': 302, 'serviceId': 3, 'optionName': 'Medikal Masaj', 'price': 1450.0, 'active': true},
  ],
};

const _fallbackPackagesByService = <int, List<Map<String, dynamic>>>{
  1: [
    {
      'packageId': 101,
      'serviceId': 1,
      'serviceName': 'Cilt Bakimi',
      'packageName': 'Glow Cilt Paketi',
      'description': '4 seanslik yenileyici cilt bakimi paketi.',
      'totalSession': 4,
      'price': 5200.0,
      'active': true,
    },
  ],
  2: [
    {
      'packageId': 201,
      'serviceId': 2,
      'serviceName': 'Lazer Epilasyon',
      'packageName': 'Lazer Devam Paketi',
      'description': '6 seanslik avantajli lazer epilasyon paketi.',
      'totalSession': 6,
      'price': 11500.0,
      'active': true,
    },
  ],
  3: [
    {
      'packageId': 301,
      'serviceId': 3,
      'serviceName': 'Masaj ve Spa',
      'packageName': 'Spa Yenilenme Paketi',
      'description': '3 seanslik masaj ve spa paketi.',
      'totalSession': 3,
      'price': 3600.0,
      'active': true,
    },
  ],
};

const _fallbackEmployees = <Map<String, dynamic>>[
  {
    'employeeId': 'GLW-001',
    'firstName': 'GlowBook',
    'lastName': 'Uzmani',
    'fullName': 'GlowBook Uzmani',
    'employeeName': 'GlowBook Uzmani',
    'phone': 'Uygun personel',
    'active': true,
  },
];

Future<List<Map<String, dynamic>>> _withCatalogFallback(
  Future<List<Map<String, dynamic>>> Function() request,
  List<Map<String, dynamic>> fallback,
) async {
  try {
    final items = await request();
    return items.isEmpty ? fallback : items;
  } catch (_) {
    return fallback;
  }
}

Future<List<Map<String, dynamic>>> _withListFallback(
  Future<List<Map<String, dynamic>>> Function() request, [
  List<Map<String, dynamic>> fallback = const [],
]) async {
  try {
    return await request();
  } catch (_) {
    return fallback;
  }
}

List<Map<String, dynamic>> _fallbackSlotsFor(String date) {
  return [
    {
      'employeeId': 'GLW-001',
      'employeeName': 'GlowBook Uzmani',
      'appointmentDate': date,
      'availableTimes': const ['10:00', '11:00', '14:00', '15:00', '16:00'],
    },
  ];
}

final servicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return _withCatalogFallback(
    ref.watch(glowBackendServiceProvider).getServices,
    _fallbackServices,
  );
});

final serviceOptionsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, serviceId) {
  return _withCatalogFallback(
    () => ref.watch(glowBackendServiceProvider).getServiceOptions(serviceId),
    _fallbackOptionsByService[serviceId] ?? const [],
  );
});

final servicePackagesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, serviceId) {
  return _withCatalogFallback(
    () => ref.watch(glowBackendServiceProvider).getServicePackages(serviceId),
    _fallbackPackagesByService[serviceId] ?? const [],
  );
});

final allServicePackagesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final services = await ref.watch(servicesProvider.future);
  final packages = <Map<String, dynamic>>[];
  for (final service in services) {
    final serviceId = service['serviceId'];
    if (serviceId is! int) continue;
    final servicePackages = await ref.watch(
      servicePackagesProvider(serviceId).future,
    );
    packages.addAll(servicePackages);
  }
  return packages;
});

final profileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(glowBackendServiceProvider).getProfile();
});

final customerPackagesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return _withListFallback(
    () => ref.watch(glowBackendServiceProvider).getCustomerPackages(customerId),
  );
});

final customerUpcomingAppointmentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return _withListFallback(
    () => ref
        .watch(glowBackendServiceProvider)
        .getCustomerUpcomingAppointments(customerId),
  );
});

final customerPastAppointmentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return _withListFallback(
    () => ref
        .watch(glowBackendServiceProvider)
        .getCustomerPastAppointments(customerId),
  );
});

final notificationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return _withListFallback(
    () => ref.watch(glowBackendServiceProvider).getNotifications(customerId),
  );
});

final unreadNotificationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return _withListFallback(
    () => ref
        .watch(glowBackendServiceProvider)
        .getUnreadNotifications(customerId),
  );
});

final employeesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => _withListFallback(
    ref.watch(glowBackendServiceProvider).getEmployees,
    _fallbackEmployees,
  ),
);

final customersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => _withListFallback(ref.watch(glowBackendServiceProvider).getCustomers),
);

final employeesByServiceProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, serviceId) {
  return _withListFallback(
    () => ref.watch(glowBackendServiceProvider).getEmployeesByService(serviceId),
    _fallbackEmployees,
  );
});

final availableSlotsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, AvailableSlotsQuery>((ref, query) {
  return _withListFallback(
    () => ref.watch(glowBackendServiceProvider).getAvailableSlots(
          serviceId: query.serviceId,
          date: query.date,
        ),
    _fallbackSlotsFor(query.date),
  );
});

final workingHoursProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return _withListFallback(
    ref.watch(glowBackendServiceProvider).getWorkingHours,
  );
});

final employeeAppointmentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, EmployeeAppointmentsQuery>(
        (ref, query) {
  return ref.watch(glowBackendServiceProvider).getEmployeeAppointments(
        employeeId: query.employeeId,
        startDate: query.startDate,
        endDate: query.endDate,
      );
});

final holidaysProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, DateRangeQuery>((ref, query) {
  return _withListFallback(
    () => ref.watch(glowBackendServiceProvider).getHolidays(
          startDate: query.startDate,
          endDate: query.endDate,
        ),
  );
});

final activeWaitingListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return _withListFallback(
    ref.watch(glowBackendServiceProvider).getActiveWaitingList,
  );
});

final customerWaitingListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return _withListFallback(
    () => ref.watch(glowBackendServiceProvider).getCustomerWaitingList(customerId),
  );
});

final appLoadingProvider = StateProvider<bool>((ref) => false);

class AvailableSlotsQuery {
  const AvailableSlotsQuery({required this.serviceId, required this.date});

  final int serviceId;
  final String date;

  @override
  bool operator ==(Object other) {
    return other is AvailableSlotsQuery &&
        other.serviceId == serviceId &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(serviceId, date);
}

class DateRangeQuery {
  const DateRangeQuery({required this.startDate, required this.endDate});

  final String startDate;
  final String endDate;

  @override
  bool operator ==(Object other) {
    return other is DateRangeQuery &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate);
}

class EmployeeAppointmentsQuery {
  const EmployeeAppointmentsQuery({
    required this.employeeId,
    required this.startDate,
    required this.endDate,
  });

  final String employeeId;
  final String startDate;
  final String endDate;

  @override
  bool operator ==(Object other) {
    return other is EmployeeAppointmentsQuery &&
        other.employeeId == employeeId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(employeeId, startDate, endDate);
}

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._backend) : super(const AsyncValue.loading());

  final AuthBackend _backend;

  Future<void> loadSession() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_backend.currentSession);
  }

  Future<void> login({
    required String username,
    required String password,
    String role = 'CUSTOMER',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _backend.login(username: username, password: password, role: role),
    );
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _backend.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
        email: email,
      ),
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _backend.logout();
    state = const AsyncValue.data(null);
  }
}
