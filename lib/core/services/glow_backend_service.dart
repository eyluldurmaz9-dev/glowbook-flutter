import 'package:dio/dio.dart';

import '../api/api_exception.dart';
import '../api/api_response.dart';
import '../storage/secure_storage_service.dart';
import 'api_service.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    this.refreshToken,
    this.tokenType,
    this.role,
    this.customerId,
    this.employeeId,
    this.fullName,
  });

  final String token;
  final String? refreshToken;
  final String? tokenType;
  final String? role;
  final int? customerId;
  final String? employeeId;
  final String? fullName;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String?,
      role: json['role'] as String?,
      customerId: json['customerId'] as int?,
      employeeId: json['employeeId'] as String?,
      fullName: json['fullName'] as String?,
    );
  }
}

class GlowBackendService {
  GlowBackendService(this._api, this._storage);

  final ApiService _api;
  final SecureStorageService _storage;

  Future<AuthSession> login({
    required String username,
    required String password,
    String role = 'CUSTOMER',
  }) async {
    return _authPost('/api/auth/login', {
      'username': username,
      'password': password,
      'role': role,
    });
  }

  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) async {
    return _authPost('/api/auth/register', {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
    });
  }

  Future<AuthSession> refresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException('Refresh token bulunamadi.');
    }
    return _authPost('/api/auth/refresh', {'refreshToken': refreshToken});
  }

  Future<void> logout() => _storage.clear();

  Future<AuthSession?> currentSession() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return AuthSession(
      token: token,
      refreshToken: await _storage.getRefreshToken(),
      role: await _storage.getRole(),
      customerId: await _storage.getCustomerId(),
      employeeId: await _storage.getEmployeeId(),
      fullName: await _storage.getFullName(),
    );
  }

  Future<List<Map<String, dynamic>>> getCustomers() {
    return _getList('/api/admin/customers');
  }

  Future<Map<String, dynamic>> getCustomer(int customerId) {
    return _getMap('/api/customers/$customerId');
  }

  Future<Map<String, dynamic>> updateCustomer(
    int customerId,
    Map<String, dynamic> payload,
  ) {
    return _putMap('/api/customers/$customerId', payload);
  }

  Future<List<Map<String, dynamic>>> getCustomerPackages(int customerId) {
    return _getList('/api/customers/$customerId/packages');
  }

  Future<Map<String, dynamic>> purchasePackage(int customerId, int packageId) {
    return _postMap('/api/customers/$customerId/packages/$packageId', null);
  }

  Future<List<Map<String, dynamic>>> getEmployees() {
    return _getList('/api/admin/employees');
  }

  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> payload) {
    return _postMap('/api/admin/employees', payload);
  }

  Future<Map<String, dynamic>> updateEmployee(
    String employeeId,
    Map<String, dynamic> payload,
  ) {
    return _putMap('/api/admin/employees/$employeeId', payload);
  }

  Future<Map<String, dynamic>> deactivateEmployee(String employeeId) {
    return _deleteMap('/api/admin/employees/$employeeId');
  }

  Future<Map<String, dynamic>> assignEmployeeService({
    required String employeeId,
    required int serviceId,
  }) {
    return _postMap('/api/admin/employees/services', {
      'employeeId': employeeId,
      'serviceId': serviceId,
    });
  }

  Future<List<Map<String, dynamic>>> getEmployeesByService(int serviceId) {
    return _getList('/api/admin/employees/services/$serviceId');
  }

  Future<Map<String, dynamic>> createEmployeeLeave(
    Map<String, dynamic> payload,
  ) {
    return _postMap('/api/admin/employees/leaves', payload);
  }

  Future<List<Map<String, dynamic>>> getEmployeeLeaves({
    required String employeeId,
    required String startDate,
    required String endDate,
  }) {
    return _getList(
      '/api/admin/employees/$employeeId/leaves',
      queryParameters: {'startDate': startDate, 'endDate': endDate},
    );
  }

  Future<List<Map<String, dynamic>>> getServices() {
    return _getList('/api/catalog/services');
  }

  Future<List<Map<String, dynamic>>> getServiceOptions(int serviceId) {
    return _getList('/api/catalog/services/$serviceId/options');
  }

  Future<List<Map<String, dynamic>>> getServicePackages(int serviceId) {
    return _getList('/api/catalog/services/$serviceId/packages');
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> payload) {
    return _postMap('/api/admin/services', payload);
  }

  Future<Map<String, dynamic>> updateService(
    int serviceId,
    Map<String, dynamic> payload,
  ) {
    return _putMap('/api/admin/services/$serviceId', payload);
  }

  Future<Map<String, dynamic>> deactivateService(int serviceId) {
    return _deleteMap('/api/admin/services/$serviceId');
  }

  Future<Map<String, dynamic>> createServiceOption(
    int serviceId,
    Map<String, dynamic> payload,
  ) {
    return _postMap('/api/admin/services/$serviceId/options', payload);
  }

  Future<Map<String, dynamic>> updateServiceOption(
    int optionId,
    Map<String, dynamic> payload,
  ) {
    return _putMap('/api/admin/options/$optionId', payload);
  }

  Future<Map<String, dynamic>> createPackage(
    int serviceId,
    Map<String, dynamic> payload,
  ) {
    return _postMap('/api/admin/services/$serviceId/packages', payload);
  }

  Future<Map<String, dynamic>> updatePackage(
    int packageId,
    Map<String, dynamic> payload,
  ) {
    return _putMap('/api/admin/packages/$packageId', payload);
  }

  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required int serviceId,
    required String date,
  }) {
    return _getList(
      '/api/appointments/available-slots',
      queryParameters: {'serviceId': serviceId, 'date': date},
    );
  }

  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> payload) {
    return _postMap('/api/appointments', payload);
  }

  Future<Map<String, dynamic>> getAppointment(int appointmentId) {
    return _getMap('/api/appointments/$appointmentId');
  }

  Future<List<Map<String, dynamic>>> getCustomerUpcomingAppointments(
    int customerId, {
    String? fromDate,
  }) {
    return _getList(
      '/api/appointments/customer/$customerId/upcoming',
      queryParameters: fromDate == null ? null : {'fromDate': fromDate},
    );
  }

  Future<List<Map<String, dynamic>>> getCustomerPastAppointments(
    int customerId, {
    String? beforeDate,
  }) {
    return _getList(
      '/api/appointments/customer/$customerId/past',
      queryParameters: beforeDate == null ? null : {'beforeDate': beforeDate},
    );
  }

  Future<List<Map<String, dynamic>>> getEmployeeAppointments({
    required String employeeId,
    required String startDate,
    required String endDate,
  }) {
    return _getList(
      '/api/appointments/employee/$employeeId',
      queryParameters: {'startDate': startDate, 'endDate': endDate},
    );
  }

  Future<Map<String, dynamic>> approveAppointment(int appointmentId) {
    return _patchMap('/api/appointments/$appointmentId/approve', null);
  }

  Future<Map<String, dynamic>> completeAppointment(int appointmentId) {
    return _patchMap('/api/appointments/$appointmentId/complete', null);
  }

  Future<Map<String, dynamic>> cancelAppointment(
    int appointmentId, {
    String? cancellationReason,
  }) {
    return _patchMap('/api/appointments/$appointmentId/cancel', {
      'cancellationReason': cancellationReason,
    });
  }

  Future<Map<String, dynamic>> updateAppointmentTime(
    int appointmentId,
    Map<String, dynamic> payload,
  ) {
    return _patchMap('/api/appointments/$appointmentId/time', payload);
  }

  Future<List<Map<String, dynamic>>> getNotifications(int customerId) {
    return _getList('/api/notifications/customer/$customerId');
  }

  Future<List<Map<String, dynamic>>> getUnreadNotifications(int customerId) {
    return _getList('/api/notifications/customer/$customerId/unread');
  }

  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) {
    return _patchMap('/api/notifications/$notificationId/read', null);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final session = await currentSession();
    if (session == null) {
      return null;
    }
    if (session.customerId != null) {
      return getCustomer(session.customerId!);
    }
    return {
      'employeeId': session.employeeId,
      'fullName': session.fullName,
      'role': session.role,
    };
  }

  Future<AuthSession> _authPost(
      String path, Map<String, dynamic> payload) async {
    final data = await _requestMap(() => _api.post<Map<String, dynamic>>(
          path,
          data: payload,
        ));
    final session = AuthSession.fromJson(data);
    if (session.token.isEmpty) {
      throw const ApiException('Backend token dondurmedi.');
    }
    await _storage.saveSession(
      accessToken: session.token,
      refreshToken: session.refreshToken,
      role: session.role,
      customerId: session.customerId,
      employeeId: session.employeeId,
      fullName: session.fullName,
    );
    return session;
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _requestList(() => _api.get<Map<String, dynamic>>(
          path,
          queryParameters: queryParameters,
        ));
  }

  Future<Map<String, dynamic>> _getMap(String path) {
    return _requestMap(() => _api.get<Map<String, dynamic>>(path));
  }

  Future<Map<String, dynamic>> _postMap(String path, dynamic data) {
    return _requestMap(() => _api.post<Map<String, dynamic>>(path, data: data));
  }

  Future<Map<String, dynamic>> _putMap(String path, dynamic data) {
    return _requestMap(() => _api.put<Map<String, dynamic>>(path, data: data));
  }

  Future<Map<String, dynamic>> _patchMap(String path, dynamic data) {
    return _requestMap(
        () => _api.patch<Map<String, dynamic>>(path, data: data));
  }

  Future<Map<String, dynamic>> _deleteMap(String path) {
    return _requestMap(() => _api.delete<Map<String, dynamic>>(path));
  }

  Future<List<Map<String, dynamic>>> _requestList(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      return unwrapApiList(response.data);
    } on DioException catch (error) {
      final apiError = error.error;
      throw apiError is ApiException ? apiError : ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> _requestMap(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      final response = await request();
      return unwrapApiMap(response.data);
    } on DioException catch (error) {
      final apiError = error.error;
      throw apiError is ApiException ? apiError : ApiException.fromDio(error);
    }
  }
}
