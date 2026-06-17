import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_routes.dart';
import 'core/services/env_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvService.init();
  await HiveService.init();
  await FirebaseService.init();

  runApp(const ProviderScope(child: SmartQueueMobileApp()));
}

class SmartQueueMobileApp extends ConsumerWidget {
  const SmartQueueMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Smart Queue Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ref.watch(themeNotifierProvider),
      locale: ref.watch(localeNotifierProvider),
      supportedLocales: const [Locale('en'), Locale('am')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (var supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return supportedLocales.first;
      },
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
