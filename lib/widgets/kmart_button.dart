import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class KMartButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final bool isOutlined;
  final IconData? suffixIcon;
  final IconData? prefixIcon;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;

  const KMartButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.isOutlined = false,
    this.suffixIcon,
    this.prefixIcon,
    this.height = 52,
    this.borderRadius = 14,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ??
        (isOutlined ? Colors.transparent : AppColors.primaryRed);

    final buttonWidget = SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: isOutlined ? AppColors.primaryRed : Colors.white,
          disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          side: isOutlined
              ? const BorderSide(color: AppColors.primaryRed, width: 1.5)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefixIcon != null) ...[
                    Icon(prefixIcon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOutlined ? AppColors.primaryRed : Colors.white,
                    ),
                  ),
                  if (suffixIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(suffixIcon, size: 18),
                  ],
                ],
              ),
      ),
    );

    return buttonWidget;
  }
}