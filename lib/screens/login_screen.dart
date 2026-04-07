import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/parking_provider.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  void _fillGuest() {
    _emailCtrl.text = AppStrings.guestEmail;
    _passCtrl.text = AppStrings.guestPass;
    setState(() {});
  }

  void _fillAdmin() {
    _emailCtrl.text = AppStrings.adminEmail;
    _passCtrl.text = AppStrings.adminPass;
    setState(() {});
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ParkingProvider>();
    provider.clearError();
    final ok = await provider.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppDecorations.backgroundGradient),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.07),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.appName,
                                style: AppTextStyles.headingMedium),
                            Text('Smart Parking System',
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
                    const SizedBox(height: 40),
                    Text('Welcome back', style: AppTextStyles.displayMedium)
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 500.ms),
                    const SizedBox(height: 6),
                    Text('Sign in to your account',
                            style: AppTextStyles.bodyMedium)
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 500.ms),
                    const SizedBox(height: 32),

                    // Login card
                    _buildLoginCard(context).animate(delay: 200.ms).fadeIn(
                        duration: 500.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 20),

                    // Demo credentials card
                    _buildDemoCard().animate(delay: 350.ms).fadeIn(
                        duration: 500.ms),

                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account?",
                            style: AppTextStyles.bodyMedium),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: Text('Register',
                              style: AppTextStyles.primaryAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (context, provider, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: AppDecorations.glassCard(opacity: 0.08, borderRadius: 24),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (provider.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(provider.error!,
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.error))),
                        ],
                      ),
                    ),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTextStyles.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon:
                          Icon(Icons.email_outlined, color: AppColors.textMuted),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Password is required' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Sign In', style: AppTextStyles.labelLarge),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDemoCard() {
    return Container(
      decoration: AppDecorations.glassCard(opacity: 0.06, borderRadius: 20),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Demo Credentials', style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _demoButton(
                  label: 'Guest',
                  email: AppStrings.guestEmail,
                  pass: AppStrings.guestPass,
                  icon: Icons.person_outline_rounded,
                  color: AppColors.available,
                  onTap: _fillGuest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _demoButton(
                  label: 'Admin',
                  email: AppStrings.adminEmail,
                  pass: AppStrings.adminPass,
                  icon: Icons.admin_panel_settings_outlined,
                  color: AppColors.primary,
                  onTap: _fillAdmin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _demoButton({
    required String label,
    required String email,
    required String pass,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.headingSmall.copyWith(color: color)),
            Text(email, style: AppTextStyles.bodySmall),
            Text(pass, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
