import 'package:flutter/material.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  static const Color backgroundCream = Color(0xFFFEF9EE);
  static const Color circleYellow = Color(0xFFF7D77A);
  static const Color buttonGreen = Color(0xFF6F8574);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundCream,
      body: Stack(
        children: [
          // top-right big yellow circle
          Positioned(
            top: -120,
            right: -60,
            child: Container(
              width: 460,
              height: 460,
              decoration: const BoxDecoration(
                color: circleYellow,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // bottom-left big yellow circle
          Positioned(
            bottom: -160,
            left: -120,
            child: Container(
              width: 520,
              height: 520,
              decoration: const BoxDecoration(
                color: circleYellow,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // center content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'WeEat',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '“Decide Together. Dine Better”',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/welcome'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 8,
                          shadowColor: Colors.black45,
                          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
