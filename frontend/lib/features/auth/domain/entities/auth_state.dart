import '../../../../core/utils/sentinel.dart';

enum AuthStatus { guest, loading, authenticated }

class AuthState {
  final AuthStatus status;
  final String? displayName;
  final String? email;
  final String? token;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.guest,
    this.displayName,
    this.email,
    this.token,
    this.errorMessage,
  });

  bool get isGuest => status == AuthStatus.guest;
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  String get initials {
    if (displayName == null || displayName!.trim().isEmpty) return '?';
    final parts = displayName!.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return displayName![0].toUpperCase();
  }

  /// [errorMessage] açıkça `null` geçilirse hata temizlenir; geçilmezse korunur.
  AuthState copyWith({
    AuthStatus? status,
    String? displayName,
    String? email,
    String? token,
    Object? errorMessage = sentinel,
  }) => AuthState(
    status: status ?? this.status,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    token: token ?? this.token,
    errorMessage: errorMessage == sentinel ? this.errorMessage : errorMessage as String?,
  );
}
