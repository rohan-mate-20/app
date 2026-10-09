import 'package:flutter/foundation.dart';
import '../models/store_model.dart';
import '../models/address_model.dart';
import '../models/delivery_settings_model.dart';
import '../models/delivery_slot_model.dart';
import '../services/store_service.dart';
import '../services/delivery_service.dart';
import '../services/address_service.dart';

class StoreDeliveryProvider with ChangeNotifier {
  final StoreService _storeService = StoreService();
  final DeliveryService _deliveryService = DeliveryService();
  final AddressService _addressService = AddressService();

  List<StoreModel> _stores = [];
  StoreModel? _activeStore;
  final double _userDistanceKm = 2.4;

  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;

  DeliverySettingsModel _deliverySettings = DeliverySettingsModel();
  List<DeliverySlotModel> _deliverySlots = DeliverySlotModel.defaultSlots;
  DeliverySlotModel? _selectedSlot;

  bool _isLoading = false;

  static final AddressModel defaultSampleAddress = AddressModel(
    id: 'addr_default_pune',
    customerId: 'guest_user',
    label: 'Home',
    fullName: 'Customer',
    phone: '9876543210',
    line1: 'A-302, Green Park Apartments',
    line2: 'Baner Road',
    city: 'Pune',
    state: 'Maharashtra',
    pincode: '411045',
    isDefault: true,
  );

  List<StoreModel> get stores => _stores;
  StoreModel? get activeStore => _activeStore;
  double get userDistanceKm => _userDistanceKm;
  List<AddressModel> get addresses => _addresses.isNotEmpty ? _addresses : [defaultSampleAddress];
  AddressModel? get selectedAddress => _selectedAddress ?? (_addresses.isNotEmpty ? _addresses.first : defaultSampleAddress);
  DeliverySettingsModel get deliverySettings => _deliverySettings;
  List<DeliverySlotModel> get deliverySlots => _deliverySlots;
  DeliverySlotModel? get selectedSlot => _selectedSlot ?? (_deliverySlots.isNotEmpty ? _deliverySlots.first : null);
  bool get isLoading => _isLoading;

  StoreDeliveryProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _storeService.fetchStores(),
        _deliveryService.fetchDeliverySettings(),
        _deliveryService.fetchDeliverySlots(),
      ]);

      _stores = results[0] as List<StoreModel>;
      if (_stores.isNotEmpty) {
        _activeStore = _stores.first;
      }

      _deliverySettings = results[1] as DeliverySettingsModel;
      _deliverySlots = results[2] as List<DeliverySlotModel>;
      if (_deliverySlots.isNotEmpty) {
        _selectedSlot = _deliverySlots.first;
      }
    } catch (e) {
      debugPrint('[StoreDeliveryProvider] loadInitialData error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCustomerAddresses(String customerId) async {
    if (customerId.isEmpty) return;
    try {
      final list = await _addressService.fetchAddresses(customerId);
      _addresses = list;
      if (list.isNotEmpty) {
        _selectedAddress = list.firstWhere(
          (a) => a.isDefault,
          orElse: () => list.first,
        );
      } else {
        // Create default Pune sample address if brand new user
        final defaultPune = AddressModel(
          id: 'addr_default_pune',
          customerId: customerId,
          label: 'Home',
          fullName: 'Customer',
          phone: '9876543210',
          line1: 'A-302, Green Park Apartments',
          line2: 'Baner Road',
          city: 'Pune',
          state: 'Maharashtra',
          pincode: '411045',
          isDefault: true,
        );
        _selectedAddress = defaultPune;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[StoreDeliveryProvider] loadCustomerAddresses error: $e');
    }
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void selectSlot(DeliverySlotModel slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void setActiveStore(StoreModel store) {
    _activeStore = store;
    notifyListeners();
  }

  Future<bool> saveAddress(AddressModel address) async {
    _isLoading = true;
    notifyListeners();

    AddressModel? saved;
    if (address.id.startsWith('addr_') || address.id.isEmpty) {
      saved = await _addressService.addAddress(address);
    } else {
      final ok = await _addressService.updateAddress(address);
      if (ok) saved = address;
    }

    if (saved != null) {
      final index = _addresses.indexWhere((a) => a.id == saved!.id);
      if (index >= 0) {
        _addresses[index] = saved;
      } else {
        _addresses.insert(0, saved);
      }
      _selectedAddress = saved;
    }

    _isLoading = false;
    notifyListeners();
    return saved != null;
  }

  Future<void> deleteAddress(String addressId) async {
    await _addressService.deleteAddress(addressId);
    _addresses.removeWhere((a) => a.id == addressId);
    if (_selectedAddress?.id == addressId) {
      _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
    }
    notifyListeners();
  }
}