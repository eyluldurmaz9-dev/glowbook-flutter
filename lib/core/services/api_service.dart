import 'package:dio/dio.dart';
import '../api/api_client.dart';

class ApiService {
  ApiService(this._client);

  final GlowApiClient _client;

  Dio get dio => _client.dio;

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    return dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) async {
    return dio.put<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) async {
    return dio.patch<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) async {
    return dio.delete<T>(path, data: data);
  }
}
