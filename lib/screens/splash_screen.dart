import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'user_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _rotationAnim;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _rotationAnim = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _animController.repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 4), () {
      // Replace this with your user setup check logic
      bool userIsSetup = true;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              userIsSetup ? const HomeScreen() : const UserSetupScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _glassIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(120),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(120),
            border:
                Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white,
            size: 80,
            shadows: [
              Shadow(
                blurRadius: 12,
                color: Colors.white54,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerText(String text, TextStyle style) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final shimmerPosition = _shimmerController.value * bounds.width;
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white,
                Colors.white.withOpacity(0.25),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1 - shimmerPosition / bounds.width * 2, 0),
              end: Alignment(1 + shimmerPosition / bounds.width * 2, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(text, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: AnimatedBuilder(
              animation: _rotationAnim,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnim.value,
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _glassIcon(),
                  const SizedBox(height: 40),
                  _shimmerText(
                    "ExSpencer",
                    const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.white54,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _shimmerText(
                    "Track. Save. Succeed.",
                    const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
