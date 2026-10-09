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
import '../../widgets/kmart_button.dart';
import '../../widgets/kmart_logo.dart';
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

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final customer = authProvider.currentCustomer;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _emailController = TextEditingController(text: customer?.email ?? '');
    _dobController = TextEditingController(text: customer?.dob ?? '');
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
      if (storeProvider.selectedAddress == null) {
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

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
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

    final address = storeProvider.selectedAddress ?? StoreDeliveryProvider.defaultSampleAddress;
    final authCust = authProvider.currentCustomer ?? CustomerModel(
      id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
      phone: address.phone.isNotEmpty ? address.phone : '9876543210',
      name: address.fullName.isNotEmpty ? address.fullName : 'Customer',
    );
    final settings = storeProvider.deliverySettings;
    final subtotal = cartProvider.itemTotal;
    final delFee = cartProvider.calculateDeliveryFee(settings);
    final total = cartProvider.calculateGrandTotal(settings);
    final slot = storeProvider.selectedSlot;

    if (_paymentMethod == 'COD') {
      final order = await ordersProvider.placeCodOrder(
        customer: authCust,
        address: address,
        items: List.from(cartProvider.items),
        subtotal: subtotal,
        deliveryFee: delFee,
        total: total,
        deliverySlotId: slot?.id,
        scheduledDeliveryDate: slot?.slotDate,
      );

      if (order != null && mounted) {
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
        deliverySlotId: slot?.id,
        scheduledDeliveryDate: slot?.slotDate,
        onSuccess: (OrderModel order) {
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

    final totalAmount = cartProvider.calculateGrandTotal(
      storeProvider.deliverySettings,
    );

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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('K MART Support: 1800-123-KMART')),
              );
            },
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
          'Delivery Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryRed,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose your delivery address and a convenient time slot.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

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
                        'A-302, Green Park Apartments, Baner Road, Pune - 411045',
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
        const SizedBox(height: 24),

        // Select Delivery Time
        const Text(
          'Select Delivery Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Showing available slots for your address.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),

        // Date Tabs + Slot Cards Grid
        () {
          final uniqueDates = slots.map((s) => s.slotDate).toSet().toList();
          uniqueDates.sort();

          final activeDate = _selectedSlotDate ??
              (selectedSlot?.slotDate ?? (uniqueDates.isNotEmpty ? uniqueDates.first : ''));

          final dateSlots = slots.where((s) => s.slotDate == activeDate).toList();
          final Map<String, DeliverySlotModel> slotByName = {};
          for (final s in dateSlots) {
            if (!slotByName.containsKey(s.slotName)) {
              slotByName[s.slotName] = s;
            }
          }
          List<DeliverySlotModel> displaySlots = slotByName.values.toList();
          if (displaySlots.isEmpty && slots.isNotEmpty) {
            final Map<String, DeliverySlotModel> fallbackByName = {};
            for (final s in slots) {
              if (!fallbackByName.containsKey(s.slotName)) {
                fallbackByName[s.slotName] = s;
              }
            }
            displaySlots = fallbackByName.values.toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal Date Selector
              if (uniqueDates.isNotEmpty) ...[
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: uniqueDates.length,
                    itemBuilder: (context, index) {
                      final dStr = uniqueDates[index];
                      final isSelected = activeDate == dStr;
                      DateTime? dt = DateTime.tryParse(dStr);
                      String label = dStr;
                      if (dt != null) {
                        final now = DateTime.now();
                        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
                          label = 'Today';
                        } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day + 1) {
                          label = 'Tomorrow';
                        } else {
                          label = '${dt.day}/${dt.month}';
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
                            final firstSlot = slots.firstWhere(
                              (s) => s.slotDate == dStr,
                              orElse: () => slots.first,
                            );
                            storeProvider.selectSlot(firstSlot);
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
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: slot.isAvailable ? AppColors.successLight : AppColors.warningLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                slot.isAvailable ? slot.feeLabel : 'Fully Booked',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: slot.isAvailable ? AppColors.successGreen : AppColors.warningOrange,
                                ),
                              ),
                            ),
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
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.navyLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.navyDark, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delivery slots are shown based on availability at your location.',
                  style: TextStyle(fontSize: 12, color: AppColors.navyDark),
                ),
              ),
            ],
          ),
        ),
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
    final settings = storeProvider.deliverySettings;
    final delFee = cartProvider.calculateDeliveryFee(settings);
    final totalAmount = cartProvider.calculateGrandTotal(settings);

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
                    'A-302, Green Park Apartments, Baner Road, Pune - 411045',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.navyDark, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Slot: Tomorrow, ${slot?.timeRange ?? '8:00 AM - 12:00 PM'}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
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
              if (cartProvider.totalSavings > 0) ...[
                const SizedBox(height: 6),
                _buildBillRow(
                  'Discount',
                  '-${CurrencyFormatter.format(cartProvider.totalSavings)}',
                  valueColor: AppColors.successGreen,
                ),
              ],
              const SizedBox(height: 6),
              _buildBillRow(
                'Delivery Fee',
                delFee == 0 ? 'FREE' : CurrencyFormatter.format(delFee),
                valueColor: delFee == 0 ? AppColors.successGreen : null,
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
                    CurrencyFormatter.format(totalAmount),
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
        const SizedBox(height: 14),

        // Savings badge
        if (cartProvider.totalSavings > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.successGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  "You're saving ${CurrencyFormatter.format(cartProvider.totalSavings)} on this order! Great choices!",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successGreen,
                  ),
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
    final settings = storeProvider.deliverySettings;
    final totalAmount = cartProvider.calculateGrandTotal(settings);

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
              if (cartProvider.totalSavings > 0) ...[
                const SizedBox(height: 6),
                _buildBillRow(
                  'Discount',
                  '-${CurrencyFormatter.format(cartProvider.totalSavings)}',
                  valueColor: AppColors.successGreen,
                ),
              ],
              const SizedBox(height: 6),
              _buildBillRow(
                'Delivery Fee',
                cartProvider.calculateDeliveryFee(settings) == 0 ? 'FREE' : '₹40',
                valueColor: AppColors.successGreen,
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
                    CurrencyFormatter.format(totalAmount),
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
        const SizedBox(height: 20),

        // Security assurance badges
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SecurityBadge(icon: Icons.lock_outline, label: 'Secure\nPayments'),
            _SecurityBadge(icon: Icons.shield_outlined, label: 'Powered by\nRazorpay'),
            _SecurityBadge(icon: Icons.verified_user_outlined, label: 'Trusted by\nMillions'),
          ],
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

class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SecurityBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.navyDark),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
