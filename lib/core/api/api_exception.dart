import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;
    String? rawMessage;

    if (data is Map<String, dynamic>) {
      final responseMessage = data['message'];
      if (responseMessage is String && responseMessage.isNotEmpty) {
        rawMessage = responseMessage;
      }
    }

    return ApiException(
      safeApiMessage(
        statusCode: response?.statusCode,
        rawMessage: rawMessage,
        dioType: error.type,
      ),
      statusCode: response?.statusCode,
    );
  }

  @override
  String toString() => message;
}

String safeApiMessage({
  required int? statusCode,
  required String? rawMessage,
  DioExceptionType? dioType,
}) {
  final lower = rawMessage?.toLowerCase() ?? '';
  if (dioType == DioExceptionType.connectionTimeout ||
      dioType == DioExceptionType.receiveTimeout ||
      dioType == DioExceptionType.sendTimeout) {
    return 'İstek zaman aşımına uğradı.';
  }
  if (dioType == DioExceptionType.connectionError) {
    return 'Backend sunucusuna ulaşılamadı.';
  }
  if (statusCode == 401 || lower.contains('unauthorized')) {
    return 'Oturum süren dolmuş olabilir. Lütfen tekrar giriş yap.';
  }
  if (statusCode == 403 ||
      lower.contains('forbidden') ||
      lower.contains('access denied')) {
    return 'Bu işlem için yetkin bulunmuyor.';
  }
  if (statusCode == 409 || lower.contains('conflict')) {
    return 'Bu kayıt başka bir veriyle çakışıyor. Bilgileri kontrol et.';
  }
  if (statusCode == 400 &&
      (lower.contains('invalid') ||
          lower.contains('required') ||
          lower.contains('notnull') ||
          lower.contains('notblank') ||
          lower.contains('positive') ||
          lower.contains(':'))) {
    return 'Form bilgilerini kontrol edip tekrar dene.';
  }
  final text = rawMessage?.trim();
  if (text != null && text.isNotEmpty) {
    return text;
  }
  return 'Sunucuya bağlanırken bir sorun oluştu.';
}
