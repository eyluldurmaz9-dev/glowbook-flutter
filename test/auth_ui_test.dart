import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowbook_flutter/core/routes/app_router.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/theme/app_theme.dart';
import 'package:glowbook_flutter/features/auth/login_page.dart';
import 'package:glowbook_flutter/features/auth/register_page.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

void main() {
  testWidgets('Login form validation mesajlarını gösterir', (tester) async {
    await tester.pumpWidget(_testApp(const LoginPage()));

    await tester.ensureVisible(find.text('Giriş Yap'));
    await tester.tap(find.text('Giriş Yap'));
    await tester.pump();

    expect(find.text('E-posta veya telefon zorunludur.'), findsOneWidget);
    expect(find.text('Şifre zorunludur.'), findsOneWidget);
  });

  testWidgets('Register form validation mesajlarını gösterir', (tester) async {
    await tester.pumpWidget(_testApp(const RegisterPage()));

    await tester.ensureVisible(find.text('Üye Ol'));
    await tester.tap(find.text('Üye Ol'));
    await tester.pump();

    expect(find.text('Ad zorunludur.'), findsOneWidget);
    expect(find.text('Soyad zorunludur.'), findsOneWidget);
    expect(find.text('Telefon zorunludur.'), findsOneWidget);
    expect(find.text('Şifre zorunludur.'), findsOneWidget);
  });

  testWidgets('Rol bazlı yönlendirme admin kullanıcısını admin alanına götürür',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController(
              _FakeAuthBackend(
                initialSession:
                    const AuthSession(token: 'token', role: 'ADMIN'),
              ),
            )..loadSession(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: appRouter,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    expect(find.text('Genel Bakış'), findsOneWidget);
  });
}

Widget _testApp(Widget child) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => _ReadyAuthController(
          _FakeAuthBackend(
            loginSession: const AuthSession(token: 'token', role: 'CUSTOMER'),
          ),
        ),
      ),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

class _FakeAuthBackend implements AuthBackend {
  _FakeAuthBackend({this.initialSession, this.loginSession});

  final AuthSession? initialSession;
  final AuthSession? loginSession;

  @override
  Future<AuthSession?> currentSession() async => initialSession;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
    String role = 'CUSTOMER',
  }) async {
    return loginSession ?? AuthSession(token: 'token', role: role);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) async {
    return const AuthSession(token: 'token', role: 'CUSTOMER');
  }
}

class _ReadyAuthController extends AuthController {
  _ReadyAuthController(super.backend) {
    state = const AsyncValue.data(null);
  }
}
