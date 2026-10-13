class DeliverySlotModel {
  final String id;
  final String slotDate;
  final String slotName; // "Morning", "Evening"
  final String timeRange; // "8:00 AM - 12:00 PM"
  final String feeLabel;
  final bool isAvailable;

  DeliverySlotModel({
    required this.id,
    required this.slotDate,
    required this.slotName,
    required this.timeRange,
    this.feeLabel = '',
    this.isAvailable = true,
  });

  factory DeliverySlotModel.fromJson(Map<String, dynamic> json) {
    final startTime = (json['start_time'] as String?)?.substring(0, 5) ?? '11:00';
    final endTime = (json['end_time'] as String?)?.substring(0, 5) ?? '14:00';
    final capacity = (json['capacity'] as num?)?.toInt() ?? 100;
    final bookings = (json['current_bookings'] as num?)?.toInt() ?? 0;

    return DeliverySlotModel(
      id: json['id'] ?? 'slot-${json['slot_name'] ?? 'morning'}',
      slotDate: json['slot_date'] ?? DateTime.now().toIso8601String().split('T')[0],
      slotName: json['slot_name'] ?? 'Morning',
      timeRange: '$startTime - $endTime',
      feeLabel: '',
      isAvailable: (capacity - bookings) > 0,
    );
  }

  /// Returns upcoming delivery slots (11:00 AM - 2:00 PM and 4:00 PM - 7:00 PM).
  /// Only shows future slots for today (omits 11-2 if past 11am; omits both if past 4pm).
  /// Adds future dates (Tomorrow and upcoming days) with both 11-2 and 4-7 slots.
  static List<DeliverySlotModel> getUpcomingSlots({int daysAhead = 7, DateTime? customNow}) {
    final now = customNow ?? DateTime.now();
    final List<DeliverySlotModel> result = [];

    for (int i = 0; i < daysAhead; i++) {
      final date = now.add(Duration(days: i));
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (i == 0) {
        // Today: Show only future slots
        if (now.hour < 11) {
          result.add(DeliverySlotModel(
            id: 'slot-$dateStr-morning',
            slotDate: dateStr,
            slotName: 'Morning',
            timeRange: '11:00 AM - 2:00 PM',
            feeLabel: '',
            isAvailable: true,
          ));
        }
        if (now.hour < 16) {
          result.add(DeliverySlotModel(
            id: 'slot-$dateStr-evening',
            slotDate: dateStr,
            slotName: 'Evening',
            timeRange: '4:00 PM - 7:00 PM',
            feeLabel: '',
            isAvailable: true,
          ));
        }
      } else {
        // Future days: both slots are upcoming
        result.add(DeliverySlotModel(
          id: 'slot-$dateStr-morning',
          slotDate: dateStr,
          slotName: 'Morning',
          timeRange: '11:00 AM - 2:00 PM',
          feeLabel: '',
          isAvailable: true,
        ));
        result.add(DeliverySlotModel(
          id: 'slot-$dateStr-evening',
          slotDate: dateStr,
          slotName: 'Evening',
          timeRange: '4:00 PM - 7:00 PM',
          feeLabel: '',
          isAvailable: true,
        ));
      }
    }

    return result;
  }

  static List<DeliverySlotModel> get defaultSlots => getUpcomingSlots();
}