import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/customer_model.dart';
import '../../models/delivery_slot_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/store_delivery_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/kmart_button.dart';
import '../../widgets/kmart_logo.dart';
import '../../widgets/need_help_faq_sheet.dart';
import '../location/location_selector_sheet.dart';
import '../orders/order_success_screen.dart';

class CheckoutFlowScreen extends StatefulWidget {
  const CheckoutFlowScreen({super.key});

  @override
  State<CheckoutFlowScreen> createState() => _CheckoutFlowScreenState();
}

class _CheckoutFlowScreenState extends State<CheckoutFlowScreen> {
  int _currentStep = 1; // 1: Details, 2: Delivery & Slot, 3: Review, 4: Payment

  // Step 1: User Profile fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  bool _whatsappOptIn = true;

  // Step 4: Payment method
  String _paymentMethod = 'ONLINE'; // 'ONLINE' (Razorpay) or 'COD'

  // Step 2: Selected slot date
  String? _selectedSlotDate;
  String _fulfillmentType = 'DELIVERY'; // 'DELIVERY' or 'PICKUP'

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final customer = authProvider.currentCustomer;
    final initialName = (customer?.name != null && customer!.name!.isNotEmpty && customer.name != 'Customer')
        ? customer.name!
        : '';
    _nameController = TextEditingController(text: initialName);
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _emailController = TextEditingController(text: customer?.email ?? '');
    _dobController = TextEditingController(text: customer?.dob ?? '');

