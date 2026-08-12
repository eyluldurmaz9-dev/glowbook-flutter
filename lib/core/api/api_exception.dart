import 'package:dio/dio.dart';

enum ApiFailureType {
  noInternet,
  dns,
  connectionRefused,
  connectTimeout,
  receiveTimeout,
  tls,
  cors,
  http,
  invalidJson,
  dtoParsing,
  missingConfiguration,
  unknown,
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.type = ApiFailureType.unknown,
  });

  final String message;
  final int? statusCode;
  final ApiFailureType type;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;
    final rawMessage = data is Map ? data['message']?.toString() : null;
    final detail = '${error.error ?? ''} ${error.message ?? ''}'.toLowerCase();
    final classification = _classify(error, detail);
    return ApiException(
      safeApiMessage(
        statusCode: response?.statusCode,
        rawMessage: rawMessage,
        dioType: error.type,
        failureType: classification,
      ),
      statusCode: response?.statusCode,
      type: classification,
    );
  }

  @override
  String toString() => message;
}

ApiFailureType _classify(DioException error, String detail) {
  if (error.response != null) return ApiFailureType.http;
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return ApiFailureType.connectTimeout;
  }
  if (error.type == DioExceptionType.receiveTimeout) {
    return ApiFailureType.receiveTimeout;
  }
  if (error.type == DioExceptionType.badCertificate ||
      detail.contains('certificate') ||
      detail.contains('handshake') ||
      detail.contains('tls')) {
    return ApiFailureType.tls;
  }
  if (detail.contains('failed host lookup') ||
      detail.contains('name or service not known') ||
      detail.contains('nodename nor servname')) {
    return ApiFailureType.dns;
  }
  if (detail.contains('connection refused')) {
    return ApiFailureType.connectionRefused;
  }
  if (detail.contains('network is unreachable') ||
      detail.contains('network unreachable') ||
      detail.contains('internet connection')) {
    return ApiFailureType.noInternet;
  }
  // Browsers intentionally hide CORS failures and expose only a generic
  // XMLHttpRequest/network error with no HTTP response.
  if (detail.contains('xmlhttprequest') || detail.contains('cors')) {
    return ApiFailureType.cors;
  }
  return ApiFailureType.unknown;
}

String safeApiMessage({
  required int? statusCode,
  required String? rawMessage,
  DioExceptionType? dioType,
  ApiFailureType? failureType,
}) {
  switch (failureType) {
    case ApiFailureType.noInternet:
      return 'İnternet bağlantısı yok. Ağ bağlantını kontrol et.';
    case ApiFailureType.dns:
      return 'Sunucu adresi çözümlenemedi. Lütfen daha sonra tekrar dene.';
    case ApiFailureType.connectionRefused:
      return 'Sunucu bağlantıyı reddetti. Lütfen daha sonra tekrar dene.';
    case ApiFailureType.connectTimeout:
      return 'Sunucuya bağlanma zaman aşımına uğradı.';
    case ApiFailureType.receiveTimeout:
      return 'Sunucudan yanıt alınması zaman aşımına uğradı.';
    case ApiFailureType.tls:
      return 'Güvenli bağlantı kurulamadı. Cihaz tarihini ve ağı kontrol et.';
    case ApiFailureType.cors:
      return 'Tarayıcı güvenlik politikası isteği engelledi.';
    default:
      break;
  }
  if (dioType == DioExceptionType.connectionTimeout ||
      dioType == DioExceptionType.sendTimeout) {
    return 'Sunucuya bağlanma zaman aşımına uğradı.';
  }
  if (dioType == DioExceptionType.receiveTimeout) {
    return 'Sunucudan yanıt alınması zaman aşımına uğradı.';
  }

  final lower = rawMessage?.toLowerCase() ?? '';
  switch (statusCode) {
    case 400:
      if (lower == 'bu hesap personel hesabı değil.' ||
          lower == 'bu hesap yönetici hesabı değil.') {
        return rawMessage!.trim();
      }
      return 'Gönderilen bilgileri kontrol edip tekrar dene.';
    case 401:
      return 'Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap.';
    case 403:
      return 'Bu işlem için yetkin bulunmuyor.';
    case 404:
      return 'İstenen kayıt bulunamadı.';
    case 409:
      return lower.contains('appointment') || lower.contains('slot')
          ? 'Seçilen saat artık uygun değil. Başka bir saat seç.'
          : 'Bu kayıt zaten mevcut veya başka bir kayıtla çakışıyor.';
    case 422:
      return 'Bilgiler işlenemedi. Form alanlarını kontrol et.';
    case 500:
      return 'Sunucuda beklenmeyen bir sorun oluştu. Lütfen daha sonra tekrar dene.';
  }
  if (statusCode != null) {
    return 'Sunucu isteği tamamlayamadı (HTTP $statusCode).';
  }
  final text = rawMessage?.trim();
  if (text != null && text.isNotEmpty) return text;
  return 'Sunucuyla iletişim kurulurken beklenmeyen bir sorun oluştu.';
}
