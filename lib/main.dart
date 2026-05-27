import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_routes.dart';
import 'core/services/env_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/hive_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvService.init();
  await HiveService.init();
  await FirebaseService.init();

  runApp(const ProviderScope(child: SmartQueueMobileApp()));
}

class SmartQueueMobileApp extends StatelessWidget {
  const SmartQueueMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Queue Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
