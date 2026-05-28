import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://smartqueuemanagmentsystem-backend.onrender.com/api',
);

const googleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue: '',
);

// ---------------------------------------------------------------------------
// App entry
// ---------------------------------------------------------------------------

void main() {
  runApp(const SmartQueueStaffApp());
}

class SmartQueueStaffApp extends StatelessWidget {
  const SmartQueueStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tsehay Bank Smart Queue',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          primary: AppColors.gold,
          secondary: AppColors.blue,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

class AppColors {
  static const gold = Color(0xFFD4AF37);
  static const blue = Color(0xFF0F2A44);
  static const background = Color(0xFFF6F8FB);
  static const danger = Color(0xFFB91C1C);
  static const success = Color(0xFF166534);
  static const surface = Colors.white;
}

// ---------------------------------------------------------------------------
// API client
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
}

class ApiClient {
  ApiClient(this._prefs);
  final SharedPreferences _prefs;

  String? get token => _prefs.getString('token');

  Map<String, String> get _headers {
    final h = <String, String>{'Accept': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await post(
      '/login',
      body: {'email': email, 'password': password},
    );
    return _saveSession(data);
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final data = await post('/auth/google', body: {'id_token': idToken});
    return _saveSession(data);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await post(
      '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': 'customer',
      },
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> resendVerification(String email) async {
    await post('/email/resend', body: {'email': email});
  }

  Future<void> logout() async {
    try {
      if (token != null) await post('/logout');
    } catch (_) {}
    await _prefs.remove('token');
    await _prefs.remove('user');
  }

  Map<String, dynamic>? cachedUser() {
    final raw = _prefs.getString('user');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Map<String, dynamic> _saveSession(dynamic data) {
    final user = Map<String, dynamic>.from(data['user'] as Map);
    _prefs.setString('token', data['token'] as String);
    _prefs.setString('user', jsonEncode(user));
    return user;
  }

  void saveUser(Map<String, dynamic> user) {
    _prefs.setString('user', jsonEncode(user));
  }

  // ── Generic HTTP ──────────────────────────────────────────────────────────

  Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final res = await http.post(
      _uri(path),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final res = await http.put(
      _uri(path),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> multipart(
    String path,
    Map<String, String> fields,
    Map<String, File> files,
  ) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers);
    fields.forEach((k, v) => request.fields[k] = v);
    for (final entry in files.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(entry.key, entry.value.path),
      );
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Future<dynamic> uploadReceipt(String path, String field, File file) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath(field, file.path));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  Uri _uri(String path) => Uri.parse('$apiBaseUrl$path');

  dynamic _decode(http.Response res) {
    final text = res.body;
    final decoded = text.isEmpty ? null : jsonDecode(text);
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    final msg = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'Request failed (${res.statusCode})';
    throw ApiException(msg, res.statusCode);
  }
}

// ---------------------------------------------------------------------------
// Auth gate — decides which shell to show
// ---------------------------------------------------------------------------

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  ApiClient? api;
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final client = ApiClient(prefs);
    setState(() {
      api = client;
      user = client.cachedUser();
    });
  }

  Future<void> _onLogin(Map<String, dynamic> u) async {
    setState(() => user = u);
  }

  Future<void> _logout() async {
    await api?.logout();
    if (mounted) setState(() => user = null);
  }

  @override
  Widget build(BuildContext context) {
    final client = api;
    if (client == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final u = user;
    if (u == null) {
      return UnifiedAuthScreen(api: client, onLogin: _onLogin);
    }
    final role = u['role'] as String? ?? '';
    if (role == 'admin')
      return AdminShell(api: client, user: u, onLogout: _logout);
    if (role == 'accountant')
      return AccountantShell(api: client, user: u, onLogout: _logout);
    return CustomerShell(api: client, user: u, onLogout: _logout);
  }
}

// ---------------------------------------------------------------------------
// Unified authentication screen for customers, admins, and accountants
// ---------------------------------------------------------------------------

class UnifiedAuthScreen extends StatefulWidget {
  const UnifiedAuthScreen({
    required this.api,
    required this.onLogin,
    super.key,
  });
  final ApiClient api;
  final ValueChanged<Map<String, dynamic>> onLogin;

  @override
  State<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends State<UnifiedAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _verificationRequired = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
      _verificationRequired = false;
    });

