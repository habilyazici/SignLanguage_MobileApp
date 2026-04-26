import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_state.dart';

export '../../domain/entities/auth_state.dart' show AuthStatus, AuthState;

final _authRepositoryProvider = Provider<AuthRepositoryImpl>(
  (ref) => AuthRepositoryImpl(),
);

// ─────────────────────────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.keepAlive();
    _restoreSession();
    return const AuthState(status: AuthStatus.loading);
  }

  Future<void> _restoreSession() async {
    final repo = ref.read(_authRepositoryProvider);
    final restored = await repo.restoreSession();
    state = restored;
  }

  Future<bool> signIn({required String email, required String password}) async {
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

  Future<void> signOut() async {
    await ref.read(_authRepositoryProvider).clearSession();
    state = const AuthState();
  }

  Future<String?> deleteAccount() async {
    final result = await ref.read(_authRepositoryProvider).deleteAccount();
    if (result.success) {
      state = const AuthState();
    }
    return result.error;
  }

  Future<String?> updateProfile({
    String? name,
    String? currentPassword,
    String? newPassword,
  }) async {
    final result = await ref.read(_authRepositoryProvider).updateProfile(
      name: name,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (result.success && result.newName != null) {
      state = state.copyWith(displayName: result.newName);
    }
    return result.error;
  }
}
