import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class KMartLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final bool isLight;

  const KMartLogo({
    super.key,
    this.fontSize = 28,
    this.showTagline = true,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'K',
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              'MART',
              style: TextStyle(
                color: isLight ? Colors.white : AppColors.navyDark,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        if (showTagline)
          Text(
            'Daily Essentials, Delivered',
            style: TextStyle(
              color: isLight ? Colors.white70 : AppColors.textSecondary,
              fontSize: fontSize * 0.35,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
      ],
    );
  }
}