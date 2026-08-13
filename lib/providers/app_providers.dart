import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/config/api_config.dart';
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
  {
    'serviceId': 4,
    'serviceName': 'Kas ve Kirpik',
    'description': 'Kas alimi, kas tasarimi, lifting ve kirpik bakimi.',
    'serviceImage':
        'https://images.unsplash.com/photo-1519415510236-718bdfcd89c8?auto=format&fit=crop&w=900&q=80',
    'active': true,
  },
  {
    'serviceId': 5,
    'serviceName': 'Bolgesel Incelme',
    'description': 'Bolgesel incelme, sikilasma ve selulit bakimi seanslari.',
    'serviceImage':
        'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=900&q=80',
    'active': true,
  },
];

const _fallbackOptionsByService = <int, List<Map<String, dynamic>>>{
  1: [
    {
      'optionId': 101,
      'serviceId': 1,
      'optionName': 'Klasik Cilt Bakimi',
      'price': 900.0,
      'active': true
    },
    {
      'optionId': 102,
      'serviceId': 1,
      'optionName': 'Hydrafacial Bakim',
      'price': 1500.0,
      'active': true
    },
    {
      'optionId': 103,
      'serviceId': 1,
      'optionName': 'Anti Aging Bakim',
      'price': 1800.0,
      'active': true
    },
    {
      'optionId': 104,
      'serviceId': 1,
      'optionName': 'Leke Bakimi',
      'price': 1650.0,
      'active': true
    },
    {
      'optionId': 105,
      'serviceId': 1,
      'optionName': 'Akne Bakimi',
      'price': 1400.0,
      'active': true
    },
  ],
  2: [
    {
      'optionId': 201,
      'serviceId': 2,
      'optionName': 'Tek Bolge',
      'price': 450.0,
      'active': true
    },
    {
      'optionId': 202,
      'serviceId': 2,
      'optionName': '3 Bolge',
      'price': 1100.0,
      'active': true
    },
    {
      'optionId': 203,
      'serviceId': 2,
      'optionName': '5 Bolge',
      'price': 1650.0,
      'active': true
    },
    {
      'optionId': 204,
      'serviceId': 2,
      'optionName': 'Yuz Bolgesi',
      'price': 650.0,
      'active': true
    },
    {
      'optionId': 205,
      'serviceId': 2,
      'optionName': 'Tum Vucut',
      'price': 2200.0,
      'active': true
    },
  ],
  3: [
    {
      'optionId': 301,
      'serviceId': 3,
      'optionName': 'Aromaterapi Masaji',
      'price': 1200.0,
      'active': true
    },
    {
      'optionId': 302,
      'serviceId': 3,
      'optionName': 'Medikal Masaj',
      'price': 1450.0,
      'active': true
    },
  ],
  4: [
    {
      'optionId': 401,
      'serviceId': 4,
      'optionName': 'Kas Alimi',
      'price': 350.0,
      'active': true
    },
    {
      'optionId': 402,
      'serviceId': 4,
      'optionName': 'Kas Tasarimi',
      'price': 650.0,
      'active': true
    },
    {
      'optionId': 403,
      'serviceId': 4,
      'optionName': 'Kas Laminasyonu',
      'price': 900.0,
      'active': true
    },
    {
      'optionId': 404,
      'serviceId': 4,
      'optionName': 'Kirpik Lifting',
      'price': 950.0,
      'active': true
    },
  ],
  5: [
    {
      'optionId': 501,
      'serviceId': 5,
      'optionName': 'Karin Bolgesi',
      'price': 1450.0,
      'active': true
    },
    {
      'optionId': 502,
      'serviceId': 5,
      'optionName': 'Bacak Bolgesi',
      'price': 1550.0,
      'active': true
    },
    {
      'optionId': 503,
      'serviceId': 5,
      'optionName': 'Kol Bolgesi',
      'price': 1250.0,
      'active': true
    },
    {
      'optionId': 504,
      'serviceId': 5,
      'optionName': 'Selulit Bakimi',
      'price': 1650.0,
      'active': true
    },
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
    {
      'packageId': 102,
      'serviceId': 1,
      'serviceName': 'Cilt Bakimi',
      'packageName': 'Hydrafacial Bakim Paketi',
      'description': '5 seanslik nem ve parlaklik bakim paketi.',
      'totalSession': 5,
      'price': 6500.0,
      'active': true,
    },
  ],
  2: [
    {
      'packageId': 201,
      'serviceId': 2,
      'serviceName': 'Lazer Epilasyon',
      'packageName': '5 Bolge Lazer Paketi',
      'description': '10 seanslik 5 bolge lazer epilasyon paketi.',
      'totalSession': 10,
      'price': 1500.0,
      'active': true,
    },
    {
      'packageId': 202,
      'serviceId': 2,
      'serviceName': 'Lazer Epilasyon',
      'packageName': 'Tum Vucut Lazer Paketi',
      'description': '8 seanslik tum vucut lazer epilasyon programi.',
      'totalSession': 8,
      'price': 11500.0,
      'active': true,
    },
    {
      'packageId': 203,
      'serviceId': 2,
      'serviceName': 'Lazer Epilasyon',
      'packageName': 'Yuz Bolgesi Lazer Paketi',
      'description': '6 seanslik yuz bolgesi lazer epilasyon paketi.',
      'totalSession': 6,
      'price': 3200.0,
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
  4: [
    {
      'packageId': 401,
      'serviceId': 4,
      'serviceName': 'Kas ve Kirpik',
      'packageName': 'Kas Kirpik Bakim Paketi',
      'description': '4 seanslik kas ve kirpik bakim paketi.',
      'totalSession': 4,
      'price': 2600.0,
      'active': true,
    },
  ],
  5: [
    {
      'packageId': 501,
      'serviceId': 5,
      'serviceName': 'Bolgesel Incelme',
      'packageName': 'Incelme Programi',
      'description': '6 seanslik bolgesel incelme programi.',
      'totalSession': 6,
      'price': 7800.0,
      'active': true,
    },
    {
      'packageId': 502,
      'serviceId': 5,
      'serviceName': 'Bolgesel Incelme',
      'packageName': 'Sikilasma Paketi',
      'description': '8 seanslik bolgesel sikilasma ve selulit bakimi.',
      'totalSession': 8,
      'price': 9800.0,
      'active': true,
    },
  ],
};

const _fallbackEmployees = <Map<String, dynamic>>[
  {
    'employeeId': 'GLW001',
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
    if (!ApiConfig.allowDemoData) rethrow;
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
    if (!ApiConfig.allowDemoData) rethrow;
    return fallback;
  }
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
    packages.addAll(servicePackages.map((item) => {
          ...item,
          if ((item['packageImage']?.toString().trim().isEmpty ?? true) &&
              service['serviceImage'] != null)
            'packageImage': service['serviceImage'],
        }));
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
  (ref) =>
      _withListFallback(ref.watch(glowBackendServiceProvider).getCustomers),
);

final employeesByServiceOptionProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, EmployeeServiceOptionQuery>(
        (ref, query) {
  return ref.watch(glowBackendServiceProvider).getEmployeesByServiceOption(
        query.serviceId,
        query.optionId,
      );
});

final employeesByServiceProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, serviceId) {
  return ref.watch(glowBackendServiceProvider).getEmployeesByService(serviceId);
});

final availableSlotsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, AvailableSlotsQuery>((ref, query) {
  return ref.watch(glowBackendServiceProvider).getAvailableSlots(
        serviceId: query.serviceId,
        optionId: query.optionId,
        date: query.date,
      );
});

final availableSlotsForDatesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, AvailableSlotsBatchQuery>(
        (ref, query) async {
  final results = <Map<String, dynamic>>[];
  for (final date in query.dates) {
    final daySlots = await ref.watch(
      availableSlotsProvider(
        AvailableSlotsQuery(
          serviceId: query.serviceId,
          optionId: query.optionId,
          date: date,
        ),
      ).future,
    );
    results.addAll(daySlots);
  }
  return results;
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
    () => ref
        .watch(glowBackendServiceProvider)
        .getCustomerWaitingList(customerId),
  );
});

final appLoadingProvider = StateProvider<bool>((ref) => false);

class AvailableSlotsQuery {
  const AvailableSlotsQuery({
    required this.serviceId,
    required this.optionId,
    required this.date,
  });

  final int serviceId;
  final int optionId;
  final String date;

  @override
  bool operator ==(Object other) {
    return other is AvailableSlotsQuery &&
        other.serviceId == serviceId &&
        other.optionId == optionId &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(serviceId, optionId, date);
}

class EmployeeServiceOptionQuery {
  const EmployeeServiceOptionQuery(
      {required this.serviceId, required this.optionId});

  final int serviceId;
  final int optionId;

  @override
  bool operator ==(Object other) =>
      other is EmployeeServiceOptionQuery &&
      other.serviceId == serviceId &&
      other.optionId == optionId;

  @override
  int get hashCode => Object.hash(serviceId, optionId);
}

class AvailableSlotsBatchQuery {
  const AvailableSlotsBatchQuery({
    required this.serviceId,
    required this.optionId,
    required this.dates,
  });

  final int serviceId;
  final int optionId;
  final List<String> dates;

  @override
  bool operator ==(Object other) {
    return other is AvailableSlotsBatchQuery &&
        other.serviceId == serviceId &&
        other.optionId == optionId &&
        other.dates.join('|') == dates.join('|');
  }

  @override
  int get hashCode => Object.hash(serviceId, optionId, dates.join('|'));
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
