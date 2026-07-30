import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'services/token_storage.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'state/auth_state.dart';
import 'routes/app_router.dart';
import '../core/config/api_config.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final ts = ref.read(tokenStorageProvider);
  final client = ApiClient(ApiConfig.baseUrl, ts);
  client.init();
  return client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.read(apiClientProvider);
  return AuthService(api);
});

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  final tokenStorage = ref.read(tokenStorageProvider);
  return AuthStateNotifier(authService, tokenStorage);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final authNotifier = ref.read(authStateProvider.notifier);
  return createAppRouter(authState, authNotifier.refreshNotifier);
});
