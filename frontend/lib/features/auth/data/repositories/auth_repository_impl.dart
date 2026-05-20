import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

bool _isJwtExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    switch (payload.length % 4) {
      case 2:
        payload += '==';
      case 3:
        payload += '=';
    }
    final decoded = jsonDecode(utf8.decode(base64Decode(payload))) as Map<String, dynamic>;
    final exp = decoded['exp'];
    // exp yoksa veya geçersiz tipte → güvenli tarafta kal, expire say
    if (exp == null || exp is! int) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiry);
  } catch (_) {
    return true;
  }
}

/// Backend yanıtından string field güvenle okur
String? _safeString(Map<String, dynamic> map, String key) {
  final v = map[key];
  if (v == null) return null;
  return v.toString();
}

/// Hata tipine göre kullanıcı dostu mesaj üretir
String _errorMessage(Object e) {
  final s = e.toString();
  if (s.contains('TimeoutException') || s.contains('timeout')) {
    return 'Sunucu yanıt vermedi. İnternet bağlantınızı kontrol edin.';
  }
  if (s.contains('SocketException') || s.contains('NetworkException')) {
    return 'İnternet bağlantısı yok.';
  }
  return 'Sunucuya bağlanılamadı.';
}

const _kTokenKey  = 'auth_token';
const _kNameKey   = 'auth_name';
const _kEmailKey  = 'auth_email';
const _kAvatarKey = 'auth_avatar';

