import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/kmart_button.dart';
import '../../widgets/kmart_logo.dart';
import '../checkout/checkout_flow_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isModal;
  final bool redirectToCheckout;

  const LoginScreen({
    super.key,
    this.isModal = false,
    this.redirectToCheckout = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordMode = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkInitialMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().isLoggedIn) {
        Navigator.of(context).pop();
      }
    });
  }

  void _checkInitialMode() async {
    final authProvider = context.read<AuthProvider>();
    final usedPassword = await authProvider.hasUsedPasswordBefore();
    final lastPhone = await authProvider.getLastLoginPhone();

    if (mounted) {
      setState(() {
        if (lastPhone != null && lastPhone.isNotEmpty) {
          _phoneController.text = lastPhone;
        }
        _isPasswordMode = usedPassword;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleContinueOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.sendOtp(phone);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: phone,
            isModal: widget.isModal,
            redirectToCheckout: widget.redirectToCheckout,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP. Please try again.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  void _handlePasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signInWithPassword(phone, password);
    if (!mounted) return;

    if (success) {
      final custId = authProvider.currentCustomer?.id;
      context.read<NotificationProvider>().loadForCustomer(custId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful! Welcome to K MART.'),
          backgroundColor: AppColors.successGreen,
        ),
      );

      if (widget.redirectToCheckout) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const CheckoutFlowScreen(),
          ),
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      final errorMsg = authProvider.authErrorMessage ?? 'Wrong mobile number or password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  void _handleForgotPassword() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your 10-digit mobile number to reset password.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendOtp(phone);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: phone,
            isModal: widget.isModal,
            redirectToCheckout: widget.redirectToCheckout,
            isForgotPassword: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP for password reset. Please try again.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Logo Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const KMartLogo(fontSize: 26),
                    if (widget.isModal || Navigator.of(context).canPop())
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 24, color: AppColors.navyDark),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Welcome Header
                const Text(
                  'Welcome to\nK MART',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navyDark,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fresh groceries. Daily essentials.\nHappier homes.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),

                // 3 Benefit Badges Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBenefitItem(Icons.inventory_2_outlined, 'Fresh\nProducts'),
                    _buildBenefitItem(Icons.percent_rounded, 'Great\nDeals'),
                    _buildBenefitItem(Icons.local_shipping_outlined, 'Delivered\nto Doorstep'),
                  ],
                ),
                const SizedBox(height: 20),

                // Grocery Hero Banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 170,
                    width: double.infinity,
                    color: AppColors.navyDark,
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -10,
                          top: -10,
                          child: CachedNetworkImage(
                            imageUrl: AppConstants.bannerFreshEssentials,
                            fit: BoxFit.cover,
                            width: 220,
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.primaryRed.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Good\nFood\nBrighter\nDays',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header based on Mode
                Text(
                  _isPasswordMode ? 'Sign In to Your Account' : 'Enter your mobile number',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPasswordMode
                      ? 'Sign in with your mobile number and password'
                      : "We'll send you a One Time Password (OTP)",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter mobile number',
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14),
                          ),
                          validator: Validators.validateIndianMobile,
                        ),
                      ),
                    ],
                  ),
                ),

                // Password Input Field (When in Password Mode)
                if (_isPasswordMode) ...[
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        if (val.trim().length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Submit Button
                KMartButton(
                  label: _isPasswordMode ? 'Sign In' : 'Continue',
                  suffixIcon: Icons.arrow_forward_rounded,
                  isLoading: authProvider.isLoading,
                  onPressed: _isPasswordMode ? _handlePasswordLogin : _handleContinueOtp,
                ),

                const SizedBox(height: 14),

                // Switch Mode Button (Password vs OTP)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isPasswordMode = !_isPasswordMode;
                        _passwordController.clear();
                      });
                    },
                    icon: Icon(
                      _isPasswordMode ? Icons.sms_outlined : Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.navyDark,
                    ),
                    label: Text(
                      _isPasswordMode ? 'Login with OTP instead' : 'Login with Password instead',
                      style: const TextStyle(
                        color: AppColors.navyDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Terms & Privacy Note
                const Center(
                  child: Text(
                    'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.navyLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: AppColors.navyDark),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
