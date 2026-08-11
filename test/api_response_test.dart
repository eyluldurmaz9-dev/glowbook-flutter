import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_exception.dart';
import 'package:glowbook_flutter/core/api/api_response.dart';

void main() {
  test('unwrapApiMap success data döndürür', () {
    final data = unwrapApiMap({
      'success': true,
      'data': {'token': 'access'},
    });

    expect(data['token'], 'access');
  });

  test('unwrapApiMap güvenli Türkçe hata döndürür', () {
    expect(
      () => unwrapApiMap({'success': false}),
      throwsA(isA<ApiException>()),
    );
  });

  test('safeApiMessage yetki ve validation hatalarını kullanıcı dostu eşler',
      () {
    expect(
      safeApiMessage(statusCode: 403, rawMessage: 'Access denied'),
      'Bu işlem için yetkin bulunmuyor.',
    );
    expect(
      safeApiMessage(statusCode: 409, rawMessage: 'conflict'),
      'Bu kayıt zaten mevcut veya başka bir kayıtla çakışıyor.',
    );
    expect(
      safeApiMessage(
          statusCode: 400, rawMessage: 'firstName: must not be blank'),
      'Gönderilen bilgileri kontrol edip tekrar dene.',
    );
  });
}
