class DeliverySlotModel {
  final String id;
  final String slotDate;
  final String slotName; // "Morning", "Evening"
  final String timeRange; // "8:00 AM - 12:00 PM"
  final String feeLabel; // "Free delivery"
  final bool isAvailable;

  DeliverySlotModel({
    required this.id,
    required this.slotDate,
    required this.slotName,
    required this.timeRange,
    this.feeLabel = 'Free delivery',
    this.isAvailable = true,
  });

  factory DeliverySlotModel.fromJson(Map<String, dynamic> json) {
    final startTime = (json['start_time'] as String?)?.substring(0, 5) ?? '08:00';
    final endTime = (json['end_time'] as String?)?.substring(0, 5) ?? '12:00';
    final capacity = (json['capacity'] as num?)?.toInt() ?? 100;
    final bookings = (json['current_bookings'] as num?)?.toInt() ?? 0;

    return DeliverySlotModel(
      id: json['id'] ?? 'slot-${json['slot_name'] ?? 'morning'}',
      slotDate: json['slot_date'] ?? DateTime.now().toIso8601String().split('T')[0],
      slotName: json['slot_name'] ?? 'Morning',
      timeRange: '$startTime - $endTime',
      feeLabel: 'Free delivery',
      isAvailable: (capacity - bookings) > 0,
    );
  }

  static List<DeliverySlotModel> get defaultSlots {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return [
      DeliverySlotModel(
        id: 'slot-morning',
        slotDate: today,
        slotName: 'Morning',
        timeRange: '8:00 AM - 12:00 PM',
        feeLabel: 'Free delivery',
        isAvailable: true,
      ),
      DeliverySlotModel(
        id: 'slot-evening',
        slotDate: today,
        slotName: 'Evening',
        timeRange: '4:00 PM - 8:00 PM',
        feeLabel: 'Free delivery',
        isAvailable: true,
      ),
    ];
  }
}