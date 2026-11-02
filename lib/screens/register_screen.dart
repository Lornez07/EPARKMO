import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';
import '../providers/parking_provider.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Single vehicle info for registration
  final _plateCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ParkingProvider>();
    provider.clearError();
    final ok = await provider.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      cars: [
        CarModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          plateNumber: _plateCtrl.text.trim().toUpperCase(),
          model: _modelCtrl.text.trim(),
          color: _colorCtrl.text.trim(),
        )
      ],
    );
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _plateCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppDecorations.backgroundGradient),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.page),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Create Account', style: AppTextStyles.displayMedium)
                        .animate()
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Register to use E-Park Mo',
                            style: AppTextStyles.bodyMedium)
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: AppSpacing.xxl),
                    Consumer<ParkingProvider>(
                      builder: (context, provider, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        child: Container(
                          decoration: AppDecorations.glassCard(
                              opacity: 0.08, borderRadius: 24),
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
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      border: Border.all(
                                          color:
                                              AppColors.error.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: AppColors.error, size: 16),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                            child: Text(provider.error!,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                        color:
                                                            AppColors.error))),
                                      ],
                                    ),
                                  ),
                                _field(
                                  controller: _nameCtrl,
                                  label: 'Full Name',
                                  icon: Icons.person_outline_rounded,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Name is required'
                                      : null,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _field(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      (v == null || !v.contains('@'))
                                          ? 'Enter a valid email'
                                          : null,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _field(
                                  controller: _passCtrl,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscure: _obscure,
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
                                  validator: (v) => (v == null || v.length < 6)
                                      ? 'Min 6 characters'
                                      : null,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _field(
                                  controller: _confirmCtrl,
                                  label: 'Confirm Password',
                                  icon: Icons.lock_outline,
                                  obscure: _obscureConfirm,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                  validator: (v) => v != _passCtrl.text
                                      ? 'Passwords do not match'
                                      : null,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                // --- Vehicle Information ---
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Primary Vehicle Info',
                                      style: AppTextStyles.headingSmall),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _field(
                                  controller: _plateCtrl,
                                  label: 'Plate Number',
                                  icon: Icons.pin_outlined,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Plate number is required'
                                      : null,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _field(
                                        controller: _modelCtrl,
                                        label: 'Car Model',
                                        icon: Icons.directions_car_outlined,
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                                ? 'Required'
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                    Expanded(
                                      child: _field(
                                        controller: _colorCtrl,
                                        label: 'Color',
                                        icon: Icons.color_lens_outlined,
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                                ? 'Required'
                                                : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        provider.isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md)),
                                    ),
                                    child: provider.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : Text('Register',
                                            style: AppTextStyles.labelLarge),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.2),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?',
                            style: AppTextStyles.bodyMedium),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Sign In',
                              style: AppTextStyles.primaryAccent),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