    try {
      final user = await widget.api.login(_email.text.trim(), _password.text);
      final role = user['role'] as String? ?? '';
      if (role == 'admin' || role == 'accountant' || role == 'customer') {
        widget.onLogin(user);
        return;
      }
      throw const ApiException('Unsupported account role.');
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        setState(() {
          _error = e.message;
          _verificationRequired = true;
        });
      } else {
        setState(() => _error = e.message);
      }
    } catch (_) {
      setState(() => _error = 'Unable to connect to the server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final googleSignIn = GoogleSignIn(
        clientId: googleClientId.isEmpty ? null : googleClientId,
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) return;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw const ApiException('Google sign-in failed.');
      final user = await widget.api.googleLogin(idToken);
      if (user['role'] != 'customer') {
        throw const ApiException(
          'Google login is only available for customers.',
        );
      }
      widget.onLogin(user);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendVerification() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await widget.api.resendVerification(_email.text.trim());
      if (mounted) {
        setState(() {
          _success = 'Verification email sent. Check your inbox.';
          _verificationRequired = false;
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BankHeader(subtitle: 'Smart Queue Authentication'),
                      const SizedBox(height: 18),
                      Text(
                        'Sign in as staff or customer',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Admins and accountants use email and password. Customers can sign in with email/password or continue with Google.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _email,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _password,
                        label: 'Password',
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        ErrorBox(_error!),
                        if (_verificationRequired) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loading ? null : _resendVerification,
                            child: const Text('Resend verification email'),
                          ),
                        ],
                      ],
                      if (_success != null) ...[
                        const SizedBox(height: 14),
                        SuccessBox(_success!),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _loading ? null : _login,
                        child: Text(_loading ? 'Signing in...' : 'Sign In'),
                      ),
                      const SizedBox(height: 12),
                      _GoogleSignInButton(
                        loading: _loading,
                        onTap: _googleLogin,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('New customer?'),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _loading
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CustomerSignupScreen(
                                          api: widget.api,
                                          onLogin: widget.onLogin,
                                        ),
                                      ),
                                    ),
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Staff login screen
// ---------------------------------------------------------------------------

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({required this.api, required this.onLogin, super.key});
  final ApiClient api;
  final ValueChanged<Map<String, dynamic>> onLogin;

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await widget.api.login(_email.text.trim(), _password.text);
      final role = user['role'] as String? ?? '';
      if (role != 'admin' && role != 'accountant') {
        throw const ApiException('This login is for staff/managers only.');
      }
      widget.onLogin(user);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to connect to the server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BankHeader(subtitle: 'Manager & window staff'),
                    const SizedBox(height: 24),
                    Text(
                      'Staff Login',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _password,
                      label: 'Password',
                      obscureText: true,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      ErrorBox(_error!),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      child: Text(_loading ? 'Logging in...' : 'Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer login screen  (email/pass + Google)
// ---------------------------------------------------------------------------

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({
    required this.api,
    required this.onLogin,
    super.key,
  });
  final ApiClient api;
  final ValueChanged<Map<String, dynamic>> onLogin;

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _verificationRequired = false;
  String? _error;
  String? _success;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
      _verificationRequired = false;
    });
    try {
      final user = await widget.api.login(_email.text.trim(), _password.text);
      if (user['role'] != 'customer') {
        throw const ApiException(
          'This login is for customers only. Use the Staff Login button.',
        );
      }
      widget.onLogin(user);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        setState(() {
          _verificationRequired = true;
          _error = e.message;
        });
      } else {
        setState(() => _error = e.message);
      }
    } catch (_) {
      setState(() => _error = 'Unable to connect to the server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final googleSignIn = GoogleSignIn(
        clientId: googleClientId.isEmpty ? null : googleClientId,
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _loading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null)
        throw const ApiException('Google sign-in failed: no ID token.');
      final user = await widget.api.googleLogin(idToken);
      widget.onLogin(user);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.api.resendVerification(_email.text.trim());
      setState(() {
        _success = 'Verification email sent. Check your inbox.';
        _verificationRequired = false;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BankHeader(subtitle: 'Customer Portal'),
                    const SizedBox(height: 24),
                    Text(
                      'Sign In',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _password,
                      label: 'Password',
                      obscureText: true,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      ErrorBox(_error!),
                      if (_verificationRequired) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loading ? null : _resend,
                          child: const Text('Resend verification email'),
                        ),
                      ],
                    ],
                    if (_success != null) ...[
                      const SizedBox(height: 14),
                      SuccessBox(_success!),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      child: Text(_loading ? 'Signing in...' : 'Sign In'),
                    ),
                    const SizedBox(height: 12),
                    _GoogleSignInButton(loading: _loading, onTap: _googleLogin),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerSignupScreen(
                                api: widget.api,
                                onLogin: widget.onLogin,
                              ),
                            ),
                          ),
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simple coloured G icon built from text (no image asset needed)
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4285F4),
                  Color(0xFF34A853),
                  Color(0xFFFBBC05),
                  Color(0xFFEA4335),
                ],
              ),
            ),
            child: const Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Continue with Google',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer sign-up screen
