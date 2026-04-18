import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

/// Stub implementasyon — backend hazır olduğunda API çağrılarıyla değiştirilecek.
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<AuthState> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.contains('@') && password.length >= 6) {
      final name = email.split('@').first;
      return AuthState(
        status: AuthStatus.authenticated,
        email: email,
        displayName: _capitalize(name),
      );
    }

    return const AuthState(
      status: AuthStatus.guest,
      errorMessage: 'E-posta veya şifre hatalı.',
    );
  }

  @override
  Future<AuthState> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.contains('@') && password.length >= 6) {
      return AuthState(
        status: AuthStatus.authenticated,
        email: email,
        displayName: name.trim(),
      );
    }

    return const AuthState(
      status: AuthStatus.guest,
      errorMessage: 'Kayıt başarısız. Bilgileri kontrol edin.',
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
