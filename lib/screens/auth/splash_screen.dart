import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // Add a small delay for branding visibility
    await Future.delayed(const Duration(seconds: 2));
    await ref.read(authNotifierProvider.notifier).restoreSession();
    if (!mounted) return;
    final auth = ref.read(authNotifierProvider);
    String route = AppRoutes.login;
    if (auth.isAuthenticated && auth.user != null) {
      if (auth.user!.role == AppConstants.roleAdmin) {
        route = AppRoutes.adminDashboard;
      } else if (auth.user!.role == AppConstants.roleAccountant) {
        route = AppRoutes.accountantDashboard;
      } else {
        route = AppRoutes.customerDashboard;
      }
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/tsehay_logo.png',
              width: 180,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.account_balance,
                size: 80,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
            ),
          ],
        ),
      ),
    );
  }
}