// ---------------------------------------------------------------------------

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({
    required this.api,
    required this.onLogin,
    super.key,
  });
  final ApiClient api;
  final ValueChanged<Map<String, dynamic>> onLogin;

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.api.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      setState(() => _done = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to connect to the server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AppCard(
                child: _done
                    ? _VerificationSentView(
                        email: _email.text,
                        api: widget.api,
                        onLogin: widget.onLogin,
                      )
                    : _RegisterForm(
                        name: _name,
                        email: _email,
                        password: _password,
                        loading: _loading,
                        error: _error,
                        onSubmit: _register,
                        onLoginTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerLoginScreen(
                              api: widget.api,
                              onLogin: widget.onLogin,
                            ),
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

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.name,
    required this.email,
    required this.password,
    required this.loading,
    required this.error,
    required this.onSubmit,
    required this.onLoginTap,
  });
  final TextEditingController name, email, password;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit, onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BankHeader(subtitle: 'Customer Registration'),
        const SizedBox(height: 24),
        Text(
          'Create Account',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        AppTextField(controller: name, label: 'Full Name'),
        const SizedBox(height: 14),
        AppTextField(
          controller: email,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: password,
          label: 'Password (min 6 chars)',
          obscureText: true,
        ),
        if (error != null) ...[const SizedBox(height: 14), ErrorBox(error!)],
        const SizedBox(height: 22),
        FilledButton(
          onPressed: loading ? null : onSubmit,
          child: Text(loading ? 'Creating...' : 'Create Account'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account? '),
            GestureDetector(
              onTap: onLoginTap,
              child: Text(
                'Sign in',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VerificationSentView extends StatefulWidget {
  const _VerificationSentView({
    required this.email,
    required this.api,
    required this.onLogin,
  });
  final String email;
  final ApiClient api;
  final ValueChanged<Map<String, dynamic>> onLogin;

  @override
  State<_VerificationSentView> createState() => _VerificationSentViewState();
}

class _VerificationSentViewState extends State<_VerificationSentView> {
  bool _resending = false;
  String? _msg;

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _msg = null;
    });
    try {
      await widget.api.resendVerification(widget.email);
      setState(() => _msg = 'Verification email resent.');
    } on ApiException catch (e) {
      setState(() => _msg = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: AppColors.gold,
        ),
        const SizedBox(height: 16),
        Text(
          'Check your email',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent a verification link to\n${widget.email}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 8),
        const Text(
          'Click the link in the email, then come back and sign in.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        if (_msg != null) ...[const SizedBox(height: 12), InfoBox(_msg!)],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CustomerLoginScreen(api: widget.api, onLogin: widget.onLogin),
            ),
          ),
          child: const Text('Go to Sign In'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _resending ? null : _resend,
          child: Text(_resending ? 'Sending...' : 'Resend verification email'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Customer shell
// ---------------------------------------------------------------------------

class CustomerShell extends StatefulWidget {
  const CustomerShell({
    required this.api,
    required this.user,
    required this.onLogout,
    super.key,
  });
  final ApiClient api;
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      CustomerTransactionsPage(api: widget.api),
      CustomerNewRequestPage(api: widget.api),
      CustomerReceiptsPage(api: widget.api),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.user['name'] ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'My Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'New Request',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Receipts',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer — My Transactions
// ---------------------------------------------------------------------------

class CustomerTransactionsPage extends StatefulWidget {
  const CustomerTransactionsPage({required this.api, super.key});
  final ApiClient api;

  @override
  State<CustomerTransactionsPage> createState() =>
      _CustomerTransactionsPageState();
}

class _CustomerTransactionsPageState extends State<CustomerTransactionsPage> {
  List<dynamic> _txs = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetch(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await widget.api.get('/my-transactions') as List;
      if (mounted)
        setState(() {
          _txs = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_txs.isEmpty) {
      return const Center(
        child: Text(
          'No transactions yet.\nUse "New Request" to get started.',
          textAlign: TextAlign.center,
        ),
      );
    }
    final calledTx = _txs.firstWhere(
      (tx) => tx['status'] == 'pending',
      orElse: () => null,
    );
    return Column(
      children: [
        if (calledTx != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.gold,
            child: Text(
              '🔔 You are called! Queue: ${calledTx['queue_number']} — Please go to your window.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetch,
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _txs.length,
              itemBuilder: (_, i) {
                final tx = _txs[i];
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${(tx['type'] as String? ?? '').toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (tx['queue_number'] != null)
                            Chip(
                              label: Text('${tx['queue_number']}'),
                              backgroundColor: AppColors.gold.withOpacity(0.15),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Amount: ${money(tx['amount'])}'),
                      Text('Account: ${tx['account_number'] ?? ''}'),
                      const SizedBox(height: 6),
                      StatusChip(status: '${tx['status'] ?? 'waiting'}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Customer — New Transaction Request
// ---------------------------------------------------------------------------

class CustomerNewRequestPage extends StatefulWidget {
  const CustomerNewRequestPage({required this.api, super.key});
  final ApiClient api;

  @override
  State<CustomerNewRequestPage> createState() => _CustomerNewRequestPageState();
}

class _CustomerNewRequestPageState extends State<CustomerNewRequestPage> {
  final _accountNumber = TextEditingController();
  final _accountHolder = TextEditingController();
  final _amount = TextEditingController();
  final _amountWords = TextEditingController();
  final _depositedBy = TextEditingController();
  final _toAccount = TextEditingController();

  String _type = 'deposit';
  List<dynamic> _windows = [];
  String? _windowId;
  File? _photo;
  File? _photoFile;
  bool _loading = false;
  String? _error;
  String? _success;

  final _sigController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void initState() {
    super.initState();
    _loadWindows();
  }

  @override
  void dispose() {
    _sigController.dispose();
    super.dispose();
  }

  Future<void> _loadWindows() async {
    try {
      final data = await widget.api.get('/available-windows') as List;
      if (mounted) setState(() => _windows = data);
    } catch (_) {}
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (_windowId == null) {
      setState(() => _error = 'Please select a window.');
      return;
    }
    if (_photo == null) {
      setState(() => _error = 'Please upload your photo.');
      return;
    }
    if (_sigController.isEmpty) {
      setState(() => _error = 'Please draw your signature.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final sigBytes = await _sigController.toPngBytes();
      if (sigBytes == null)
        throw const ApiException('Could not export signature.');
      final tmpSig = File(
        '${Directory.systemTemp.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tmpSig.writeAsBytes(sigBytes);

      final fields = <String, String>{
        'type': _type,
        'window_id': _windowId!,
        'account_number': _accountNumber.text.trim(),
        'account_holder': _accountHolder.text.trim(),
        'amount': _amount.text.trim(),
        'amount_words': _amountWords.text.trim(),
        'deposited_by': _depositedBy.text.trim(),
        'to_account': _toAccount.text.trim(),
        'date': DateTime.now().toIso8601String().split('T').first,
      };

      await widget.api.multipart('/transactions', fields, {
        'photo': _photo!,
        'signature': tmpSig,
      });

      setState(
        () => _success = 'Transaction submitted! You are now in the queue.',
      );
      _accountNumber.clear();
      _accountHolder.clear();
      _amount.clear();
      _amountWords.clear();
      _depositedBy.clear();
      _toAccount.clear();
      _photo = null;
      _sigController.clear();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(title: 'New Transaction Request'),

          // Step 1: Type
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Step 1 — Choose service',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['deposit', 'withdraw', 'transfer'].map((t) {
                    final selected = _type == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.gold : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.gold
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            t[0].toUpperCase() + t.substring(1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select window',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                if (_windows.isEmpty)
                  const Text(
                    'Loading windows...',
                    style: TextStyle(color: Colors.black54),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _windows.map((w) {
                      final id = '${w['id']}';
                      final sel = _windowId == id;
                      return GestureDetector(
                        onTap: () => setState(() => _windowId = id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.gold.withOpacity(0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  sel ? AppColors.gold : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${w['name']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: sel ? AppColors.gold : Colors.black87,
                                ),
                              ),
                              Text(
                                '${w['waiting_count'] ?? 0} waiting',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Step 2: Details
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Step 2 — Fill details',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _accountNumber,
                  label: 'Account Number',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _accountHolder,
                  label: 'Account Holder Name',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _amount,
                  label: 'Amount (ETB)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _amountWords,
                  label: 'Amount in Words',
                  hint: 'e.g. Five Hundred Birr',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _depositedBy,
                  label: 'Deposited by (optional)',
                ),
                if (_type == 'transfer') ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _toAccount,
                    label: 'Recipient Account Number',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Step 3: Photo
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Step 3 — Upload photo',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                if (_photo != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _photo!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _photo = null),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.gold,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.gold.withOpacity(0.05),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera_outlined,
                              color: AppColors.gold,
                              size: 32,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tap to upload photo',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Step 4: Signature
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Step 4 — Draw signature',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _sigController.clear(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Signature(
                    controller: _sigController,
                    height: 160,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in the box above',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_error != null) ...[
            ErrorBox(_error!),
            const SizedBox(height: 10),
          ],
          if (_success != null) ...[
            SuccessBox(_success!),
            const SizedBox(height: 10),
          ],

          FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: const Icon(Icons.send_outlined),
            label: Text(_loading ? 'Submitting...' : 'Submit to Queue'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer — Receipts
// ---------------------------------------------------------------------------

class CustomerReceiptsPage extends StatefulWidget {
  const CustomerReceiptsPage({required this.api, super.key});
  final ApiClient api;

  @override
  State<CustomerReceiptsPage> createState() => _CustomerReceiptsPageState();
}

class _CustomerReceiptsPageState extends State<CustomerReceiptsPage> {
  List<dynamic> _receipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.get('/my-receipts') as List;
      if (mounted)
        setState(() {
          _receipts = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_receipts.isEmpty) {
      return const Center(
        child: Text(
          'No receipts yet.\nReceipts appear here after transactions are completed.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _receipts.length,
        itemBuilder: (_, i) {
          final r = _receipts[i];
          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${r['transaction']?['type'] ?? 'Transaction'} Receipt'
                      .toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Amount: ${money(r['transaction']?['amount'])}',
                  style: const TextStyle(color: Colors.black54),
                ),
                if (r['receipt_url'] != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '${r['receipt_url']}',
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin shell (unchanged logic, ported cleanly)
// ---------------------------------------------------------------------------

class AdminShell extends StatefulWidget {
  const AdminShell({
    required this.api,
    required this.user,
    required this.onLogout,
    super.key,
  });
  final ApiClient api;
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int tab = 0;
  late Map<String, dynamic> currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = Map<String, dynamic>.from(widget.user);
  }

  void _updateUser(Map<String, dynamic> user) {
    setState(() {
      currentUser = Map<String, dynamic>.from(user);
    });
    widget.api.saveUser(currentUser);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminOverview(api: widget.api),
      StaffManagement(api: widget.api),
      AdminTransactions(api: widget.api),
      AdminSettings(api: widget.api),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Manager: ${currentUser['name'] ?? ''}'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminProfileScreen(
                  api: widget.api,
                  user: currentUser,
                  onProfileUpdated: _updateUser,
                ),
              ),
            ),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Staff',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({
    required this.api,
    required this.user,
    required this.onProfileUpdated,
    super.key,
  });
  final ApiClient api;
  final Map<String, dynamic> user;
  final ValueChanged<Map<String, dynamic>> onProfileUpdated;

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _email;
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user['name']?.toString() ?? '');
    _email = TextEditingController(
      text: widget.user['email']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final body = <String, dynamic>{};
      final name = _name.text.trim();
      final email = _email.text.trim();
      final password = _password.text;
      if (name.isNotEmpty && name != widget.user['name']) {
        body['name'] = name;
      }
      if (email.isNotEmpty && email != widget.user['email']) {
        body['email'] = email;
      }
      if (password.isNotEmpty) {
        body['password'] = password;
      }
      if (body.isEmpty) {
        setState(() {
          _success = 'No changes to save.';
          _loading = false;
        });
        return;
      }
      final data = await widget.api.put('/admin/profile', body: body)
          as Map<String, dynamic>;
      final updatedUser = Map<String, dynamic>.from(data['user'] as Map);
      widget.onProfileUpdated(updatedUser);
      setState(() {
        _success = 'Profile updated successfully.';
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to update profile.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BankHeader(subtitle: 'Profile settings'),
                    const SizedBox(height: 20),
                    AppTextField(controller: _name, label: 'Name'),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _password,
                      label: 'New password (leave blank to keep current)',
                      obscureText: true,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      ErrorBox(_error!),
                    ],
                    if (_success != null) ...[
                      const SizedBox(height: 16),
                      SuccessBox(_success!),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _saveProfile,
                      child: Text(_loading ? 'Saving...' : 'Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminOverview extends StatefulWidget {
  const AdminOverview({required this.api, super.key});
  final ApiClient api;

  @override
  State<AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<AdminOverview> {
  List<dynamic> liveQueue = [];
  Map<String, dynamic> totals = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => loading = true);
    try {
      final queue = await widget.api.get('/admin/live-queue') as List;
      final report =
          await widget.api.get('/transactions/daily?type=all') as Map;
      setState(() {
        liveQueue = queue;
        totals = Map<String, dynamic>.from(report['totals'] as Map? ?? {});
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const BankHeader(subtitle: 'Live branch operations'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatTile(label: 'Deposits', value: money(totals['deposit'])),
              StatTile(label: 'Withdrawals', value: money(totals['withdraw'])),
              StatTile(label: 'Transfers', value: money(totals['transfer'])),
              StatTile(label: 'Transactions', value: '${totals['count'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 18),
          SectionTitle(
            title: 'Live Queue',
            trailing: loading ? 'Loading...' : '${liveQueue.length} windows',
          ),
          for (final window in liveQueue)
            AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${window['name'] ?? 'Window'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Staff: ${window['accountant']?['name'] ?? 'Unassigned'}',
                  ),
                  const Divider(),
                  ...((window['transactions'] as List? ?? []).map(
                    (tx) => TransactionListTile(tx: tx),
                  )),
                  if ((window['transactions'] as List? ?? []).isEmpty)
                    const Text('No active customers.'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class StaffManagement extends StatefulWidget {
  const StaffManagement({required this.api, super.key});
  final ApiClient api;

  @override
  State<StaffManagement> createState() => _StaffManagementState();
}

class _StaffManagementState extends State<StaffManagement> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final window = TextEditingController();
  List<dynamic> staff = [];
  List<dynamic> windows = [];
  bool loading = false;
  String? message;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final accountants = await widget.api.get('/accountants') as List;
    final windowList = await widget.api.get('/windows') as List;
    setState(() {
      staff = accountants;
      windows = windowList;
    });
  }

  Future<void> addStaff() async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await widget.api.post(
        '/accountants',
        body: {
          'name': name.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
          'window': window.text.trim(),
        },
      );
      name.clear();
      email.clear();
      password.clear();
      window.clear();
      await refresh();
      setState(() => message = 'Accountant created.');
    } on ApiException catch (e) {
      setState(() => message = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteStaff(int id) async {
    await widget.api.delete('/accountants/$id');
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle(title: 'Add Window Staff'),
          AppCard(
            child: Column(
              children: [
                AppTextField(controller: name, label: 'Full name'),
                const SizedBox(height: 12),
                AppTextField(
                  controller: email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: password,
                  label: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: window,
                  label: 'Window name',
                  hint: 'Example: Window 1',
                ),
                if (message != null) ...[
                  const SizedBox(height: 12),
                  InfoBox(message!),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: loading ? null : addStaff,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(loading ? 'Saving...' : 'Create Accountant'),
                ),
              ],
            ),
          ),
          const SectionTitle(title: 'Accountants'),
          for (final item in staff)
            AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${item['name'] ?? ''}'),
                subtitle: Text(
                  '${item['email'] ?? ''}\nWindow: ${item['window']?['name'] ?? 'Not assigned'}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  onPressed: () => deleteStaff(item['id'] as int),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          const SectionTitle(title: 'Windows'),
          for (final item in windows)
            AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.meeting_room_outlined),
                title: Text('${item['name'] ?? ''}'),
                subtitle: Text(
                  'Staff: ${item['accountant']?['name'] ?? 'Unassigned'}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AdminTransactions extends StatefulWidget {
  const AdminTransactions({required this.api, super.key});
  final ApiClient api;

  @override
  State<AdminTransactions> createState() => _AdminTransactionsState();
}

class _AdminTransactionsState extends State<AdminTransactions> {
  String period = 'daily';
  String type = 'all';
  List<dynamic> transactions = [];
  Map<String, dynamic> totals = {};
  bool loading = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => loading = true);
    final report =
        await widget.api.get('/transactions/$period?type=$type') as Map;
    setState(() {
      transactions = report['transactions'] as List? ?? [];
      totals = Map<String, dynamic>.from(report['totals'] as Map? ?? {});
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: AppDropdown(
                value: period,
                values: const ['daily', 'weekly', 'monthly', 'yearly'],
                onChanged: (v) => setState(() => period = v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppDropdown(
                value: type,
                values: const ['all', 'deposit', 'withdraw', 'transfer'],
                onChanged: (v) => setState(() => type = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: loading ? null : refresh,
          child: Text(loading ? 'Loading...' : 'Load Report'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatTile(label: 'Deposit', value: money(totals['deposit'])),
            StatTile(label: 'Withdraw', value: money(totals['withdraw'])),
            StatTile(label: 'Transfer', value: money(totals['transfer'])),
          ],
        ),
        const SizedBox(height: 16),
        for (final tx in transactions) TransactionListTile(tx: tx),
        if (transactions.isEmpty)
          const AppCard(child: Text('No transactions found.')),
      ],
    );
  }
}

class AdminSettings extends StatefulWidget {
  const AdminSettings({required this.api, super.key});
  final ApiClient api;

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final min = TextEditingController(text: '100');
  final max = TextEditingController(text: '50000');
  String? message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await widget.api.get('/admin/settings') as Map;
    min.text = '${settings['withdraw_min'] ?? 100}';
    max.text = '${settings['withdraw_max'] ?? 50000}';
  }

  Future<void> save() async {
    try {
      await widget.api.post(
        '/admin/settings',
        body: {'withdraw_min': min.text, 'withdraw_max': max.text},
      );
      setState(() => message = 'Settings saved.');
    } on ApiException catch (e) {
      setState(() => message = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle(title: 'Withdrawal Rules'),
        AppCard(
          child: Column(
            children: [
              AppTextField(
                controller: min,
                label: 'Minimum withdraw amount',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: max,
                label: 'Maximum withdraw amount',
                keyboardType: TextInputType.number,
              ),
              if (message != null) ...[
                const SizedBox(height: 12),
                InfoBox(message!),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Accountant shell
// ---------------------------------------------------------------------------

class AccountantShell extends StatefulWidget {
  const AccountantShell({
    required this.api,
    required this.user,
    required this.onLogout,
    super.key,
  });
  final ApiClient api;
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  @override
  State<AccountantShell> createState() => _AccountantShellState();
}

class _AccountantShellState extends State<AccountantShell> {
  List<dynamic> queue = [];
  Map<String, dynamic>? selected;
  Timer? timer;
  bool loading = false;
  String? message;

  @override
  void initState() {
    super.initState();
    refresh();
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refresh(silent: true),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) setState(() => loading = true);
    try {
      final data = await widget.api.get('/queue') as List;
      setState(() {
        queue = data;
        if (selected != null) {
          selected = data
                  .cast<dynamic>()
                  .where((tx) => tx['id'] == selected!['id'])
                  .firstOrNull ??
              selected;
        }
      });
    } finally {
      if (mounted && !silent) setState(() => loading = false);
    }
  }

  Future<void> selectTx(Map<String, dynamic> tx) async {
    setState(() => loading = true);
    try {
      if (tx['status'] == 'waiting') {
        final data = await widget.api.post('/queue/select/${tx['id']}') as Map;
        selected = Map<String, dynamic>.from(data);
      } else {
        selected = tx;
      }
      await refresh(silent: true);
    } on ApiException catch (e) {
      setState(() => message = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> complete() async {
    final tx = selected;
    if (tx == null) return;
    await widget.api.post('/queue/complete/${tx['id']}');
    setState(() => message = 'Transaction completed.');
    await refresh();
  }

  Future<void> sendReceipt() async {
    final tx = selected;
    if (tx == null) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    await widget.api.uploadReceipt(
      '/receipts/${tx['id']}',
      'image',
      File(picked.path),
    );
    setState(() => message = 'Receipt sent.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Window Staff: ${widget.user['name'] ?? ''}'),
        actions: [
          IconButton(
            onPressed: () => refresh(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const BankHeader(subtitle: 'Queue processing'),
            const SizedBox(height: 14),
            if (message != null) InfoBox(message!),
            const SizedBox(height: 8),
            SectionTitle(
              title: 'Queue',
              trailing: loading ? 'Loading...' : '${queue.length} active',
            ),
            for (final tx in queue)
              AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => selectTx(Map<String, dynamic>.from(tx as Map)),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.gold,
                    child: Text('${queue.indexOf(tx) + 1}'),
                  ),
                  title: Text('${tx['user']?['name'] ?? 'Customer'}'),
                  subtitle: Text(
                    '${tx['type']} • ${money(tx['amount'])}\nQueue: ${tx['queue_number'] ?? '-'}',
                  ),
                  isThreeLine: true,
                  trailing: StatusChip(status: '${tx['status'] ?? 'waiting'}'),
                ),
              ),
            if (queue.isEmpty)
              const AppCard(child: Text('No customers in your queue.')),
            if (selected != null) ...[
              const SizedBox(height: 12),
              const SectionTitle(title: 'Selected Customer'),
              TransactionDetail(tx: selected!),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: selected!['status'] == 'completed' ? null : complete,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Complete Transaction'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: sendReceipt,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Receipt Image'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class BankHeader extends StatelessWidget {
  const BankHeader({required this.subtitle, super.key});
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/tsehay_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFF0F2A44)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    'TB',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tsehay Bank',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({required this.child, this.margin, super.key});
  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    super.key,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class AppDropdown extends StatelessWidget {
  const AppDropdown({
    required this.value,
    required this.values,
    required this.onChanged,
    super.key,
  });
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, this.trailing, super.key});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({required this.label, required this.value, super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => AppColors.success,
      'pending' || 'processing' => const Color(0xFFC2410C),
      _ => Colors.blueGrey,
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide.none,
    );
  }
}

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({required this.tx, super.key});
  final dynamic tx;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('${tx['type'] ?? 'Transaction'}'.toUpperCase()),
        subtitle: Text(
          'Account: ${tx['account_number'] ?? '-'}\nQueue: ${tx['queue_number'] ?? '-'}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              money(tx['amount']),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            StatusChip(status: '${tx['status'] ?? ''}'),
          ],
        ),
      ),
    );
  }
}

class TransactionDetail extends StatelessWidget {
  const TransactionDetail({required this.tx, super.key});
  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${tx['user']?['name'] ?? 'Customer'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              StatusChip(status: '${tx['status'] ?? ''}'),
            ],
          ),
          const Divider(),
          DetailRow(label: 'Type', value: '${tx['type'] ?? ''}'),
          DetailRow(label: 'Amount', value: money(tx['amount'])),
          DetailRow(
            label: 'Account number',
            value: '${tx['account_number'] ?? ''}',
          ),
          DetailRow(
            label: 'Account holder',
            value: '${tx['account_holder'] ?? ''}',
          ),
          DetailRow(
            label: 'Amount words',
            value: '${tx['amount_words'] ?? ''}',
          ),
          DetailRow(
            label: 'Deposited by',
            value: '${tx['deposited_by'] ?? ''}',
          ),
          DetailRow(
            label: 'Recipient account',
            value: '${tx['to_account'] ?? ''}',
          ),
          DetailRow(
            label: 'Queue number',
            value: '${tx['queue_number'] ?? ''}',
          ),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({required this.label, required this.value, super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorBox extends StatelessWidget {
  const ErrorBox(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SuccessBox extends StatelessWidget {
  const SuccessBox(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class InfoBox extends StatelessWidget {
  const InfoBox(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String money(dynamic value) {
  final number = num.tryParse('${value ?? 0}') ?? 0;
  return '${number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 2)} ETB';
}
