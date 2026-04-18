import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth durum modeli
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStatus { guest, loading, authenticated }

class AuthState {
  final AuthStatus status;
  final String? displayName;
  final String? email;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.guest,
    this.displayName,
    this.email,
    this.errorMessage,
  });

  bool get isGuest         => status == AuthStatus.guest;
  bool get isLoading       => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Profilde gösterilecek baş harfler (ör. "AY" veya "HM")
  String get initials {
    if (displayName == null || displayName!.trim().isEmpty) return '?';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  AuthState copyWith({
    AuthStatus?  status,
    String?      displayName,
    String?      email,
    String?      errorMessage,
  }) =>
      AuthState(
        status:       status       ?? this.status,
        displayName:  displayName  ?? this.displayName,
        email:        email        ?? this.email,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.keepAlive();
    return const AuthState(); // varsayılan: misafir
  }

  // ── Giriş (stub — backend hazır olunca doldurulacak) ──────────────────────

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 800)); // API simülasyonu

    // TODO: gerçek API çağrısı buraya
    // Şimdilik basit doğrulama — herhangi e-posta/şifre kabul edilir
    if (email.contains('@') && password.length >= 6) {
      final name = email.split('@').first;
      state = state.copyWith(
        status:      AuthStatus.authenticated,
        email:       email,
        displayName: _capitalize(name),
      );
      return true;
    }

    state = state.copyWith(
      status:       AuthStatus.guest,
      errorMessage: 'E-posta veya şifre hatalı.',
    );
    return false;
  }

  // ── Kayıt (stub) ──────────────────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: gerçek API çağrısı buraya
    if (email.contains('@') && password.length >= 6) {
      state = state.copyWith(
        status:      AuthStatus.authenticated,
        email:       email,
        displayName: name.trim(),
      );
      return true;
    }

    state = state.copyWith(
      status:       AuthStatus.guest,
      errorMessage: 'Kayıt başarısız. Bilgileri kontrol edin.',
    );
    return false;
  }

  // ── Çıkış ─────────────────────────────────────────────────────────────────

  void signOut() {
    state = const AuthState();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
