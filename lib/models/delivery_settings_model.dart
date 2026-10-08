class DeliverySettingsModel {
  final int id;
  final double minOrderValue;
  final double tier1MaxValue;
  final double tier1Fee;
  final double tier2Fee;
  final int freeDeliveryOrderCount;

  DeliverySettingsModel({
    this.id = 1,
    this.minOrderValue = 500,
    this.tier1MaxValue = 999,
    this.tier1Fee = 40,
    this.tier2Fee = 30,
    this.freeDeliveryOrderCount = 3,
  });

  factory DeliverySettingsModel.fromJson(Map<String, dynamic> json) {
    return DeliverySettingsModel(
      id: (json['id'] as num?)?.toInt() ?? 1,
      minOrderValue: (json['min_order_value'] as num?)?.toDouble() ?? 500.0,
      tier1MaxValue: (json['tier1_max_value'] as num?)?.toDouble() ?? 999.0,
      tier1Fee: (json['tier1_fee'] as num?)?.toDouble() ?? 40.0,
      tier2Fee: (json['tier2_fee'] as num?)?.toDouble() ?? 30.0,
      freeDeliveryOrderCount:
          (json['free_delivery_order_count'] as num?)?.toInt() ?? 3,
    );
  }

  double calculateFee(double subtotal, int pastOrderCount) {
    if (pastOrderCount < freeDeliveryOrderCount) {
      return 0.0;
    }
    if (subtotal >= 2000) {
      return 0.0;
    }
    if (subtotal <= tier1MaxValue) {
      return tier1Fee;
    }
    return tier2Fee;
  }
}