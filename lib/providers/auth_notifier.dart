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
      final message = e.response?.data is Map
          ? (e.response!.data['message']?.toString() ?? 'Login failed')
          : 'Login failed. Check your connection.';
      state = state.copyWith(isLoading: false, errorMessage: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: $e',
      );
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
    if (user != null && _isStaff(user)) {
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

  bool _isStaff(User user) =>
      user.role == AppConstants.roleAdmin ||
      user.role == AppConstants.roleAccountant;
}
