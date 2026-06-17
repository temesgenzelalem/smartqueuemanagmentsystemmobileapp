import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/routes/app_routes.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isDone = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      setState(() => _isDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isDone
            ? _buildSuccessView()
            : _buildSignupForm(authState),
        ),
      ),
    );
  }

  Widget _buildSignupForm(authState) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/tsehay_logo.png',
                height: 80,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_add, size: 48, color: Color(0xFFD4AF37)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Join Tsehay Bank',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a customer account to join the queue from anywhere.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (authState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Email required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: 'Minimum 6 characters',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: authState.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Sign In', style: TextStyle(color: Color(0xFFD4AF37))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Check your email',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'We sent a verification link to ${_emailController.text}.\nPlease verify your email to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('GO TO LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
