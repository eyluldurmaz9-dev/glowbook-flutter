import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowbook_flutter/core/api/api_exception.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

void main() {
  test('AuthController başarılı login sonrası oturumu saklar', () async {
    final backend = _FakeAuthBackend(
      loginSession: const AuthSession(
        token: 'access',
        refreshToken: 'refresh',
        role: 'CUSTOMER',
        customerId: 1,
      ),
    );
    final controller = AuthController(backend);

    await controller.login(username: 'demo', password: 'secret123');

    expect(controller.state.asData?.value?.role, 'CUSTOMER');
    expect(backend.lastRole, 'CUSTOMER');
  });

  test('AuthController API hatasını AsyncError olarak döndürür', () async {
    final backend = _FakeAuthBackend(
      loginError: const ApiException('Giriş başarısız.'),
    );
    final controller = AuthController(backend);

    await controller.login(username: 'demo', password: 'wrong');

    expect(controller.state, isA<AsyncError<AuthSession?>>());
  });

  test('AuthController logout oturumu temizler', () async {
    final backend = _FakeAuthBackend(
      current: const AuthSession(token: 'access', role: 'ADMIN'),
    );
    final controller = AuthController(backend);

    await controller.logout();

    expect(controller.state.asData?.value, isNull);
    expect(backend.loggedOut, isTrue);
  });
}

class _FakeAuthBackend implements AuthBackend {
  _FakeAuthBackend({this.current, this.loginSession, this.loginError});

  final AuthSession? current;
  final AuthSession? loginSession;
  final Object? loginError;
  String? lastRole;
  bool loggedOut = false;

  @override
  Future<AuthSession?> currentSession() async => current;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
    String role = 'CUSTOMER',
  }) async {
    lastRole = role;
    final error = loginError;
    if (error != null) throw error;
    return loginSession ?? AuthSession(token: 'access', role: role);
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
  }

  @override
  Future<AuthSession> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) async {
    return const AuthSession(token: 'access', role: 'CUSTOMER', customerId: 1);
  }
}
