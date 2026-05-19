import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const Color backgroundCream = Color(0xFFFEF9EE);
  static const Color circleYellow = Color(0xFFF7D77A);
  static const Color buttonGreen = Color(0xFF6F8574);

  bool _hoverLogin = false;
  bool _hoverSignup = false;

  Widget _hoverButton({
    required String label,
    required VoidCallback onPressed,
    required bool hovering,
    required ValueChanged<bool> onHoverChanged,
  }) {
    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, hovering ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, hovering ? 10 : 6),
              blurRadius: hovering ? 16 : 8,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(buttonGreen),
            foregroundColor: WidgetStateProperty.all(Colors.white),
            minimumSize: WidgetStateProperty.all(const Size(260, 50)),
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            elevation: WidgetStateProperty.resolveWith<double>(
              (states) {
                if (states.contains(WidgetState.pressed)) return 2;
                return hovering ? 12 : 6;
              },
            ),
            shadowColor: WidgetStateProperty.all(Colors.black45),
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundCream,
      body: Stack(
        children: [
          // decorative circles
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                color: circleYellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -100,
            child: Container(
              width: 420,
              height: 420,
              decoration: const BoxDecoration(
                color: circleYellow,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // main content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Welcome Lets\nGet Started',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Login button with hover & shadow
                  _hoverButton(
                    label: 'Login',
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
                    hovering: _hoverLogin,
                    onHoverChanged: (v) => setState(() => _hoverLogin = v),
                  ),

                  const SizedBox(height: 18),

                  // Sign up button with hover & shadow
                  _hoverButton(
                    label: 'Sign up',
                    onPressed: () => Navigator.of(context).pushNamed('/signup'),
                    hovering: _hoverSignup,
                    onHoverChanged: (v) => setState(() => _hoverSignup = v),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
