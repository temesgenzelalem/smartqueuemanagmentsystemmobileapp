import 'package:flutter/material.dart';

import 'package:smartqueue_mobileapp/screens/accountant/accountant_dashboard_screen.dart';
import 'package:smartqueue_mobileapp/screens/admin/admin_dashboard_screen.dart';
import 'package:smartqueue_mobileapp/screens/auth/login_screen.dart';
import 'package:smartqueue_mobileapp/screens/auth/signup_screen.dart';
import 'package:smartqueue_mobileapp/screens/auth/splash_screen.dart';
import 'package:smartqueue_mobileapp/screens/customer/customer_dashboard_screen.dart';
import 'package:smartqueue_mobileapp/screens/customer/about_page.dart';
import 'package:smartqueue_mobileapp/screens/settings/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String adminDashboard = '/admin-dashboard';
  static const String accountantDashboard = '/accountant-dashboard';
  static const String customerDashboard = '/customer-dashboard';
  static const String settings = '/settings';
  static const String about = '/about';

  static Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),
    adminDashboard: (_) => const AdminDashboardScreen(),
    accountantDashboard: (_) => const AccountantDashboardScreen(),
    customerDashboard: (_) => const CustomerDashboardScreen(),
    settings: (_) => const SettingsScreen(),
    about: (_) => const AboutPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute(builder: builder, settings: settings);
    }
    return MaterialPageRoute(builder: (_) => const LoginScreen());
  }
}
