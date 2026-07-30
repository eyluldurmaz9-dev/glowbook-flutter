import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'api_response.dart';
import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';

class GlowApiClient {
  GlowApiClient({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshRequest =
              error.requestOptions.path.contains('/api/auth/refresh');

          if (isUnauthorized && !isRefreshRequest) {
            final refreshed = await refreshToken();
            final token = await _secureStorage.getAccessToken();
            if (refreshed && token != null && token.isNotEmpty) {
              final request = error.requestOptions;
              request.headers['Authorization'] = 'Bearer $token';
              try {
                final retryResponse = await _dio.fetch<dynamic>(request);
                handler.resolve(retryResponse);
                return;
              } on DioException catch (retryError) {
                handler.reject(retryError);
                return;
              }
            }
          }

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: ApiException.fromDio(error),
            ),
          );
        },
      ),
    );
  }

  final SecureStorageService _secureStorage;
  late final Dio _dio;
  bool _isRefreshing = false;

  Dio get dio => _dio;

  Future<void> logout() => _secureStorage.clear();

  Future<bool> refreshToken() async {
    if (_isRefreshing) {
      return false;
    }

    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    _isRefreshing = true;
    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          sendTimeout: ApiConfig.sendTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = unwrapApiMap(response.data);
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        return false;
      }
      await _secureStorage.saveSession(
        accessToken: token,
        refreshToken: data['refreshToken'] as String? ?? refreshToken,
        role: data['role'] as String?,
        customerId: data['customerId'] as int?,
        employeeId: data['employeeId'] as String?,
        fullName: data['fullName'] as String?,
      );
      return true;
    } on DioException {
      await _secureStorage.clear();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}
