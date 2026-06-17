import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthService({
    ApiClient? apiClient,
    FlutterSecureStorage? storage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: false,
              ),
            );

  Future<User> login(String email, String password) async {
    final response = await _apiClient.post(
      '/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw AuthException('Unexpected login response');
    }

    final user = User.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
    final token = data['token']?.toString() ?? '';

    if (token.isEmpty) {
      throw AuthException('Missing authentication token');
    }

    if (user.role != AppConstants.roleAdmin &&
        user.role != AppConstants.roleAccountant &&
        user.role != AppConstants.roleCustomer) {
      throw AuthException('Unauthorized role for this application.');
    }

    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(
      key: AppConstants.userKey,
      value: jsonEncode(user.toJson()),
    );

    return user;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/logout');
    } catch (_) {
      // Clear local session even if remote logout fails.
    }
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Future<User?> getCurrentUser() async {
    try {
      final userJson = await _storage.read(key: AppConstants.userKey);
      if (userJson == null) return null;
      return User.fromJson(
        Map<String, dynamic>.from(jsonDecode(userJson) as Map),
      );
    } catch (e) {
      await _storage.deleteAll();
      return null;
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } catch (e) {
      await _storage.deleteAll();
      return null;
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'role': 'customer',
      },
    );
    final data = response.data;
    if (data is Map && data['user'] is Map) {
      return User.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    }
    throw AuthException('Registration failed.');
  }

  Future<User> googleLogin(String idToken) async {
    final response = await _apiClient.post(
      '/auth/google',
      data: {'id_token': idToken},
    );
    final data = response.data;
    if (data is Map && data['user'] is Map) {
      final user = User.fromJson(Map<String, dynamic>.from(data['user'] as Map));
      final token = data['token']?.toString() ?? '';
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(
        key: AppConstants.userKey,
        value: jsonEncode(user.toJson()),
      );
      return user;
    }
    throw AuthException('Google login failed.');
  }

  Future<void> resendVerification(String email) async {
    await _apiClient.post('/email/resend', data: {'email': email});
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<User> updateProfile({
    String? name,
    String? password,
  }) async {
    final response = await _apiClient.put(
      '/admin/profile',
      data: {
        if (name != null) 'name': name,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );
    final data = response.data;
    if (data is Map && data['user'] is Map) {
      final user = User.fromJson(Map<String, dynamic>.from(data['user'] as Map));
      await _storage.write(
        key: AppConstants.userKey,
        value: jsonEncode(user.toJson()),
      );
      return user;
    }
    throw AuthException('Unable to update profile');
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
