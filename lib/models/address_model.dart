class AddressModel {
  final String id;
  final String customerId;
  final String label; // "Home", "Work", "Other"
  final String fullName;
  final String phone;
  final String line1; // House / Flat / Building No.
  final String? line2; // Area / Locality / Landmark
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.customerId,
    this.label = 'Home',
    required this.fullName,
    required this.phone,
    required this.line1,
    this.line2,
    this.city = 'Pune',
    this.state = 'Maharashtra',
    required this.pincode,
    this.latitude = 18.5204,
    this.longitude = 73.8567,
    this.isDefault = false,
  });

  String get fullAddressString {
    final parts = [
      line1,
      if (line2 != null && line2!.trim().isNotEmpty) line2,
      '$city, $state - $pincode',
    ];
    return parts.join(', ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      label: json['label'] ?? 'Home',
      fullName: json['full_name'] ?? 'Customer',
      phone: json['phone'] ?? '',
      line1: json['line1'] ?? '',
      line2: json['line2'],
      city: json['city'] ?? 'Pune',
      state: json['state'] ?? 'Maharashtra',
      pincode: json['pincode'] ?? '411001',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 18.5204,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 73.8567,
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'label': label,
      'full_name': fullName,
      'phone': phone,
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    };
  }

  AddressModel copyWith({
    String? id,
    String? customerId,
    String? label,
    String? fullName,
    String? phone,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}