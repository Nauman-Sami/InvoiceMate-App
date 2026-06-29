import 'package:flutter/material.dart';

/// A professional gradient background with a faint app logo watermark.
/// Wrap a screen's body in this widget and set the Scaffold's
/// backgroundColor to transparent so the gradient shows through.
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showLogo;
  const AppBackground({super.key, required this.child, this.showLogo = true});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF1FF), // soft blue
            Color(0xFFF8FAFC), // near white
            Color(0xFFE6EEFF), // soft blue
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          if (showLogo)
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/splash/splash.png',
                    width: size.width * 0.78,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
