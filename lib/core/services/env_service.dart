import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads API URL from --dart-define, .env asset, or a safe local default.
class EnvService {
  static const String _defineApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: 'assets/config.env');
    } catch (_) {
      // Fall back to dart-define or hard-coded default.
    }
    try {
      await dotenv.load(fileName: '.env', mergeWith: dotenv.env);
    } catch (_) {
      // Optional local override (not committed).
    }
  }

  static String get apiBaseUrl {
    if (_defineApiBaseUrl.isNotEmpty) {
      return _normalize(_defineApiBaseUrl);
    }
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return _normalize(fromEnv);
    }
    return 'http://127.0.0.1:8000/api';
  }

  static String? get firebaseApiKey => dotenv.maybeGet('FIREBASE_API_KEY');
  static String? get firebaseAppId => dotenv.maybeGet('FIREBASE_APP_ID');
  static String? get firebaseSenderId =>
      dotenv.maybeGet('FIREBASE_MESSAGING_SENDER_ID');
  static String? get firebaseProjectId => dotenv.maybeGet('FIREBASE_PROJECT_ID');

  static String _normalize(String url) {
    var value = url.trim();
    if (!value.endsWith('/api')) {
      value = value.endsWith('/') ? '${value}api' : '$value/api';
    }
    return value;
  }
}
