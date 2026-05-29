import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    await ref.read(authNotifierProvider.notifier).restoreSession();
    if (!mounted) return;
    final auth = ref.read(authNotifierProvider);
    String route = AppRoutes.login;
    if (auth.isAuthenticated && auth.user != null) {
      route = auth.user!.role == AppConstants.roleAdmin
          ? AppRoutes.adminDashboard
          : AppRoutes.accountantDashboard;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingIndicator(message: AppLocalizations.of(context)!.splashLoading),
    );
  }
}
