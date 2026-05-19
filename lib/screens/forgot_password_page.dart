import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  
  bool _loading = false;
  bool _emailVerified = false;
  String? _error;

  Future<void> _verifyEmail() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = "Please enter your email");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Check if email exists in database
      final res = await http.get(
        Uri.parse("${ApiService.baseUrl}/users/verify-email?email=${_email.text.trim()}"),
        headers: {"Accept": "application/json"},
      );

      if (res.statusCode == 200) {
        setState(() {
          _emailVerified = true;
          _loading = false;
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _error = "Email not found in our system";
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Something went wrong. Please try again.";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Cannot connect to server. Is the backend running?";
        _loading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _error = "Passwords do not match");
      return;
    }

    if (_newPassword.text.length < 6) {
      setState(() => _error = "Password must be at least 6 characters");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/auth/reset-password"),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode({
          "email": _email.text.trim(),
          "new_password": _newPassword.text,
        }),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset successfully! Please login."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        final body = jsonDecode(res.body);
        setState(() {
          _error = body["detail"] ?? "Failed to reset password";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Cannot connect to server. Is the backend running?";
        _loading = false;
      });
    }
  }

  static const Color background = Color(0xFFF7DCA2);
  static const Color fieldFill = Color(0xFFFFFBF5);
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
          suffixIcon: suffix == null ? null : Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: suffix,
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
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
              // Back button
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 28),
                  alignment: Alignment.centerLeft,
                ),
              ),

              const SizedBox(height: 8),

              // Title
              const Center(
                child: Text(
                  'Reset Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Center(
                child: Text(
                  _emailVerified
                      ? 'Enter your new password'
                      : 'Enter your email to verify your account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Error message
              if (_error != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(
                      hint: 'Email',
                      ctrl: _email,
                      suffix: const Icon(Icons.mail_outline, color: Colors.grey),
                    ),

                    if (_emailVerified) ...[
                      _buildField(
                        hint: 'New Password',
                        ctrl: _newPassword,
                        obscure: true,
                        suffix: const Icon(Icons.lock_outline, color: Colors.grey),
                      ),
                      _buildField(
                        hint: 'Confirm Password',
                        ctrl: _confirmPassword,
                        obscure: true,
                        suffix: const Icon(Icons.lock_outline, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : (_emailVerified ? _resetPassword : _verifyEmail),
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
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text(
                    _loading
                        ? 'Please wait...'
                        : (_emailVerified ? 'Reset Password' : 'Verify Email'),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // Back to login
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text('Remember your password? ', style: TextStyle(color: Colors.black87)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
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
            ],
          ),
        ),
      ),
    );
  }
}
