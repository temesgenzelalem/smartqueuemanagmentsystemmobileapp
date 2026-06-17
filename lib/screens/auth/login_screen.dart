import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/language_selector.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    final auth = ref.read(authNotifierProvider);
    if (auth.isAuthenticated && auth.user != null) {
      String route;
      if (auth.user!.role == AppConstants.roleAdmin) {
        route = AppRoutes.adminDashboard;
      } else if (auth.user!.role == AppConstants.roleAccountant) {
        route = AppRoutes.accountantDashboard;
      } else {
        route = AppRoutes.customerDashboard;
      }
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/tsehay_logo.png',
                          height: 100,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.account_balance,
                            size: 60,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        Align(alignment: Alignment.topRight, child: const LanguageSelector()),
                        const SizedBox(height: 12),
                        Text(
                          loc.loginTitle,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.loginSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (auth.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              auth.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: loc.emailLabel,
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Email required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: loc.passwordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(loc.signInButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("New customer?"),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signup),
                              child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
