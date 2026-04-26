import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

const _kTokenKey = 'auth_token';
const _kNameKey = 'auth_name';
const _kEmailKey = 'auth_email';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<AuthState> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kApiBaseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final token = body['token'] as String;
        final user = body['user'] as Map<String, dynamic>;
        await _saveSession(
          token: token,
          name: user['name'] as String,
          email: user['email'] as String,
        );
        return AuthState(
          status: AuthStatus.authenticated,
          token: token,
          displayName: user['name'] as String,
          email: user['email'] as String,
        );
      }

      return AuthState(
        status: AuthStatus.guest,
        errorMessage: body['error'] as String? ?? 'Giriş başarısız.',
      );
    } catch (_) {
      return const AuthState(
        status: AuthStatus.guest,
        errorMessage: 'Sunucuya bağlanılamadı.',
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
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name, 'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201) {
        final token = body['token'] as String;
        final user = body['user'] as Map<String, dynamic>;
        await _saveSession(
          token: token,
          name: user['name'] as String,
          email: user['email'] as String,
        );
        return AuthState(
          status: AuthStatus.authenticated,
          token: token,
          displayName: user['name'] as String,
          email: user['email'] as String,
        );
      }

      return AuthState(
        status: AuthStatus.guest,
        errorMessage: body['error'] as String? ?? 'Kayıt başarısız.',
      );
    } catch (_) {
      return const AuthState(
        status: AuthStatus.guest,
        errorMessage: 'Sunucuya bağlanılamadı.',
      );
    }
  }

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
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final parsed = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final updatedName = parsed['name'] as String?;
        if (updatedName != null) {
          await _storage.write(key: _kNameKey, value: updatedName);
        }
        return (success: true, error: null, newName: updatedName);
      }
      return (success: false, error: parsed['error'] as String? ?? 'Güncelleme başarısız.', newName: null);
    } catch (_) {
      return (success: false, error: 'Sunucuya bağlanılamadı.', newName: null);
    }
  }

  Future<AuthState> restoreSession() async {
    final token = await _storage.read(key: _kTokenKey);
    final name = await _storage.read(key: _kNameKey);
    final email = await _storage.read(key: _kEmailKey);
    if (token == null || email == null) return const AuthState();
    return AuthState(
      status: AuthStatus.authenticated,
      token: token,
      displayName: name,
      email: email,
    );
  }

  Future<({bool success, String? error})> deleteAccount() async {
    final token = await _storage.read(key: _kTokenKey);
    if (token == null) return (success: false, error: 'Oturum bulunamadı.');

    try {
      final res = await http
          .delete(
            Uri.parse('$kApiBaseUrl/api/auth/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 204) {
        await clearSession();
        return (success: true, error: null);
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (success: false, error: body['error'] as String? ?? 'Hesap silinemedi.');
    } catch (_) {
      return (success: false, error: 'Sunucuya bağlanılamadı.');
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kNameKey);
    await _storage.delete(key: _kEmailKey);
  }

  Future<void> _saveSession({
    required String token,
    required String name,
    required String email,
  }) async {
    await _storage.write(key: _kTokenKey, value: token);
    await _storage.write(key: _kNameKey, value: name);
    await _storage.write(key: _kEmailKey, value: email);
  }
}
