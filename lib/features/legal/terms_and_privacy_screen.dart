import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  final int initialTabIndex;

  const TermsAndPrivacyScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Legal & Policies'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.primaryRed,
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Terms & Conditions'),
              Tab(text: 'Privacy Policy'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TermsContent(),
            _PrivacyContent(),
          ],
        ),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Last updated: October 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Divider(height: 24),
                _buildSection(
                  '1. Acceptance of Terms',
                  'By accessing or using the K MART website or mobile application, you agree to be bound by these Terms & Conditions. If you do not agree to any part of these terms, please do not use our services.',
                ),
                _buildSection(
                  '2. Use of the Platform',
                  '• You must be at least 18 years old or using the platform under adult supervision.\n'
                  '• You agree to provide accurate and complete information when placing an order.\n'
                  '• You are responsible for keeping your account credentials confidential.\n'
                  '• Misuse of the platform, including fraudulent orders, will result in account suspension.',
                ),
                _buildSection(
                  '3. Product Information',
                  'We strive to display product descriptions, images, and prices as accurately as possible. However, K MART does not warrant that product descriptions or other content is error-free. Prices and availability are subject to change without prior notice.',
                ),
                _buildSection(
                  '4. Orders & Payment',
                  '• Placing an order constitutes an offer to purchase. We reserve the right to accept or decline any order.\n'
                  '• Payment is currently accepted via Cash on Delivery (COD) and UPI/online payment as available.\n'
                  '• In the event of a payment failure, the order will not be confirmed.',
                ),
                _buildSection(
                  '5. Intellectual Property',
                  'All content on this platform — including logos, text, images, and software — is the property of K MART and is protected by applicable copyright and trademark laws.',
                ),
                _buildSection(
                  '6. Limitation of Liability',
                  'K MART shall not be liable for any indirect, incidental, or consequential damages arising from the use of our platform or products purchased through it.',
                ),
                _buildSection(
                  '7. Governing Law',
                  'These terms are governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in Baramati, Maharashtra.',
                ),
                _buildSection(
                  '8. Changes to Terms',
                  'We reserve the right to update these terms at any time. Continued use of the platform after changes are posted constitutes your acceptance of the revised terms.',
                ),
                _buildSection(
                  '9. Contact Us',
                  'For questions regarding these Terms & Conditions, contact us at:\n'
                  '• Email: support@kmart.com\n'
                  '• Phone: +91 99750 40003\n'
                  '• Location: Baramati, Maharashtra - 413102',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Last updated: October 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Divider(height: 24),
                _buildSection(
                  '1. Information We Collect',
                  'We collect personal information that you provide when registering, placing an order, or contacting us, including: name, phone number, delivery address, and email address (optional). We also collect device information and usage data automatically.',
                ),
                _buildSection(
                  '2. How We Use Your Information',
                  'We use your information to:\n'
                  '• Process and deliver your orders\n'
                  '• Send order confirmations and delivery updates via SMS/WhatsApp\n'
                  '• Improve our platform and customer service\n'
                  '• Prevent fraud and ensure security\n'
                  '• Comply with legal obligations',
                ),
                _buildSection(
                  '3. Sharing of Information',
                  'We do not sell your personal information. We may share your data with:\n'
                  '• Delivery partners to fulfill orders\n'
                  '• Payment gateways (e.g., Razorpay) to process transactions securely\n'
                  '• Law enforcement or regulatory authorities if required by law',
                ),
                _buildSection(
                  '4. Data Retention',
                  'We retain your order and account data for as long as necessary to provide our services and comply with statutory legal requirements.',
                ),
                _buildSection(
                  '5. Cookies & Tracking',
                  'Our website and app may use essential cookies and tracking technologies to maintain session state, cart contents, and enhance your user experience.',
                ),
                _buildSection(
                  '6. Data Security',
                  'We implement industry-standard security measures, including HTTPS encryption, Supabase Row-Level Security, and restricted access controls, to protect your personal information.',
                ),
                _buildSection(
                  '7. Your Rights',
                  'You may request access to, correction of, or deletion of your personal data by contacting us at support@kmart.com.',
                ),
                _buildSection(
                  '8. Contact Us',
                  'If you have any questions or concerns about this Privacy Policy, please reach out to:\n'
                  '• Email: support@kmart.com\n'
                  '• Phone: +91 99750 40003\n'
                  '• Address: K MART, Baramati, Maharashtra - 413102',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
