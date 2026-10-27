import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/kmart_button.dart';
import '../../widgets/kmart_logo.dart';
import '../checkout/checkout_flow_screen.dart';

class SetPasswordScreen extends StatefulWidget {
  final bool isForgotPassword;
  final bool isChangePassword;
  final bool redirectToCheckout;

  const SetPasswordScreen({
    super.key,
    this.isForgotPassword = false,
    this.isChangePassword = false,
    this.redirectToCheckout = false,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text.trim();
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.setPassword(password);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password saved successfully! You can now sign in with your password.'),
          backgroundColor: AppColors.successGreen,
        ),
      );

      if (widget.isChangePassword) {
        Navigator.of(context).pop();
      } else if (widget.redirectToCheckout) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const CheckoutFlowScreen(),
          ),
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.authErrorMessage ?? 'Failed to save password. Please try again.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  void _handleSkip() {
    if (widget.redirectToCheckout) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CheckoutFlowScreen(),
        ),
      );
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canSkip = !widget.isForgotPassword && !widget.isChangePassword;

    final title = widget.isChangePassword
        ? 'Change Password'
        : widget.isForgotPassword
            ? 'Set New Password'
            : 'Set a password for faster login';

    final subtitle = widget.isChangePassword
        ? 'Enter a new password for your K MART account (minimum 8 characters).'
        : 'Next time you sign in, simply enter your phone number and password without waiting for an SMS OTP.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isChangePassword || widget.isForgotPassword
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.navyDark),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: widget.isChangePassword || widget.isForgotPassword,
        title: const KMartLogo(fontSize: 22),
        actions: [
          if (canSkip)
            TextButton(
              onPressed: _handleSkip,
              child: const Text(
                'Maybe later',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRedLight.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 32,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navyDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // New Password Field
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Enter password (min 8 characters)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                    ),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 18),

                // Confirm Password Field
                const Text(
                  'Confirm Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Re-enter password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (val.trim() != _passwordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button
                KMartButton(
                  label: 'Save Password',
                  suffixIcon: Icons.check_circle_outline_rounded,
                  isLoading: authProvider.isLoading,
                  onPressed: _handleSubmit,
                ),

                if (canSkip) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: _handleSkip,
                      child: const Text(
                        'Maybe later',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
