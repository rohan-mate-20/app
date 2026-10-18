import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class LocationResult {
  final bool isSuccess;
  final String? errorMessage;
  final double? latitude;
  final double? longitude;
  final String? house;
  final String? area;
  final String? city;
  final String? state;
  final String? pincode;
  final String? addressLine;

  const LocationResult({
    required this.isSuccess,
    this.errorMessage,
    this.latitude,
    this.longitude,
    this.house,
    this.area,
    this.city,
    this.state,
    this.pincode,
    this.addressLine,
  });

  factory LocationResult.success({
    required double latitude,
    required double longitude,
    String? house,
    String? area,
    String? city,
    String? state,
    String? pincode,
    String? addressLine,
  }) {
    return LocationResult(
      isSuccess: true,
      latitude: latitude,
      longitude: longitude,
      house: house,
      area: area,
      city: city,
      state: state,
      pincode: pincode,
      addressLine: addressLine,
    );
  }

  factory LocationResult.error(String message) {
    return LocationResult(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class LocationService {
  static const MethodChannel _channel = MethodChannel('kmart/location');

  /// Check whether location permissions are granted
  static Future<bool> checkPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('checkPermission');
      return res ?? false;
    } catch (e) {
      debugPrint('[LocationService] checkPermission error: $e');
      return false;
    }
  }

  /// Request runtime location permissions
  static Future<bool> requestPermission() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestPermission');
      return res ?? false;
    } catch (e) {
      debugPrint('[LocationService] requestPermission error: $e');
      return false;
    }
  }

  /// Check whether GPS or network location provider is enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('isLocationServiceEnabled');
      return res ?? false;
    } catch (e) {
      debugPrint('[LocationService] isLocationServiceEnabled error: $e');
      return false;
    }
  }

  /// Retrieve device current location and reverse geocode to readable address
  static Future<LocationResult> getCurrentLocation({Duration timeout = const Duration(seconds: 12)}) async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCurrentLocation').timeout(timeout);

      if (raw == null) {
        return LocationResult.error('Could not detect device location. Please enter your address manually.');
      }

      final lat = (raw['latitude'] as num?)?.toDouble();
      final lng = (raw['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        return LocationResult.error('Unable to retrieve valid GPS coordinates. Please enter your address manually.');
      }

      String? house = raw['house']?.toString();
      String? area = raw['area']?.toString();
      String? city = raw['city']?.toString();
      String? state = raw['state']?.toString();
      String? pincode = raw['pincode']?.toString();
      String? addressLine = raw['addressLine']?.toString();

      // If native geocoder did not provide city/area, attempt reverse geocoding fallback
      if (city == null || city.isEmpty || pincode == null || pincode.isEmpty) {
        final fallback = await reverseGeocodeCoordinates(lat, lng);
        if (fallback != null) {
          house ??= fallback['house'];
          area ??= fallback['area'];
          city ??= fallback['city'];
          state ??= fallback['state'];
          pincode ??= fallback['pincode'];
          addressLine ??= fallback['addressLine'];
        }
      }

      return LocationResult.success(
        latitude: lat,
        longitude: lng,
        house: house,
        area: area,
        city: city ?? 'Baramati',
        state: state ?? 'Maharashtra',
        pincode: pincode ?? '413102',
        addressLine: addressLine,
      );
    } on PlatformException catch (pe) {
      debugPrint('[LocationService] PlatformException: code=${pe.code}, message=${pe.message}');
      if (pe.code == 'PERMISSION_DENIED') {
        return LocationResult.error('Location permission was denied. Please allow location access to use your current location.');
      } else if (pe.code == 'LOCATION_SERVICES_DISABLED') {
        return LocationResult.error('Location services (GPS) are turned off. Please turn on GPS in your device settings.');
      } else if (pe.code == 'TIMEOUT') {
        return LocationResult.error('Location request timed out. Please check your GPS signal or enter address manually.');
      }
      return LocationResult.error(pe.message ?? 'Could not retrieve your location. Please enter your address manually.');
    } on TimeoutException {
      return LocationResult.error('Location request timed out. Please check your GPS signal or enter address manually.');
    } catch (e) {
      debugPrint('[LocationService] getCurrentLocation error: $e');
      return LocationResult.error('Could not retrieve current location. Please enter your address manually.');
    }
  }

  /// Reverse geocode coordinates using Google Maps Geocoding API with safe Nominatim fallback
  static Future<Map<String, String>?> reverseGeocodeCoordinates(double lat, double lng) async {
    // 1. Google Maps Geocoding API (Preferred high-precision)
    if (AppConstants.googleMapsApiKey.isNotEmpty) {
      try {
        final googleUri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${AppConstants.googleMapsApiKey}',
        );
        final response = await http.get(googleUri).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final status = data['status'] as String?;
          if (status == 'OK') {
            final results = data['results'] as List<dynamic>?;
            if (results != null && results.isNotEmpty) {
              final first = results.first as Map<String, dynamic>;
              final components = (first['address_components'] as List<dynamic>?) ?? [];
              String? house;
              String? road;
              String? sublocality;
              String? city;
              String? state;
              String? pincode;

              for (final comp in components) {
                final types = ((comp['types'] as List<dynamic>?) ?? []).cast<String>();
                final longName = comp['long_name']?.toString() ?? '';
                if (types.contains('street_number')) house = longName;
                if (types.contains('route')) road = longName;
                if (types.contains('sublocality') || types.contains('sublocality_level_1')) sublocality = longName;
                if (types.contains('locality')) city = longName;
                if (types.contains('administrative_area_level_1')) state = longName;
                if (types.contains('postal_code')) pincode = longName;
              }

              final areaParts = [road, sublocality].where((s) => s != null && s.isNotEmpty).toList();
              final area = areaParts.isNotEmpty ? areaParts.join(', ') : null;
              final formatted = first['formatted_address']?.toString();

              return {
                if (house != null && house.isNotEmpty) 'house': house,
                if (area != null && area.isNotEmpty) 'area': area,
                if (city != null && city.isNotEmpty) 'city': city,
                if (state != null && state.isNotEmpty) 'state': state,
                if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
                if (formatted != null && formatted.isNotEmpty) 'addressLine': formatted,
              };
            }
          }
        }
      } catch (e) {
        debugPrint('[LocationService] Google geocoding error: $e');
      }
    }

    // 2. OpenStreetMap Nominatim fallback
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'KMartCustomerEcommerce/1.0 (contact@kmart.in)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final house = address['house_number'] ?? address['building'] ?? address['amenity'];
          final road = address['road'] ?? address['neighbourhood'] ?? address['suburb'];
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'];
          final state = address['state'];
          final postCode = address['postcode'];
          final displayName = data['display_name'];

          return {
            if (house != null) 'house': house.toString(),
            if (road != null) 'area': road.toString(),
            if (city != null) 'city': city.toString(),
            if (state != null) 'state': state.toString(),
            if (postCode != null) 'pincode': postCode.toString(),
            if (displayName != null) 'addressLine': displayName.toString(),
          };
        }
      }
    } catch (e) {
      debugPrint('[LocationService] reverseGeocodeCoordinates fallback error: $e');
    }
    return null;
  }
}
