import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_delivery_provider.dart';
import '../../widgets/kmart_button.dart';
import '../../widgets/kmart_logo.dart';

class LocationSelectorSheet extends StatefulWidget {
  const LocationSelectorSheet({super.key});

  @override
  State<LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController(text: '411045');
  final TextEditingController _cityController = TextEditingController(text: 'Pune');
  final TextEditingController _stateController = TextEditingController(text: 'Maharashtra');
  String _selectedLabel = 'Home';
  bool _isDefault = true;

  @override
  void dispose() {
    _houseController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final house = _houseController.text.trim();
    final area = _areaController.text.trim();
    final pin = _pincodeController.text.trim();

    if (house.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter House/Flat/Building No.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    final authCust = context.read<AuthProvider>().currentCustomer;
    final storeProvider = context.read<StoreDeliveryProvider>();

    final newAddress = AddressModel(
      id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
      customerId: authCust?.id ?? '',
      label: _selectedLabel,
      fullName: authCust?.name ?? 'Customer',
      phone: authCust?.phone ?? '9876543210',
      line1: house,
      line2: area.isNotEmpty ? area : _landmarkController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: pin,
      latitude: 18.5204,
      longitude: 73.8567,
      isDefault: _isDefault,
    );

    await storeProvider.saveAddress(newAddress);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery address saved successfully!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreDeliveryProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const KMartLogo(fontSize: 20, showTagline: false),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stepper Pill Header (1 Location -> 2 Explore -> 3 Shop)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepCircle('1', 'Location', true),
                      _buildStepLine(),
                      _buildStepCircle('2', 'Explore', false),
                      _buildStepLine(),
                      _buildStepCircle('3', 'Shop', false),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Where should we deliver?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter your address to check product availability and delivery options.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Use my current location Button
                  InkWell(
                    onTap: () {
                      _houseController.text = '123, Green Park';
                      _areaController.text = 'Baner Road';
                      _pincodeController.text = '411045';
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Auto-detected location: Pune (Store 1: 2.4 km)'),
                          backgroundColor: AppColors.navyDark,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.navyLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            color: AppColors.navyDark,
                            size: 24,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Use my current location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                                Text(
                                  'Allow access to find nearest K MART store',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.navyDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Map visual card
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.map_rounded,
                            size: 64,
                            color: AppColors.navyDark.withOpacity(0.2),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: AppColors.primaryRed,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'K MART 2.4 km away',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '✓ Delivery available at your location',
                              style: TextStyle(
                                color: AppColors.successGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Manual Address Form Header
                  const Text(
                    'Or add address manually',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Address Type Tabs (Home, Work, Other)
                  Row(
                    children: ['Home', 'Work', 'Other'].map((label) {
                      final isSelected = _selectedLabel == label;
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
                          ),
                          onSelected: (_) => setState(() => _selectedLabel = label),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Form Fields
                  TextField(
                    controller: _houseController,
                    decoration: const InputDecoration(
                      hintText: 'House / Flat / Building No.',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      hintText: 'Area / Locality / Sector',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _landmarkController,
                          decoration: const InputDecoration(
                            hintText: 'Landmark (Optional)',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'PIN Code',
                            prefixIcon: Icon(Icons.pin_drop_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            hintText: 'City',
                            prefixIcon: Icon(Icons.apartment_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            hintText: 'State',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Save as default checkbox
                  CheckboxListTile(
                    value: _isDefault,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primaryRed,
                    title: const Text(
                      'Save as my default address',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) => setState(() => _isDefault = val ?? true),
                  ),
                  const SizedBox(height: 20),

                  // Save Address Button
                  KMartButton(
                    label: 'Save Address',
                    suffixIcon: Icons.arrow_forward_rounded,
                    isLoading: storeProvider.isLoading,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(String number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryRed : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
    );
  }
}