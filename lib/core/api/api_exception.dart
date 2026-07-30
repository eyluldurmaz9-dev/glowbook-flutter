import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;
    var message = 'Sunucuya baglanirken bir sorun olustu.';

    if (data is Map<String, dynamic>) {
      final responseMessage = data['message'];
      if (responseMessage is String && responseMessage.isNotEmpty) {
        message = responseMessage;
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      message = 'Istek zaman asimina ugradi.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Backend sunucusuna ulasilamadi.';
    }

    return ApiException(message, statusCode: response?.statusCode);
  }

  @override
  String toString() => message;
}
