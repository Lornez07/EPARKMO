import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We use the brand color as the solid background for 100% logo blending
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background glow orb top-right
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Background glow orb bottom-left
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    // Subtle shadow to add depth without showing edges
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.cover,
                  ),
                )
                    .animate()
                    .scale(
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.5, 0.5))
                    .fadeIn(duration: 500.ms),
                const SizedBox(height: 32),
                Text(
                  AppStrings.appName,
                  style: AppTextStyles.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                    letterSpacing: 2,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 8),
                Text(
                  'SMART PARKING SOLUTION',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 4,
                    fontSize: 10,
                  ),
                )
                    .animate(delay: 700.ms)
                    .fadeIn(duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
