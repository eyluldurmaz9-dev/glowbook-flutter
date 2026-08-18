import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowbook_flutter/core/routes/app_router.dart';
import 'package:glowbook_flutter/core/api/api_exception.dart';
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

  testWidgets(
      'Web login\'e eklenen Ana Sayfa kontrolü mobil derlemede görünmez',
      (tester) async {
    // kIsWeb is false under the normal (non-web) test target this suite
    // runs on, so this locks in that the new web-only home button never
    // reaches the mobile build; its actual web-visible rendering is
    // exercised by `flutter build web --release`, not a widget test, since
    // kIsWeb can't be flipped at runtime in a VM test.
    await tester.pumpWidget(_testApp(const LoginPage()));

    expect(find.byKey(const Key('web_login_home')), findsNothing);
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

  testWidgets('Personel girişi personel rolünü backend isteğine gönderir',
      (tester) async {
    final backend = _FakeAuthBackend(
      loginError: const ApiException('Test isteği kaydedildi.'),
    );
    await tester.pumpWidget(_testAppWithBackend(
      const LoginPage(initialRole: 'EMPLOYEE'),
      backend,
    ));

    await tester.enterText(
        find.byType(TextFormField).at(0), 'employee@glowbook.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
    await tester.ensureVisible(find.text('Giriş Yap'));
    await tester.tap(find.text('Giriş Yap'));
    await tester.pump();

    expect(backend.lastRole, 'EMPLOYEE');
  });

  testWidgets('Yanlış rol mesajı kullanıcıya Türkçe gösterilir',
      (tester) async {
    final backend = _FakeAuthBackend(
      loginError: const ApiException('Bu hesap yönetici hesabı değil.'),
    );
    await tester.pumpWidget(_testAppWithBackend(
      const LoginPage(initialRole: 'ADMIN'),
      backend,
    ));

    await tester.enterText(
        find.byType(TextFormField).at(0), 'employee@glowbook.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
    await tester.ensureVisible(find.text('Giriş Yap'));
    await tester.tap(find.text('Giriş Yap'));
    await tester.pump();

    expect(find.text('Bu hesap yönetici hesabı değil.'), findsOneWidget);
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

Widget _testAppWithBackend(Widget child, _FakeAuthBackend backend) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(
        (ref) => _ReadyAuthController(backend),
      ),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

class _FakeAuthBackend implements AuthBackend {
  _FakeAuthBackend({this.initialSession, this.loginSession, this.loginError});

  final AuthSession? initialSession;
  final AuthSession? loginSession;
  final Object? loginError;
  String? lastRole;

  @override
  Future<AuthSession?> currentSession() async => initialSession;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
    String role = 'CUSTOMER',
  }) async {
    lastRole = role;
    if (loginError != null) throw loginError!;
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
