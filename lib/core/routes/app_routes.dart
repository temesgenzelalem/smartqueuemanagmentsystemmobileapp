import 'package:flutter/material.dart';

import '../../screens/accountant/accountant_dashboard_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String adminDashboard = '/admin-dashboard';
  static const String accountantDashboard = '/accountant-dashboard';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    adminDashboard: (_) => const AdminDashboardScreen(),
    accountantDashboard: (_) => const AccountantDashboardScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return MaterialPageRoute(builder: (_) => const LoginScreen());
  }
}
