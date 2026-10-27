import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_delivery_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/kmart_button.dart';
import '../../widgets/kmart_logo.dart';

class LocationSelectorSheet extends StatefulWidget {
  const LocationSelectorSheet({super.key});

  @override
  State<LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  late final TextEditingController _nameController;
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController(text: '413102');
  final TextEditingController _cityController = TextEditingController(text: 'Baramati');
  final TextEditingController _stateController = TextEditingController(text: 'Maharashtra');
  String _selectedLabel = 'Home';
  bool _isDefault = true;
  bool _isLocating = false;
  double _currentLat = 18.1508;
  double _currentLng = 74.5779;

  String _getMapTileUrl(double lat, double lng, {int zoom = 15}) {
    final n = 1 << zoom;
    final x = ((lng + 180.0) / 360.0 * n).floor().clamp(0, n - 1);
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 - (math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) / math.pi)) / 2.0 * n)
        .floor()
        .clamp(0, n - 1);
    return 'https://a.basemaps.cartocdn.com/rastertiles/voyager/$zoom/$x/$y@2x.png';
  }

  @override
  void initState() {
    super.initState();
    final authCust = context.read<AuthProvider>().currentCustomer;
    final initialName = (authCust?.name != null && authCust!.name!.isNotEmpty && authCust.name != 'Customer')
        ? authCust.name!
        : '';
    _nameController = TextEditingController(text: initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    final enteredName = _nameController.text.trim();

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

    if (enteredName.isNotEmpty && enteredName != 'Customer') {
      context.read<AuthProvider>().updateCustomerName(enteredName);
    }

    final resolvedName = enteredName.isNotEmpty
        ? enteredName
        : ((authCust?.name != null && authCust!.name!.isNotEmpty && authCust.name != 'Customer')
            ? authCust.name!
            : 'Customer');

    final newAddress = AddressModel(
      id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
      customerId: authCust?.id ?? '',
      label: _selectedLabel,
      fullName: resolvedName,
      phone: authCust?.phone ?? '9876543210',
      line1: house,
      line2: area.isNotEmpty ? area : _landmarkController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: pin,
      latitude: _currentLat,
      longitude: _currentLng,
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

  Future<void> _handleUseCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    final result = await LocationService.getCurrentLocation();

    if (!mounted) return;
    setState(() => _isLocating = false);

    if (result.isSuccess) {
      if (result.latitude != null && result.longitude != null) {
        _currentLat = result.latitude!;
        _currentLng = result.longitude!;
      }
      if (result.house != null && result.house!.isNotEmpty) {
        _houseController.text = result.house!;
      }
      if (result.area != null && result.area!.isNotEmpty) {
        _areaController.text = result.area!;
      }
      if (result.city != null && result.city!.isNotEmpty) {
        _cityController.text = result.city!;
      }
      if (result.state != null && result.state!.isNotEmpty) {
        _stateController.text = result.state!;
      }
      if (result.pincode != null && result.pincode!.isNotEmpty) {
        _pincodeController.text = result.pincode!;
      }
      setState(() {});

      final locationName = [result.area, result.city]
          .where((s) => s != null && s.isNotEmpty)
          .join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locationName.isNotEmpty
                ? 'Current location detected: $locationName'
                : 'Current location detected successfully.',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      // Show understandable error message without silently substituting default address
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Could not determine location. Please enter manually.'),
          backgroundColor: AppColors.primaryRed,
          duration: const Duration(seconds: 4),
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
                    onTap: _isLocating ? null : _handleUseCurrentLocation,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.navyLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          if (_isLocating)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.primaryRed,
                              ),
                            )
                          else
                            const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.navyDark,
                              size: 24,
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isLocating ? 'Detecting current location...' : 'Use my current location',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                                Text(
                                  _isLocating
                                      ? 'Fetching GPS coordinates & address details'
                                      : 'Tap to fetch your current delivery address',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isLocating)
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.navyDark,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Map visual card with Google Static Map & high-res tile fallback
                  Container(
                    height: 130,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl:
                                'https://maps.googleapis.com/maps/api/staticmap?center=$_currentLat,$_currentLng&zoom=15&size=600x260&scale=2&markers=color:red%7C$_currentLat,$_currentLng&key=${AppConstants.googleMapsApiKey}',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => CachedNetworkImage(
                              imageUrl: _getMapTileUrl(_currentLat, _currentLng),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFE8EDF5),
                                child: Center(
                                  child: Icon(
                                    Icons.map_rounded,
                                    size: 56,
                                    color: AppColors.navyDark.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFFE8EDF5),
                                child: Center(
                                  child: Icon(
                                    Icons.map_rounded,
                                    size: 56,
                                    color: AppColors.navyDark.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => CachedNetworkImage(
                              imageUrl: _getMapTileUrl(_currentLat, _currentLng),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFE8EDF5),
                              ),
                              errorWidget: (context, url, err) => Container(
                                color: const Color(0xFFE8EDF5),
                                child: Center(
                                  child: Icon(
                                    Icons.map_rounded,
                                    size: 56,
                                    color: AppColors.navyDark.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Central Location Pin Marker
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 36,
                                  color: AppColors.primaryRed,
                                ),
                                Container(
                                  width: 8,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Soft dark gradient overlay for tag contrast
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
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
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.store_mall_directory_rounded,
                                  color: AppColors.primaryRed,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'K MART Store • Baramati',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
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
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Customer / Receiver Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

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