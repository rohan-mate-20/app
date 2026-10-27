import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/platform_launcher_service.dart';

class NeedHelpFaqSheet extends StatelessWidget {
  const NeedHelpFaqSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NeedHelpFaqSheet(),
    );
  }

  static const List<Map<String, String>> faqs = [
    {
      'question': 'How can I place an order?',
      'answer':
          'Select your products, add them to your cart, choose delivery or pickup, confirm your details, select a payment method, and place your order.',
    },
    {
      'question': 'How can I track my order?',
      'answer':
          'Open the Orders or My Orders section to view your order status and available tracking information.',
    },
    {
      'question': 'What are the delivery charges?',
      'answer':
          'Delivery charges depend on your order value: Orders below ₹1,000 have a ₹40 delivery charge, while orders worth ₹1,000 or more have a ₹30 delivery charge. Store pickup orders are completely FREE.',
    },
    {
      'question': 'Can I collect my order myself?',
      'answer':
          'Yes, if pickup is available for your order and selected store. Choose Pickup during checkout. Delivery charges will not apply to pickup orders.',
    },
    {
      'question': 'What payment methods are available?',
      'answer':
          'You can use the payment methods currently supported by the app and displayed at checkout.',
    },
    {
      'question': 'What are handling and platform fees?',
      'answer':
          'Handling and platform fees are currently ₹0 each. If these fees change in the future, their amounts will be displayed in the order summary before you place an order.',
    },
    {
      'question': 'How can I contact customer support?',
      'answer':
          'Contact our customer support directly at +91 99750 40003.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRedLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.primaryRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Help?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.navyDark,
                          ),
                        ),
                        Text(
                          'Frequently Asked Questions & Support',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: faqs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        childrenPadding: const EdgeInsets.only(
                          left: 14,
                          right: 14,
                          bottom: 14,
                        ),
                        leading: CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.navyDark,
                          child: Text(
                            'Q${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          faq['question']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              faq['answer']!,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (faq['question']!.toLowerCase().contains('contact')) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => PlatformLauncherService.makePhoneCall('+919975040003'),
                                    icon: const Icon(Icons.call_rounded, size: 16),
                                    label: const Text('Call Us', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryRed,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => PlatformLauncherService.openSms('+919975040003', message: 'Hello K MART, I need support with my order.'),
                                    icon: const Icon(Icons.sms_rounded, size: 16),
                                    label: const Text('Send SMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.navyDark,
                                      side: const BorderSide(color: AppColors.navyDark),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
