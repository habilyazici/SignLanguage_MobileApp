import '../entities/auth_state.dart';

abstract interface class AuthRepository {
  Future<AuthState> signIn({
    required String email,
    required String password,
  });

  Future<AuthState> register({
    required String name,
    required String email,
    required String password,
  });
}
