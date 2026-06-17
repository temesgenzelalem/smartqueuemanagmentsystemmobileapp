import '../services/env_service.dart';

class AppConstants {
  static String get baseUrl => EnvService.apiBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static const String roleAdmin = 'admin';
  static const String roleAccountant = 'accountant';
  static const String roleCustomer = 'customer';

  static const int unauthorized401 = 401;

  static const String hiveBoxCache = 'sq_cache';
  static const String hiveKeyQueue = 'cached_queue';
  static const String hiveKeyPendingSync = 'pending_sync_ops';
}
