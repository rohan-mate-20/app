import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/kmart_button.dart';
import '../../widgets/kmart_logo.dart';
import '../checkout/checkout_flow_screen.dart';
import '../../widgets/need_help_faq_sheet.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final bool isModal;
  final bool redirectToCheckout;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    this.isModal = false,
    this.redirectToCheckout = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  void _handleVerify() async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isOtpExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP has expired. Please tap Resend OTP to receive a new code.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    final otp = _enteredOtp;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the OTP'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    final success = await authProvider.verifyOtp(otp);

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
        // Pop OtpVerificationScreen, then replace LoginScreen with CheckoutFlowScreen
        // so back navigation from Checkout returns directly to Cart instead of showing Login.
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const CheckoutFlowScreen(),
          ),
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      final isExpired = authProvider.isOtpExpired;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isExpired
                ? 'OTP has expired. Please tap Resend OTP to receive a new code.'
                : 'Invalid OTP. Please check and try again.',
          ),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  void _handleResend() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.canResend || authProvider.isLoading) return;
    final sent = await authProvider.sendOtp(widget.phone);
    if (!mounted) return;
    if (sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new 6-digit OTP has been sent via SMS.'),
          backgroundColor: AppColors.navyDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => NeedHelpFaqSheet.show(context),
            child: const Text(
              'Need help?',
              style: TextStyle(
                color: AppColors.navyDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Center(child: KMartLogo(fontSize: 26)),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Verify Your Number',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(height: 8),

              // Phone number + Edit button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "We've sent a 6-digit OTP via SMS to\n+91 ${widget.phone}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.primaryRed,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 6 OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 54,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primaryRed,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_enteredOtp.length == 6) {
                          _handleVerify();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.navyDark),
                    SizedBox(width: 8),
                    Text(
                      'Test mode: enter any 6 digits (e.g. 123456) to verify',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // OTP Validity & Resend Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: authProvider.isOtpExpired
                      ? AppColors.primaryRedLight.withValues(alpha: 0.5)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: authProvider.isOtpExpired
                        ? AppColors.primaryRed.withValues(alpha: 0.3)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: authProvider.isOtpExpired
                              ? AppColors.primaryRed
                              : AppColors.navyDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          authProvider.isOtpExpired
                              ? 'OTP expired'
                              : 'OTP expires in ${authProvider.formattedCountdown}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: authProvider.isOtpExpired
                                ? AppColors.primaryRed
                                : AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                    if (authProvider.canResend)
                      TextButton(
                        onPressed: _handleResend,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Resend in ${authProvider.resendCooldown}s',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Verify OTP CTA
              KMartButton(
                label: 'Verify OTP',
                suffixIcon: Icons.arrow_forward_rounded,
                isLoading: authProvider.isLoading,
                onPressed: _handleVerify,
              ),
              const SizedBox(height: 20),

              // Trust note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 20,
                      color: AppColors.navyDark,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your number is safe with us. We only use it for verification and important updates.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3 Bottom Feature Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomBadge(
                    Icons.shopping_bag_outlined,
                    'Wide Range\nof Products',
                  ),
                  _buildBottomBadge(
                    Icons.check_circle_outline_rounded,
                    'Great Deals\nEveryday',
                  ),
                  _buildBottomBadge(
                    Icons.local_shipping_outlined,
                    'Delivered to\nYour Doorstep',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBadge(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.navyDark),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
