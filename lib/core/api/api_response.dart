import 'api_exception.dart';

T unwrapApiData<T>(dynamic responseData) {
  if (responseData is Map<String, dynamic> &&
      responseData.containsKey('success')) {
    if (responseData['success'] == false) {
      throw ApiException(
        responseData['message']?.toString() ?? 'İşlem başarısız oldu.',
      );
    }
    if (!responseData.containsKey('data')) {
      return responseData as T;
    }
    return responseData['data'] as T;
  }
  if (responseData == null || responseData is String) {
    throw const ApiException(
      'Sunucudan geçersiz JSON yanıtı alındı.',
      type: ApiFailureType.invalidJson,
    );
  }
  return responseData as T;
}

List<Map<String, dynamic>> unwrapApiList(dynamic responseData) {
  final data = unwrapApiData<dynamic>(responseData);
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  }
  throw const ApiException(
    'Sunucu liste yanıtı uygulamayla uyumlu değil.',
    type: ApiFailureType.dtoParsing,
  );
}

Map<String, dynamic> unwrapApiMap(dynamic responseData) {
  final data = unwrapApiData<dynamic>(responseData);
  if (data is Map<String, dynamic>) {
    return data;
  }
  throw const ApiException(
    'Sunucu yanıtı uygulamayla uyumlu değil.',
    type: ApiFailureType.dtoParsing,
  );
}
