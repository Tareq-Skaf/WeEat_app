import 'package:flutter/material.dart';
import 'login_page.dart';
import '../services/api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _repass = TextEditingController();

  bool _loading = false;

  Future<void> _onRegister() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;

  if (_pass.text != _repass.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwords do not match")),
    );
    return;
  }

  setState(() => _loading = true);

  try {
    final api = ApiService();
    await api.register(
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      username: _username.text.trim().isNotEmpty ? _username.text.trim() : null,
      email: _email.text.trim(),
      password: _pass.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account created. Please login.")),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst("Exception: ", "")),
      ),
    );
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}


  static const Color background = Color(0xFFF7DCA2); // warm yellow
  static const Color fieldFill = Color(0xFFFFFBF5); // off-white field
  static const Color buttonGreen = Color(0xFF6F8574);

  Widget _buildField({
    required String hint, 
    TextEditingController? ctrl,
    Widget? suffix,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: fieldFill,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: const Offset(3, 6),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
          border: InputBorder.none,
          suffixIcon: suffix == null ? null : Padding(padding: const EdgeInsets.only(left:12.0), child: suffix),
          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _username.dispose();
    _email.dispose();
    _pass.dispose();
    _repass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 36, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Form fields
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(hint: 'First Name', ctrl: _first),
                    _buildField(hint: 'Last Name', ctrl: _last),
                    _buildField(
                      hint: 'Username (optional)',
                      ctrl: _username,
                      suffix: const Icon(Icons.alternate_email, color: Colors.grey),
                    ),
                    _buildField(
                      hint: 'Email',
                      ctrl: _email,
                      suffix: const Icon(Icons.mail_outline, color: Colors.grey),
                    ),
                    _buildField(
                      hint: 'Password',
                      ctrl: _pass,
                      obscure: true,
                      suffix: const Icon(Icons.lock_outline, color: Colors.grey),
                    ),
                    _buildField(
                      hint: 'Re-enter Password',
                      ctrl: _repass,
                      obscure: true,
                      suffix: const Icon(Icons.lock_outline, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Register button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: _loading ? null : _onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: Colors.black45,
                    fixedSize: const Size.fromHeight(64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  child: Text(_loading ? 'Registering...' : 'Register'),
                ),
              ),

              const SizedBox(height: 26),

              // Or divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.black26, thickness: 1)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Or', style: TextStyle(color: Colors.black54)),
                    ),
                    const Expanded(child: Divider(color: Colors.black26, thickness: 1)),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Login link (uses LoginPage from login_page.dart)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: TextStyle(color: Colors.black87)),
                      GestureDetector(
                        onTap: () {
                          // directly open the LoginPage class from login_page.dart
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: buttonGreen,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}