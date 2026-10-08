import 'dart:math';

class StoreModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double serviceRadiusKm;
  final String gofrugalAccountId;
  final bool active;

  StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.serviceRadiusKm,
    required this.gofrugalAccountId,
    required this.active,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'K MART Store',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 18.5204,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 73.8567,
      serviceRadiusKm: (json['service_radius_km'] as num?)?.toDouble() ?? 5.0,
      gofrugalAccountId: json['gofrugal_account_id'] ?? '',
      active: json['active'] ?? true,
    );
  }

  double calculateDistanceKm(double userLat, double userLng) {
    const earthRadiusKm = 6371.0;
    final lat1 = latitude * (pi / 180.0);
    final lat2 = userLat * (pi / 180.0);
    final deltaLat = (userLat - latitude) * (pi / 180.0);
    final deltaLng = (userLng - longitude) * (pi / 180.0);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }
}