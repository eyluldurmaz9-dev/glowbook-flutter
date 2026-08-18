import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/api/api_exception.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/core/widgets/glow_widgets.dart';
import 'package:glowbook_flutter/features/auth/forgot_password_page.dart';
import 'package:glowbook_flutter/features/auth/reset_password_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

/// Covers the now-active password reset screens: request-by-email shows the
/// backend's generic message and never leaks whether the email exists (that
/// invariant is enforced backend-side; here we cover that the UI just
/// displays whatever it's told), and the reset-by-token form validates,
/// submits, and distinguishes a missing token from a rejected one.
void main() {
  group('ForgotPasswordPage', () {
    testWidgets('Geçerli e-posta ile gönderim genel mesajı gösterir',
        (tester) async {
      final backend = _FakeBackend();
      await tester.pumpWidget(_wrap(backend: backend, child: const ForgotPasswordPage()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-posta'),
        'customer@glowbook.test',
      );
      await tester.tap(find.widgetWithText(GlowButton, 'Gönder'));
      await tester.pumpAndSettle();

      expect(backend.forgotPasswordCalls, ['customer@glowbook.test']);
      expect(
        find.text(
            'Eğer bu e-posta adresi sistemde kayıtlıysa şifre sıfırlama bağlantısı gönderildi.'),
        findsOneWidget,
      );
    });

    testWidgets('Boş e-posta backend çağrısı yapmadan doğrulama hatası gösterir',
        (tester) async {
      final backend = _FakeBackend();
      await tester.pumpWidget(_wrap(backend: backend, child: const ForgotPasswordPage()));

      await tester.tap(find.widgetWithText(GlowButton, 'Gönder'));
      await tester.pumpAndSettle();

      expect(find.text('E-posta zorunludur.'), findsOneWidget);
      expect(backend.forgotPasswordCalls, isEmpty);
    });
  });

  group('ResetPasswordPage', () {
    testWidgets('Token eksikse form gösterilmez, geçersiz bağlantı ekranı çıkar',
        (tester) async {
      final backend = _FakeBackend();
      await tester.pumpWidget(
          _wrap(backend: backend, child: const ResetPasswordPage(token: null)));

      expect(find.text('Bu bağlantı eksik veya geçersiz.'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Yeni Şifre'), findsNothing);
    });

    testWidgets('Şifreler eşleşmezse backend çağrılmadan hata gösterir',
        (tester) async {
      final backend = _FakeBackend();
      await tester.pumpWidget(_wrap(
        backend: backend,
        child: const ResetPasswordPage(token: 'valid-token'),
      ));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Yeni Şifre'),
        'password-one',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Yeni Şifre (Tekrar)'),
        'password-two',
      );
      await tester.tap(find.widgetWithText(GlowButton, 'Şifreyi Güncelle'));
      await tester.pumpAndSettle();

      expect(find.text('Şifreler eşleşmiyor.'), findsOneWidget);
      expect(backend.resetPasswordCalls, isEmpty);
    });

    testWidgets('Geçerli token ve eşleşen şifrelerle güncelleme başarılı olur',
        (tester) async {
      final backend = _FakeBackend();
      await tester.pumpWidget(_wrap(
        backend: backend,
        child: const ResetPasswordPage(token: 'valid-token'),
      ));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Yeni Şifre'),
        'brand-new-password',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Yeni Şifre (Tekrar)'),
        'brand-new-password',
      );
      await tester.tap(find.widgetWithText(GlowButton, 'Şifreyi Güncelle'));
      await tester.pumpAndSettle();

      expect(backend.resetPasswordCalls, hasLength(1));
      expect(backend.resetPasswordCalls.first.token, 'valid-token');
      expect(
          backend.resetPasswordCalls.first.newPassword, 'brand-new-password');
      expect(find.text('Şifren güncellendi.'), findsOneWidget);
    });

    testWidgets('Reddedilen token hata gösterir ve formda kalır', (tester) async {
      final backend = _FakeBackend(
        resetPasswordError:
            const ApiException('Geçersiz veya süresi dolmuş bağlantı.'),
      );
      await tester.pumpWidget(_wrap(
        backend: backend,
        child: const ResetPasswordPage(token: 'expired-token'),
      ));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Yeni Şifre'),
        'brand-new-password',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Yeni Şifre (Tekrar)'),
        'brand-new-password',
      );
      await tester.tap(find.widgetWithText(GlowButton, 'Şifreyi Güncelle'));
      await tester.pumpAndSettle();

      expect(find.text('Geçersiz veya süresi dolmuş bağlantı.'), findsOneWidget);
      expect(find.text('Şifren güncellendi.'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Yeni Şifre'), findsOneWidget);
    });
  });
}

Widget _wrap({required _FakeBackend backend, required Widget child}) {
  return ProviderScope(
    overrides: [glowBackendServiceProvider.overrideWithValue(backend)],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

class _FakeBackend extends GlowBackendService {
  _FakeBackend({this.resetPasswordError})
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  final Object? resetPasswordError;
  final List<String> forgotPasswordCalls = [];
  final List<_ResetCall> resetPasswordCalls = [];

  @override
  Future<String> forgotPassword(String email) async {
    forgotPasswordCalls.add(email);
    return 'Eğer bu e-posta adresi sistemde kayıtlıysa şifre sıfırlama bağlantısı gönderildi.';
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    resetPasswordCalls.add(_ResetCall(token, newPassword));
    if (resetPasswordError != null) throw resetPasswordError!;
    return 'Şifreniz güncellendi.';
  }
}

class _ResetCall {
  const _ResetCall(this.token, this.newPassword);

  final String token;
  final String newPassword;
}
