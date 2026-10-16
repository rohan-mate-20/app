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
  /// Strictly restricts selection to 4 calendar dates: Today, Tomorrow, Day after tomorrow, 3 days from today.
  /// Only shows future slots for today (omits 11-2 if past 11am; omits both if past 4pm).
  /// Adds future dates with both 11-2 and 4-7 slots.
  static List<DeliverySlotModel> getUpcomingSlots({int daysAhead = 4, DateTime? customNow}) {
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

  /// Sanitizes slots from database:
  /// 1. Removes test slots
  /// 2. Restricts to strictly the 4 calendar dates (Today + 3 upcoming days)
  /// 3. Removes expired time slots for Today
  static List<DeliverySlotModel> filterAndSanitizeSlots(
    List<DeliverySlotModel> rawSlots, {
    DateTime? customNow,
  }) {
    final now = customNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allowedDateStrings = List.generate(4, (i) {
      final d = today.add(Duration(days: i));
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }).toSet();

    final todayStr = allowedDateStrings.first;
    final List<DeliverySlotModel> filtered = [];

    for (final slot in rawSlots) {
      // Filter out test slots
      if (slot.slotName.toLowerCase().contains('test') || slot.id.toLowerCase().contains('test')) {
        continue;
      }
      // Restrict strictly to the 4 calendar days
      if (!allowedDateStrings.contains(slot.slotDate)) {
        continue;
      }
      // Remove passed slots for Today
      if (slot.slotDate == todayStr) {
        final nameLower = slot.slotName.toLowerCase();
        if (nameLower.contains('morning') && now.hour >= 11) {
          continue;
        }
        if (nameLower.contains('evening') && now.hour >= 16) {
          continue;
        }
      }
      filtered.add(slot);
    }

    // Merge defaults for any missing day in the 4-day window
    final defaults = getUpcomingSlots(daysAhead: 4, customNow: now);
    for (final defSlot in defaults) {
      final exists = filtered.any(
        (s) => s.slotDate == defSlot.slotDate && s.slotName.toLowerCase() == defSlot.slotName.toLowerCase(),
      );
      if (!exists) {
        filtered.add(defSlot);
      }
    }

    filtered.sort((a, b) {
      final c = a.slotDate.compareTo(b.slotDate);
      if (c != 0) return c;
      return a.slotName.compareTo(b.slotName);
    });

    return filtered;
  }

  static List<DeliverySlotModel> get defaultSlots => getUpcomingSlots();
}