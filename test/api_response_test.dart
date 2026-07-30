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
}
