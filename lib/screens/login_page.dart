import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'forgot_password_page.dart';
import '../services/api_service.dart';
import '../services/session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _remember = false;

  bool _loading = false;

  static const Color background = Color(0xFFF7DCA2); // warm yellow
  static const Color fieldFill = Color(0xFFFFFBF5); // off-white
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
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(3, 6),
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
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: suffix,
                ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
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
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final api = ApiService();
      final res = await api.login(
        email: _email.text.trim(),
        password: _pass.text,
      );

      if (!mounted) return;

      final email = _email.text.trim();

      // ---- Read what backend returned (support multiple key names) ----
      final firstName = (res["first_name"] ?? res["firstName"] ?? "").toString();
      final lastName = (res["last_name"] ?? res["lastName"] ?? "").toString();

      // Some backends return id as "_id" or "id"
      final userId = (res["_id"] ?? res["id"] ?? res["user_id"] ?? "").toString();

      // Username/tag system (if backend returns them)
      final username = (res["username"] ?? "").toString();
      final tag = (res["tag"] ?? res["discriminator"] ?? "").toString();

      // Fallback display name
      String displayName = firstName.isNotEmpty
          ? firstName
          : email.split('@').first;

      // Handle example: "shadow_slayer#7512"
      String handle = "";
      if (username.isNotEmpty && tag.isNotEmpty) {
        handle = "$username#$tag";
      } else if (displayName.isNotEmpty && tag.isNotEmpty) {
        handle = "$displayName#$tag";
      }

      // ---- Save into Session ----
      Session.email = email;
      Session.userId = userId;
      Session.firstName = firstName;
      Session.lastName = lastName;
      Session.displayName = displayName;
      Session.username = username;
      Session.tag = tag;
      Session.handle = handle;

      // (Optional) if backend sends avatar
      Session.avatarUrl = (res["avatarUrl"] ?? res["avatar_url"] ?? "").toString();

      await Session.save();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(name: displayName)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Login',
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

              Form(
                key: _formKey,
                child: Column(
                  children: [
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
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Checkbox(
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Remember me?',
                        style: TextStyle(color: Colors.black87)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: _loading ? null : _onSignIn,
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
                  child: Text(_loading ? 'Signing in...' : 'Sign-in'),
                ),
              ),

              const SizedBox(height: 26),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: const [
                    Expanded(
                        child: Divider(color: Colors.black26, thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Or', style: TextStyle(color: Colors.black54)),
                    ),
                    Expanded(
                        child: Divider(color: Colors.black26, thickness: 1)),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignupPage()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
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