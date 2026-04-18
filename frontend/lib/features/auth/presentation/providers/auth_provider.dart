import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

// Mevcut import'lar auth_provider.dart üzerinden geldiğinden uyumluluk için yeniden dışa aktar.
export '../../domain/entities/auth_state.dart' show AuthStatus, AuthState;

// ─────────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────────

final _authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Auth provider
// ─────────────────────────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.keepAlive();
    return const AuthState();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final result = await ref
        .read(_authRepositoryProvider)
        .signIn(email: email, password: password);
    state = result;
    return result.isAuthenticated;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final result = await ref
        .read(_authRepositoryProvider)
        .register(name: name, email: email, password: password);
    state = result;
    return result.isAuthenticated;
  }

  void signOut() => state = const AuthState();
}
