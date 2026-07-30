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

final servicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(glowBackendServiceProvider).getServices();
});

final serviceOptionsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, serviceId) {
  return ref.watch(glowBackendServiceProvider).getServiceOptions(serviceId);
});

final servicePackagesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, serviceId) {
  return ref.watch(glowBackendServiceProvider).getServicePackages(serviceId);
});

final profileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(glowBackendServiceProvider).getProfile();
});

final customerPackagesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return ref.watch(glowBackendServiceProvider).getCustomerPackages(customerId);
});

final customerUpcomingAppointmentsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return ref
      .watch(glowBackendServiceProvider)
      .getCustomerUpcomingAppointments(customerId);
});

final notificationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return ref.watch(glowBackendServiceProvider).getNotifications(customerId);
});

final unreadNotificationsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return ref
      .watch(glowBackendServiceProvider)
      .getUnreadNotifications(customerId);
});

final employeesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(glowBackendServiceProvider).getEmployees(),
);

final customersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(glowBackendServiceProvider).getCustomers(),
);

final employeesByServiceProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, serviceId) {
  return ref.watch(glowBackendServiceProvider).getEmployeesByService(serviceId);
});

final availableSlotsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, AvailableSlotsQuery>((ref, query) {
  return ref.watch(glowBackendServiceProvider).getAvailableSlots(
        serviceId: query.serviceId,
        date: query.date,
      );
});

final workingHoursProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(glowBackendServiceProvider).getWorkingHours();
});

final holidaysProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, DateRangeQuery>((ref, query) {
  return ref.watch(glowBackendServiceProvider).getHolidays(
        startDate: query.startDate,
        endDate: query.endDate,
      );
});

final activeWaitingListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(glowBackendServiceProvider).getActiveWaitingList();
});

final customerWaitingListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, customerId) {
  return ref
      .watch(glowBackendServiceProvider)
      .getCustomerWaitingList(customerId);
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
