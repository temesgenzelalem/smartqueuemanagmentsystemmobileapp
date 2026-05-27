import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'env_service.dart';

/// Firebase placeholders — wire real options when push notifications are enabled.
class FirebaseService {
  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: EnvService.firebaseApiKey ?? 'placeholder-api-key',
          appId: EnvService.firebaseAppId ?? 'placeholder-app-id',
          messagingSenderId:
              EnvService.firebaseSenderId ?? 'placeholder-sender-id',
          projectId: EnvService.firebaseProjectId ?? 'placeholder-project-id',
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase init skipped (placeholder): $e');
      }
    }
  }
}
