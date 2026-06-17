import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.login(email, password);
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        clearError: true,
      );
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } on DioException catch (e) {
      String message;
      if (e.response?.data is Map) {
        message = e.response!.data['message']?.toString() ?? 'Login failed';
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        message = 'Server timed out. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'No internet connection. Please check your data or Wi-Fi.';
      } else {
        message = 'Connection error: ${e.message}';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Registration failed')
          : 'Registration failed. Check your connection.';
      state = state.copyWith(isLoading: false, errorMessage: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: $e',
      );
    }
    return false;
  }

  Future<void> googleLogin(String idToken) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.googleLogin(idToken);
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        clearError: true,
      );
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google login failed.',
      );
    }
  }

  Future<void> resendVerification(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.resendVerification(email);
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to resend.');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) {
      state = const AuthState();
      return;
    }
    final user = await _authService.getCurrentUser();
    if (user != null && (user.role == AppConstants.roleAdmin || user.role == AppConstants.roleAccountant || user.role == AppConstants.roleCustomer)) {
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
        clearError: true,
      );
    } else {
      await _authService.logout();
      state = const AuthState();
    }
  }
}
