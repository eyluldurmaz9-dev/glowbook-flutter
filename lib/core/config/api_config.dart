import '../constants/app_constants.dart';

class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const Duration connectTimeout = AppConstants.connectTimeout;
  static const Duration receiveTimeout = AppConstants.receiveTimeout;
  static const Duration sendTimeout = AppConstants.sendTimeout;
}