const _kAllKeys = [_kTokenKey, _kNameKey, _kEmailKey, _kAvatarKey];

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class AuthRepositoryImpl implements AuthRepository {
  static const _authHeaders = {
    ...kNgrokHeaders,
    'Content-Type': 'application/json',
  };

  @override
  Future<AuthState> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kApiBaseUrl/api/auth/login'),
            headers: _authHeaders,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(kAuthTimeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final token = _safeString(body, 'token') ?? '';
        final user = body['user'] is Map<String, dynamic>
            ? body['user'] as Map<String, dynamic>
            : <String, dynamic>{};
        final name = _safeString(user, 'name') ?? '';
        final email = _safeString(user, 'email') ?? '';
        if (token.isEmpty || email.isEmpty) {
          return const AuthState(
            status: AuthStatus.guest,
            errorMessage: 'Sunucu geçersiz yanıt döndürdü.',
          );
        }
        final avatarUrl = _safeString(user, 'avatarUrl');
        await _saveSession(token: token, name: name, email: email, avatarUrl: avatarUrl);
        return AuthState(
          status: AuthStatus.authenticated,
          token: token,
          displayName: name,
          email: email,
          avatarUrl: avatarUrl,
        );
      }

      if (res.statusCode == 401) {
        return AuthState(
          status: AuthStatus.guest,
          errorMessage: body['error'] as String? ?? 'E-posta veya şifre hatalı.',
        );
      }

      return AuthState(
        status: AuthStatus.guest,
        errorMessage: _safeString(body, 'error') ?? 'Giriş başarısız.',
      );
    } catch (e) {
      return AuthState(
        status: AuthStatus.guest,
        errorMessage: _errorMessage(e),
      );
    }
  }

  @override
  Future<AuthState> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kApiBaseUrl/api/auth/register'),
            headers: _authHeaders,
            body: jsonEncode({'name': name, 'email': email, 'password': password}),
          )
          .timeout(kAuthTimeout);

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201) {
        final token = _safeString(body, 'token') ?? '';
        final user = body['user'] is Map<String, dynamic>
            ? body['user'] as Map<String, dynamic>
            : <String, dynamic>{};
        final name = _safeString(user, 'name') ?? '';
        final email = _safeString(user, 'email') ?? '';
        if (token.isEmpty || email.isEmpty) {
          return const AuthState(
            status: AuthStatus.guest,
            errorMessage: 'Sunucu geçersiz yanıt döndürdü.',
          );
        }
        final avatarUrl = _safeString(user, 'avatarUrl');
        await _saveSession(token: token, name: name, email: email, avatarUrl: avatarUrl);
        return AuthState(
          status: AuthStatus.authenticated,
          token: token,
          displayName: name,
          email: email,
          avatarUrl: avatarUrl,
        );
      }

      if (res.statusCode == 409) {
        return AuthState(
          status: AuthStatus.guest,
          errorMessage: _safeString(body, 'error') ?? 'Bu e-posta zaten kayıtlı.',
        );
      }

      return AuthState(
        status: AuthStatus.guest,
        errorMessage: _safeString(body, 'error') ?? 'Kayıt başarısız.',
      );
    } catch (e) {
      return AuthState(
        status: AuthStatus.guest,
        errorMessage: _errorMessage(e),
      );
    }
  }

  @override
  Future<({bool success, String? error, String? newName})> updateProfile({
    String? name,
    String? currentPassword,
    String? newPassword,
  }) async {
    final token = await _storage.read(key: _kTokenKey);
    if (token == null) return (success: false, error: 'Oturum bulunamadı.', newName: null);

    try {
      final body = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
      if (currentPassword != null) body['currentPassword'] = currentPassword;
      if (newPassword != null) body['newPassword'] = newPassword;

      final res = await http
          .put(
            Uri.parse('$kApiBaseUrl/api/auth/profile'),
            headers: {
              ..._authHeaders,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(kAuthTimeout);

      if (res.statusCode == 401) {
        await clearSession();
        return (success: false, error: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.', newName: null);
      }
      final parsed = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final updatedName = parsed['name'] as String?;
        if (updatedName != null) {
          await _storage.write(key: _kNameKey, value: updatedName);
        }
        return (success: true, error: null, newName: updatedName);
      }
      return (success: false, error: _safeString(parsed, 'error') ?? 'Güncelleme başarısız.', newName: null);
    } catch (e) {
      return (success: false, error: _errorMessage(e), newName: null);
    }
  }

  @override
  Future<AuthState> restoreSession() async {
    final token = await _storage.read(key: _kTokenKey);
    final name = await _storage.read(key: _kNameKey);
    final email = await _storage.read(key: _kEmailKey);
    final avatarUrl = await _storage.read(key: _kAvatarKey);
    if (token == null || email == null) return const AuthState();
    if (_isJwtExpired(token)) {
      await clearSession();
      return const AuthState();
    }
    return AuthState(
      status: AuthStatus.authenticated,
      token: token,
      displayName: name,
      email: email,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await http
          .post(
            Uri.parse('$kApiBaseUrl/api/auth/forgot-password'),
            headers: _authHeaders,
            body: jsonEncode({'email': email}),
          )
          .timeout(kAuthTimeout);
    } catch (_) {
      // Güvenlik gereği hata olsa bile sessiz devam et
    }
  }

  @override
  Future<({bool success, String? error})> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kApiBaseUrl/api/auth/reset-password'),
            headers: _authHeaders,
            body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
          )
          .timeout(kAuthTimeout);

      if (res.statusCode == 200) return (success: true, error: null);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (success: false, error: body['error'] as String? ?? 'Şifre sıfırlanamadı.');
    } catch (_) {
      return (success: false, error: 'Sunucuya bağlanılamadı.');
    }
  }

  @override
  Future<({bool success, String? error})> deleteAccount() async {
    final token = await _storage.read(key: _kTokenKey);
    if (token == null) return (success: false, error: 'Oturum bulunamadı.');

    try {
      final res = await http
          .delete(
            Uri.parse('$kApiBaseUrl/api/auth/profile'),
            headers: {
              ..._authHeaders,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(kAuthTimeout);

      if (res.statusCode == 204) {
        await clearSession();
        return (success: true, error: null);
      }
      if (res.statusCode == 401) {
        await clearSession();
        return (success: false, error: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (success: false, error: _safeString(body, 'error') ?? 'Hesap silinemedi.');
    } catch (e) {
      return (success: false, error: _errorMessage(e));
    }
  }

  @override
  Future<void> clearSession() async {
    for (final key in _kAllKeys) {
      await _storage.delete(key: key);
    }
  }

  @override
  Future<({bool success, String? error, String? avatarUrl})> uploadAvatar(
    Uint8List bytes,
  ) async {
    final token = await _storage.read(key: _kTokenKey);
    if (token == null) {
      return (success: false, error: 'Oturum bulunamadı.', avatarUrl: null);
    }

    try {
      final uri = Uri.parse('$kApiBaseUrl/api/auth/avatar');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          ...kNgrokHeaders,
          'Authorization': 'Bearer $token',
        })
        ..files.add(
          http.MultipartFile.fromBytes('avatar', bytes, filename: 'avatar.jpg'),
        );

      final streamed = await request.send().timeout(kAuthTimeout);
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 401) {
        await clearSession();
        return (
          success: false,
          error: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
          avatarUrl: null,
        );
      }

      if (res.statusCode == 200) {
        final parsed = jsonDecode(res.body) as Map<String, dynamic>;
        final url = _safeString(parsed, 'avatarUrl');
        if (url != null) await _storage.write(key: _kAvatarKey, value: url);
        return (success: true, error: null, avatarUrl: url);
      }

      final parsed = jsonDecode(res.body) as Map<String, dynamic>;
      return (
        success: false,
        error: _safeString(parsed, 'error') ?? 'Yükleme başarısız.',
        avatarUrl: null,
      );
    } catch (e) {
      return (success: false, error: _errorMessage(e), avatarUrl: null);
    }
  }

  Future<void> _saveSession({
    required String token,
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    await _storage.write(key: _kTokenKey, value: token);
    await _storage.write(key: _kNameKey, value: name);
    await _storage.write(key: _kEmailKey, value: email);
    if (avatarUrl != null) {
      await _storage.write(key: _kAvatarKey, value: avatarUrl);
    }
  }
}
