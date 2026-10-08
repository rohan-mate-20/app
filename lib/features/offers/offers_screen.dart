import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> offers = [
      {
        'title': 'Flat ₹50 OFF',
        'code': 'KMART50',
        'desc': 'Get ₹50 discount on your grocery order above ₹250.',
        'validity': 'Valid till 31st Oct',
        'discount': '₹50 OFF',
      },
      {
        'title': 'Welcome Offer 10%',
        'code': 'WELCOME10',
        'desc': 'Flat 10% instant discount across all fresh daily essentials.',
        'validity': 'For new shoppers',
        'discount': '10% OFF',
      },
      {
        'title': 'Free Doorstep Delivery',
        'code': 'FREEDEL',
        'desc': 'Enjoy free delivery with no minimum order value constraint.',
        'validity': 'Limited period offer',
        'discount': 'FREE DEL',
      },
      {
        'title': 'Bulk Savings Deal',
        'code': 'MEGA200',
        'desc': 'Save ₹200 on monthly pantry & staples orders above ₹2,000.',
        'validity': 'Valid every weekend',
        'discount': '₹200 OFF',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offers & Deals'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRedLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        offer['discount']!,
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      offer['validity']!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  offer['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer['desc']!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.confirmation_number_outlined,
                            size: 16,
                            color: AppColors.navyDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            offer['code']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              fontSize: 13,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Coupon code ${offer['code']} copied to clipboard!',
                            ),
                            backgroundColor: AppColors.navyDark,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('COPY CODE'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}