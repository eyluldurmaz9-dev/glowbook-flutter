import '../constants/app_constants.dart';

class ApiConfig {
  ApiConfig._();

  static const bool _isWeb = bool.fromEnvironment('dart.library.html') ||
      bool.fromEnvironment('dart.library.js_interop');
  static const String _productionBaseUrl =
      'https://glowbook-production-7b59.up.railway.app';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8080';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String baseUrl = _configuredBaseUrl != ''
      ? _configuredBaseUrl
      : (_isWeb ? _productionBaseUrl : _androidEmulatorBaseUrl);

  static const Duration connectTimeout = AppConstants.connectTimeout;
  static const Duration receiveTimeout = AppConstants.receiveTimeout;
  static const Duration sendTimeout = AppConstants.sendTimeout;
}
