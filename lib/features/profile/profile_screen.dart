import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../location/address_management_screen.dart';
import '../../widgets/need_help_faq_sheet.dart';
import '../auth/login_screen.dart';
import '../auth/set_password_screen.dart';
import '../legal/terms_and_privacy_screen.dart';
import '../../providers/orders_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_delivery_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/app_update_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final customer = authProvider.currentCustomer;
    final isLoggedIn = authProvider.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isLoggedIn
            ? Column(
                children: [
                  // User Header Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primaryRedLight,
                          child: Text(
                            (customer?.name != null && customer!.name!.isNotEmpty)
                                ? customer.name!.substring(0, 1).toUpperCase()
                                : 'K',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (customer?.name != null && customer!.name!.isNotEmpty) ? customer.name! : 'Customer',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customer?.phone.isNotEmpty == true ? '+91 ${customer!.phone}' : 'Verified K MART Member',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Quick Action Menu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.location_on_outlined,
                          title: 'Delivery Addresses',
                          subtitle: 'Manage saved addresses & locations',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddressManagementScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildMenuItem(
                          icon: Icons.headset_mic_outlined,
                          title: 'Help & Customer Support',
                          subtitle: 'FAQs, toll-free support & complaints',
                          onTap: () => NeedHelpFaqSheet.show(context),
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildMenuItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Change Password',
                          subtitle: 'Update your account login password',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SetPasswordScreen(
                                  isChangePassword: true,
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildMenuItem(
                          icon: Icons.system_update_rounded,
                          title: 'App Updates',
                          subtitle: 'Version ${AppUpdateService.currentVersion} • Check for Play Store updates',
                          onTap: () => AppUpdateService.showUpdatePrompt(context),
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildMenuItem(
                          icon: Icons.policy_outlined,
                          title: 'Terms & Privacy Policy',
                          subtitle: 'Terms of service, refund & privacy',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const TermsAndPrivacyScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout Option
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      subtitle: 'Sign out from this device',
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Log Out?'),
                            content: const Text(
                              'Are you sure you want to sign out from K MART?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  authProvider.signOut();
                                  context.read<OrdersProvider>().clearOrders();
                                  context.read<StoreDeliveryProvider>().clearAddresses();
                                  context.read<CartProvider>().clearCartOnLogout();
                                  context.read<NotificationProvider>().clearOnLogout();
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed,
                                ),
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.navyDark.withValues(alpha: 0.08),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 38,
                            color: AppColors.navyDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome to K MART',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Log in with your mobile number to view your profile, manage addresses, and track your orders.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text(
                              'Sign In with Mobile',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(isModal: true),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.navyDark).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.navyDark, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: iconColor ?? AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}