    // Skip step 1 if authenticated user already has their name and phone
    if (authProvider.isLoggedIn && initialName.isNotEmpty && (customer?.phone.isNotEmpty == true)) {
      _currentStep = 2;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final ordersProvider = context.read<OrdersProvider>();
        final authCust = context.read<AuthProvider>().currentCustomer;
        if (authCust != null && ordersProvider.orders.isEmpty) {
          ordersProvider.loadOrders(authCust.id).then((_) {
            if (mounted) {
              context.read<CartProvider>().setCompletedDeliveriesCount(ordersProvider.completedDeliveriesCount);
            }
          });
        } else {
          context.read<CartProvider>().setCompletedDeliveriesCount(ordersProvider.completedDeliveriesCount);
        }

        final storeProv = context.read<StoreDeliveryProvider>();
        if (storeProv.deliverySlots.isNotEmpty) {
          final firstSlot = storeProv.deliverySlots.first;
          if (storeProv.selectedSlot == null ||
              !storeProv.deliverySlots.any((s) => s.id == storeProv.selectedSlot!.id)) {
            storeProv.selectSlot(firstSlot);
          }
          if (_selectedSlotDate == null) {
            setState(() {
              _selectedSlotDate = storeProv.selectedSlot?.slotDate ?? firstSlot.slotDate;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your full name'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return;
      }
      context.read<AuthProvider>().updateProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            dob: _dobController.text.trim(),
            whatsappOptIn: _whatsappOptIn,
          );
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      final storeProvider = context.read<StoreDeliveryProvider>();
      if (_fulfillmentType == 'DELIVERY' && storeProvider.selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select or add a delivery address'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      setState(() => _currentStep = 4);
    }
  }

  bool _isSlotValid(DeliverySlotModel slot) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allowedDates = List.generate(4, (i) {
      final d = today.add(Duration(days: i));
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
    if (!allowedDates.contains(slot.slotDate)) return false;
    if (slot.slotName.toLowerCase().contains('test') || slot.id.toLowerCase().contains('test')) return false;
    if (slot.slotDate == allowedDates.first) {
      final lower = slot.slotName.toLowerCase();
      if (lower.contains('morning') && now.hour >= 11) return false;
      if (lower.contains('evening') && now.hour >= 16) return false;
    }
    return true;
  }

  void _previousStep() {
    final authProvider = context.read<AuthProvider>();
    final customer = authProvider.currentCustomer;
    final hasExistingProfile = authProvider.isLoggedIn &&
        customer?.name != null &&
        customer!.name!.isNotEmpty &&
        customer.name != 'Customer';

    if (_currentStep > 2) {
      setState(() => _currentStep--);
    } else if (_currentStep == 2 && !hasExistingProfile) {
      setState(() => _currentStep = 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handlePlaceOrder() async {
    final authProvider = context.read<AuthProvider>();
    final storeProvider = context.read<StoreDeliveryProvider>();
    final cartProvider = context.read<CartProvider>();
    final ordersProvider = context.read<OrdersProvider>();

    if (cartProvider.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    final slot = storeProvider.selectedSlot;
    if (_fulfillmentType == 'DELIVERY') {
      if (slot == null || !_isSlotValid(slot)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The selected delivery slot is invalid or has expired. Please choose an upcoming slot.'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
        return;
      }
    }

    final address = storeProvider.selectedAddress ?? StoreDeliveryProvider.defaultSampleAddress;
    final authCust = authProvider.currentCustomer ?? CustomerModel(
      id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
      phone: address.phone.isNotEmpty ? address.phone : '9876543210',
      name: address.fullName.isNotEmpty ? address.fullName : 'Customer',
    );
    final isPickup = _fulfillmentType == 'PICKUP';
    final subtotal = cartProvider.itemTotal;
    final delFee = cartProvider.calculateDeliveryFee(isPickup: isPickup);
    final total = cartProvider.calculateGrandTotal(isPickup: isPickup);

    if (_paymentMethod == 'COD') {
      final order = await ordersProvider.placeCodOrder(
        customer: authCust,
        address: address,
        items: List.from(cartProvider.items),
        subtotal: subtotal,
        deliveryFee: delFee,
        total: total,
        orderType: _fulfillmentType,
        deliverySlotId: slot?.id,
        scheduledDeliveryDate: slot?.slotDate,
        deliverySlotTime: slot?.timeRange,
      );

      if (order != null && mounted) {
        final isPickup = _fulfillmentType == 'PICKUP';
        context.read<NotificationProvider>().addNotification(
          title: isPickup ? 'Self Pickup Order Confirmed! 🏪' : 'Order Placed Successfully! 🎉',
          body: isPickup
              ? 'Your pickup order #${order.orderNumber} for ${CurrencyFormatter.format(order.total)} has been confirmed. It will be packed at K MART store for collection!'
              : 'Your order #${order.orderNumber} for ${CurrencyFormatter.format(order.total)} has been confirmed. Doorstep delivery guaranteed!',
          orderId: order.id,
          type: 'order',
        );
        cartProvider.clearCart();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(order: order),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ordersProvider.errorMessage ?? 'Failed to place order. Please try again.'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } else {
      // Razorpay Online Flow
      await ordersProvider.placeRazorpayOrder(
        customer: authCust,
        address: address,
        items: List.from(cartProvider.items),
        subtotal: subtotal,
        deliveryFee: delFee,
        total: total,
        orderType: _fulfillmentType,
        deliverySlotId: slot?.id,
        scheduledDeliveryDate: slot?.slotDate,
        deliverySlotTime: slot?.timeRange,
        onSuccess: (OrderModel order) {
          if (mounted) {
            final isPickup = _fulfillmentType == 'PICKUP';
            context.read<NotificationProvider>().addNotification(
              title: isPickup ? 'Self Pickup Order Confirmed! 🏪' : 'Order Placed Successfully! 🎉',
              body: isPickup
                  ? 'Your pickup order #${order.orderNumber} for ${CurrencyFormatter.format(order.total)} has been paid and confirmed. It will be packed at K MART store for collection!'
                  : 'Your order #${order.orderNumber} for ${CurrencyFormatter.format(order.total)} has been paid and confirmed. Doorstep delivery guaranteed!',
              orderId: order.id,
              type: 'order',
            );
          }
          cartProvider.clearCart();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderSuccessScreen(order: order),
            ),
          );
        },
        onFailure: (String errorMsg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: AppColors.primaryRed,
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final storeProvider = context.watch<StoreDeliveryProvider>();
    final ordersProvider = context.watch<OrdersProvider>();

    final isPickup = _fulfillmentType == 'PICKUP';
    final totalAmount = cartProvider.calculateGrandTotal(isPickup: isPickup);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _previousStep,
        ),
        title: const KMartLogo(fontSize: 20, showTagline: false),
        centerTitle: true,
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
        child: Column(
          children: [
            // 4-Step Progress Indicator Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCheckoutStep(1, 'Details', _currentStep >= 1),
                  _buildStepLine(_currentStep > 1),
                  _buildCheckoutStep(2, 'Delivery', _currentStep >= 2),
                  _buildStepLine(_currentStep > 2),
                  _buildCheckoutStep(3, 'Review', _currentStep >= 3),
                  _buildStepLine(_currentStep > 3),
                  _buildCheckoutStep(4, 'Payment', _currentStep >= 4),
                ],
              ),
            ),
            const Divider(height: 1),

            // Step Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(cartProvider, storeProvider),
              ),
            ),

            // Fixed Bottom CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.cardBorder)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep == 4) ...[
                    Expanded(
                      child: KMartButton(
                        label: 'Continue to Pay ${CurrencyFormatter.format(totalAmount)}',
                        suffixIcon: Icons.arrow_forward_rounded,
                        isLoading: ordersProvider.isLoading,
                        onPressed: _handlePlaceOrder,
                      ),
                    ),
                  ] else if (_currentStep == 3) ...[
                    Expanded(
                      child: KMartButton(
                        label: 'Place Order',
                        suffixIcon: Icons.arrow_forward_rounded,
                        onPressed: _nextStep,
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: KMartButton(
                        label: 'Continue',
                        suffixIcon: Icons.arrow_forward_rounded,
                        onPressed: _nextStep,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(
    CartProvider cartProvider,
    StoreDeliveryProvider storeProvider,
  ) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Details();
      case 2:
        return _buildStep2DeliveryAndSlot(storeProvider);
      case 3:
        return _buildStep3Review(cartProvider, storeProvider);
      case 4:
        return _buildStep4Payment(cartProvider, storeProvider);
      default:
        return Container();
    }
  }

  // -------------------------------------------------------------
  // Step 1: Tell us about yourself (Page 7)
  // -------------------------------------------------------------
  Widget _buildStep1Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tell us about yourself',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryRed,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "We'll use this information to create your account and keep you updated about your orders.",
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.navyLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: AppColors.navyDark, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your information is safe with us. We only use it for order updates and a better shopping experience.',
                  style: TextStyle(fontSize: 12, color: AppColors.navyDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Full Name *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Mobile Number *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          enabled: false,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_outlined),
            suffixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Email Address (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Enter your email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Date of Birth (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _dobController,
          decoration: const InputDecoration(
            hintText: 'DD / MM / YYYY',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
        const SizedBox(height: 14),

        CheckboxListTile(
          value: _whatsappOptIn,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primaryRed,
          title: const Text(
            "I'd like to receive offers, discounts and updates on WhatsApp/SMS",
            style: TextStyle(fontSize: 13),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (val) => setState(() => _whatsappOptIn = val ?? true),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Step 2: Delivery Details & Slot (Page 8)
  // -------------------------------------------------------------
  Widget _buildStep2DeliveryAndSlot(StoreDeliveryProvider storeProvider) {
    final addresses = storeProvider.addresses;
    final selectedAddress = storeProvider.selectedAddress;
    final slots = storeProvider.deliverySlots;
    final selectedSlot = storeProvider.selectedSlot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fulfilment Method',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryRed,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'How would you like to receive your order?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _fulfillmentType = 'DELIVERY'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _fulfillmentType == 'DELIVERY' ? AppColors.primaryRedLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _fulfillmentType == 'DELIVERY' ? AppColors.primaryRed : AppColors.cardBorder,
                      width: _fulfillmentType == 'DELIVERY' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined, color: _fulfillmentType == 'DELIVERY' ? AppColors.primaryRed : AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Home Delivery',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _fulfillmentType == 'DELIVERY' ? AppColors.primaryRed : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _fulfillmentType = 'PICKUP'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _fulfillmentType == 'PICKUP' ? AppColors.primaryRedLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _fulfillmentType == 'PICKUP' ? AppColors.primaryRed : AppColors.cardBorder,
                      width: _fulfillmentType == 'PICKUP' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_outlined, color: _fulfillmentType == 'PICKUP' ? AppColors.primaryRed : AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Self Pickup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _fulfillmentType == 'PICKUP' ? AppColors.primaryRed : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_fulfillmentType == 'DELIVERY') ...[
          // Delivering To Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivering to',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDark,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add New Address'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.navyDark,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const LocationSelectorSheet(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),


        // Saved Addresses List
        if (addresses.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.home_outlined, color: AppColors.primaryRed),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Near K MART Store, Yashwant Nagar, Baramati - 413102',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // ignore: deprecated_member_use
                Radio<bool>(
                  value: true,
                  // ignore: deprecated_member_use
                  groupValue: true,
                  activeColor: AppColors.primaryRed,
                  // ignore: deprecated_member_use
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ] else ...[
          ...addresses.map((addr) {
            final isSelected = selectedAddress?.id == addr.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primaryRed : AppColors.cardBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    addr.label == 'Work' ? Icons.business_rounded : Icons.home_rounded,
                    color: isSelected ? AppColors.primaryRed : AppColors.navyDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addr.label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          addr.fullAddressString,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Radio<String>(
                    value: addr.id,
                    groupValue: selectedAddress?.id,
                    activeColor: AppColors.primaryRed,
                    onChanged: (_) => storeProvider.selectAddress(addr),
                  ),
                ],
              ),
            );
          }),
        ],
        ],

        if (_fulfillmentType == 'PICKUP') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryRedLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.store_mall_directory_outlined, color: AppColors.primaryRed),
                    SizedBox(width: 8),
                    Text(
                      'K MART Store',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '123 Supermarket Road, Main City Center',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Collect your items anytime between 10 AM and 8 PM.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Select Delivery/Pickup Time
        Text(
          _fulfillmentType == 'DELIVERY' ? 'Select Delivery Time' : 'Select Pickup Date',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _fulfillmentType == 'DELIVERY'
              ? 'Showing available slots for your address.'
              : 'Select when you plan to collect your order.',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),

        // Date Tabs + Slot Cards Grid (Strictly 4 calendar dates, test & expired slots removed)
        () {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final allowedDateStrings = List.generate(4, (i) {
            final d = today.add(Duration(days: i));
            return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          });

          // Only keep valid slots (no test slots, within 4 calendar dates, unexpired)
          final validSlots = slots.where(_isSlotValid).toList();

          final availableDates = allowedDateStrings.where((dStr) {
            return validSlots.any((s) => s.slotDate == dStr);
          }).toList();

          final activeDate = (_selectedSlotDate != null && availableDates.contains(_selectedSlotDate))
              ? _selectedSlotDate!
              : (selectedSlot != null && availableDates.contains(selectedSlot.slotDate))
                  ? selectedSlot.slotDate
                  : (availableDates.isNotEmpty ? availableDates.first : '');

          final dateSlots = validSlots.where((s) => s.slotDate == activeDate).toList();
          final Map<String, DeliverySlotModel> slotByName = {};
          for (final s in dateSlots) {
            if (!slotByName.containsKey(s.slotName)) {
              slotByName[s.slotName] = s;
            }
          }
          List<DeliverySlotModel> displaySlots = slotByName.values.toList();
          if (displaySlots.isEmpty && validSlots.isNotEmpty) {
            final Map<String, DeliverySlotModel> fallbackByName = {};
            for (final s in validSlots) {
              if (!fallbackByName.containsKey(s.slotName)) {
                fallbackByName[s.slotName] = s;
              }
            }
            displaySlots = fallbackByName.values.toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal Date Selector (Strictly 4 dates)
              if (availableDates.isNotEmpty) ...[
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableDates.length,
                    itemBuilder: (context, index) {
                      final dStr = availableDates[index];
                      final isSelected = activeDate == dStr;
                      DateTime? dt = DateTime.tryParse(dStr);
                      String label = dStr;
                      if (dt != null) {
                        final slotDay = DateTime(dt.year, dt.month, dt.day);
                        final diffDays = slotDay.difference(today).inDays;
                        if (diffDays == 0) {
                          label = 'Today';
                        } else if (diffDays == 1) {
                          label = 'Tomorrow';
                        } else if (diffDays == 2) {
                          const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          label = 'Day After (${weekdays[dt.weekday - 1]})';
                        } else {
                          const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          label = '${weekdays[dt.weekday - 1]}, ${dt.day}/${dt.month}';
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: AppColors.primaryRed,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedSlotDate = dStr);
                            final matchingSlots = validSlots.where((s) => s.slotDate == dStr).toList();
                            if (matchingSlots.isNotEmpty) {
                              storeProvider.selectSlot(matchingSlots.first);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Morning & Evening Slot Cards Grid
              Row(
                children: displaySlots.map((slot) {
                  final isSelected = selectedSlot?.id == slot.id;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => storeProvider.selectSlot(slot),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryRed : AppColors.cardBorder,
                            width: isSelected ? 1.8 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  slot.slotName == 'Morning'
                                      ? Icons.wb_sunny_outlined
                                      : Icons.nightlight_outlined,
                                  color: isSelected ? AppColors.primaryRed : AppColors.navyDark,
                                  size: 22,
                                ),
                                Radio<String>(
                                  value: slot.id,
                                  groupValue: selectedSlot?.id,
                                  activeColor: AppColors.primaryRed,
                                  onChanged: (_) => storeProvider.selectSlot(slot),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${slot.slotName} Slot',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              slot.timeRange,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (!slot.isAvailable) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.warningLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Fully Booked',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warningOrange,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }(),
      ],
    );
  }

  // -------------------------------------------------------------
  // Step 3: Order Review (Page 9)
  // -------------------------------------------------------------
  Widget _buildStep3Review(
    CartProvider cartProvider,
    StoreDeliveryProvider storeProvider,
  ) {
    final address = storeProvider.selectedAddress;
    final slot = storeProvider.selectedSlot;
    final delFee = cartProvider.calculateDeliveryFee(isPickup: _fulfillmentType == 'PICKUP');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Review',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryRed,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Please review your order details before placing it.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Items Summary Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items (${cartProvider.itemCount})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.navyDark,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Cart'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.navyDark,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...cartProvider.items.map((it) {
          final p = it.product;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: AppColors.background,
                    child: CachedNetworkImage(
                      imageUrl: p.imageUrl,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.shopping_bag),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        p.weightUnit,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Qty: ${it.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  CurrencyFormatter.format(it.lineTotal),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),

        // Delivery Address Snapshot
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: AppColors.primaryRed, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Delivery Address',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                address?.fullAddressString ??
                    'Near K MART Store, Yashwant Nagar, Baramati - 413102',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.navyDark, size: 18),
                  const SizedBox(width: 8),
                  () {
                    String dateLabel = 'Today';
                    if (slot != null && slot.slotDate.isNotEmpty) {
                      final dt = DateTime.tryParse(slot.slotDate);
                      if (dt != null) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final slotDay = DateTime(dt.year, dt.month, dt.day);
                        final diffDays = slotDay.difference(today).inDays;
                        if (diffDays == 0) {
                          dateLabel = 'Today';
                        } else if (diffDays == 1) {
                          dateLabel = 'Tomorrow';
                        } else {
                          const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          dateLabel = '${weekdays[dt.weekday - 1]}, ${dt.day}/${dt.month}';
                        }
                      }
                    }
                    return Text(
                      'Delivery Slot: $dateLabel, ${slot?.timeRange ?? '11:00 AM - 2:00 PM'}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    );
                  }(),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bill Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bill Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 10),
              _buildBillRow(
                'Item Total (${cartProvider.itemCount} items)',
                CurrencyFormatter.format(cartProvider.itemTotal),
              ),
              const SizedBox(height: 6),
              _buildBillRow(
                _fulfillmentType == 'PICKUP' ? 'Pickup Fee' : 'Delivery Fee',
                delFee == 0 ? 'FREE' : CurrencyFormatter.format(delFee),
                valueColor: delFee == 0 ? AppColors.successGreen : null,
              ),
              const SizedBox(height: 6),
              _buildBillRow(
                'Handling Fee',
                CurrencyFormatter.format(cartProvider.handlingFee),
              ),
              const SizedBox(height: 6),
              _buildBillRow(
                'Platform Fee',
                CurrencyFormatter.format(cartProvider.platformFee),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      cartProvider.calculateGrandTotal(isPickup: _fulfillmentType == 'PICKUP'),
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Step 4: Payment Method (Page 10)
  // -------------------------------------------------------------
  Widget _buildStep4Payment(
    CartProvider cartProvider,
    StoreDeliveryProvider storeProvider,
  ) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryRed,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose how you would like to pay for your order.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Razorpay Option Card
        GestureDetector(
          onTap: () => setState(() => _paymentMethod = 'ONLINE'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _paymentMethod == 'ONLINE'
                    ? AppColors.primaryRed
                    : AppColors.cardBorder,
                width: _paymentMethod == 'ONLINE' ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Radio<String>(
                      value: 'ONLINE',
                      groupValue: _paymentMethod,
                      activeColor: AppColors.primaryRed,
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Razorpay',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0C2340),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: AppColors.successGreen),
                          SizedBox(width: 4),
                          Text(
                            'Secure Payments',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 48),
                  child: Text(
                    'Pay easily using UPI, Cards, Wallets or Net Banking via Razorpay.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cash on Delivery Option Card
        GestureDetector(
          onTap: () => setState(() => _paymentMethod = 'COD'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _paymentMethod == 'COD'
                    ? AppColors.primaryRed
                    : AppColors.cardBorder,
                width: _paymentMethod == 'COD' ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<String>(
                  value: 'COD',
                  groupValue: _paymentMethod,
                  activeColor: AppColors.primaryRed,
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.payments_outlined, color: AppColors.navyDark),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cash on Delivery',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Pay when your order is delivered',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Order Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Text(
                    '${cartProvider.itemCount} items',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildBillRow(
                'Item Total',
                CurrencyFormatter.format(cartProvider.itemTotal),
              ),
              const SizedBox(height: 6),
              _buildBillRow(
                _fulfillmentType == 'PICKUP' ? 'Pickup Fee' : 'Delivery Fee',
                (_fulfillmentType == 'PICKUP' || cartProvider.calculateDeliveryFee(isPickup: _fulfillmentType == 'PICKUP') == 0)
                    ? 'FREE'
                    : CurrencyFormatter.format(cartProvider.calculateDeliveryFee(isPickup: _fulfillmentType == 'PICKUP')),
                valueColor: (_fulfillmentType == 'PICKUP' || cartProvider.calculateDeliveryFee(isPickup: _fulfillmentType == 'PICKUP') == 0)
                    ? AppColors.successGreen
                    : AppColors.textPrimary,
              ),
              const SizedBox(height: 6),
              _buildBillRow(
                'Handling Fee',
                CurrencyFormatter.format(cartProvider.handlingFee),
              ),
              const SizedBox(height: 6),
              _buildBillRow(
                'Platform Fee',
                CurrencyFormatter.format(cartProvider.platformFee),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      cartProvider.calculateGrandTotal(isPickup: _fulfillmentType == 'PICKUP'),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutStep(int stepNumber, String title, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primaryRed : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted && stepNumber < _currentStep
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isCompleted ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isCompleted ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Container(
      width: 36,
      height: 2,
      color: isCompleted ? AppColors.primaryRed : AppColors.divider,
      margin: const EdgeInsets.only(bottom: 14),
    );
  }

  Widget _buildBillRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

