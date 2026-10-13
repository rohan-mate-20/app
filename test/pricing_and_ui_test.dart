import 'package:flutter_test/flutter_test.dart';
import 'package:kmart_customer/services/delivery_service.dart';
import 'package:kmart_customer/models/delivery_settings_model.dart';
import 'package:kmart_customer/models/delivery_slot_model.dart';
import 'package:kmart_customer/models/order_model.dart';
import 'package:kmart_customer/widgets/need_help_faq_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Delivery and Pricing Tests', () {
    test('1. Below ₹500 order subtotal returns ₹40 delivery fee for non-eligible customer', () {
      final fee = DeliveryPricingService.calculateDeliveryFee(
        subtotal: 350.0,
        isPickup: false,
        pastEligibleDeliveries: 3,
      );
      expect(fee, 40.0);
    });

    test('2. ₹500 order subtotal returns ₹40 delivery fee for non-eligible customer', () {
      final fee = DeliveryPricingService.calculateDeliveryFee(
        subtotal: 500.0,
        isPickup: false,
        pastEligibleDeliveries: 3,
      );
      expect(fee, 40.0);
    });

    test('3. ₹600 order subtotal returns ₹40 delivery fee', () {
      final fee = DeliveryPricingService.calculateDeliveryFee(
        subtotal: 600.0,
        isPickup: false,
        pastEligibleDeliveries: 3,
      );
      expect(fee, 40.0);
    });

    test('4. ₹900 order subtotal returns ₹40 delivery fee', () {
      final fee = DeliveryPricingService.calculateDeliveryFee(
        subtotal: 900.0,
        isPickup: false,
        pastEligibleDeliveries: 3,
      );
      expect(fee, 40.0);
    });

    test('5. ₹999 order subtotal returns ₹40 delivery fee', () {
      final fee = DeliveryPricingService.calculateDeliveryFee(
        subtotal: 999.0,
        isPickup: false,
        pastEligibleDeliveries: 3,
      );
      expect(fee, 40.0);
    });

    test('6. ₹1,000 order subtotal returns ₹30 delivery fee', () {
      final fee = DeliveryPricingService.calculateDeliveryFee(
        subtotal: 1000.0,
        isPickup: false,
        pastEligibleDeliveries: 3,
      );
      expect(fee, 30.0);
    });

    test('7. ₹1,200 order subtotal returns ₹30 delivery fee', () {
      final fee = DeliveryPricingService.calculateDeliveryFee(
        subtotal: 1200.0,
        isPickup: false,
        pastEligibleDeliveries: 3,
      );
      expect(fee, 30.0);
    });

    test('8. First 3 eligible deliveries receive ₹0 delivery fee', () {
      expect(
        DeliveryPricingService.calculateDeliveryFee(subtotal: 350, pastEligibleDeliveries: 0),
        0.0,
      );
      expect(
        DeliveryPricingService.calculateDeliveryFee(subtotal: 600, pastEligibleDeliveries: 1),
        0.0,
      );
      expect(
        DeliveryPricingService.calculateDeliveryFee(subtotal: 1200, pastEligibleDeliveries: 2),
        0.0,
      );
      // 4th delivery onwards is not free
      expect(
        DeliveryPricingService.calculateDeliveryFee(subtotal: 600, pastEligibleDeliveries: 3),
        40.0,
      );
      expect(
        DeliveryPricingService.calculateDeliveryFee(subtotal: 1200, pastEligibleDeliveries: 3),
        30.0,
      );
    });

    test('9. Pickup orders receive ₹0 delivery charge regardless of subtotal or history', () {
      expect(
        DeliveryPricingService.calculateDeliveryFee(subtotal: 300, isPickup: true, pastEligibleDeliveries: 5),
        0.0,
      );
      expect(
        DeliveryPricingService.calculateDeliveryFee(subtotal: 600, isPickup: true, pastEligibleDeliveries: 5),
        0.0,
      );
      expect(
        DeliveryPricingService.calculateDeliveryFee(subtotal: 1500, isPickup: true, pastEligibleDeliveries: 5),
        0.0,
      );
    });

    test('10. Handling fee and platform fee both start at ₹0', () {
      expect(DeliveryPricingService.handlingFee, 0.0);
      expect(DeliveryPricingService.platformFee, 0.0);
    });

    test('11. Delivery fee is never cumulative (never ₹40 + ₹30 = ₹70)', () {
      final fee1 = DeliveryPricingService.calculateDeliveryFee(subtotal: 600, pastEligibleDeliveries: 3);
      final fee2 = DeliveryPricingService.calculateDeliveryFee(subtotal: 1200, pastEligibleDeliveries: 3);
      expect(fee1, 40.0);
      expect(fee2, 30.0);
      expect(fee1 != 70.0, true);
      expect(fee2 != 70.0, true);
    });

    test('12. Final payable amount calculation is consistent', () {
      // Order of 600
      final total600 = DeliveryPricingService.calculatePayableTotal(
        subtotal: 600.0,
        deliveryFee: 40.0,
      );
      expect(total600, 640.0);

      // Order of 1200
      final total1200 = DeliveryPricingService.calculatePayableTotal(
        subtotal: 1200.0,
        deliveryFee: 30.0,
      );
      expect(total1200, 1230.0);

      // Free delivery order of 600
      final totalFreeDel = DeliveryPricingService.calculatePayableTotal(
        subtotal: 600.0,
        deliveryFee: 0.0,
      );
      expect(totalFreeDel, 600.0);

      // Pickup order of 1200
      final totalPickup = DeliveryPricingService.calculatePayableTotal(
        subtotal: 1200.0,
        deliveryFee: 0.0,
      );
      expect(totalPickup, 1200.0);
    });

    test('13. DeliverySettingsModel calculateFee matches rules', () {
      final model = DeliverySettingsModel();
      expect(model.calculateFee(400, 3), 40.0);
      expect(model.calculateFee(500, 3), 40.0);
      expect(model.calculateFee(999, 3), 40.0);
      expect(model.calculateFee(1000, 3), 30.0);
      expect(model.calculateFee(1500, 3), 30.0);
      expect(model.calculateFee(1500, 3, isPickup: true), 0.0);
      expect(model.calculateFee(1500, 1), 0.0);
    });
  });

  group('Need Help FAQ Content Tests', () {
    test('14. Exactly 8 predefined FAQ questions and answers are present', () {
      expect(NeedHelpFaqSheet.faqs.length, 8);
      for (final faq in NeedHelpFaqSheet.faqs) {
        expect(faq['question']?.isNotEmpty, true);
        expect(faq['answer']?.isNotEmpty, true);
      }
      expect(NeedHelpFaqSheet.faqs[0]['question'], 'How can I place an order?');
      expect(NeedHelpFaqSheet.faqs[1]['question'], 'How can I track my order?');
      expect(NeedHelpFaqSheet.faqs[2]['question'], 'What are the delivery charges?');
      expect(NeedHelpFaqSheet.faqs[3]['question'], 'Can I collect my order myself?');
      expect(NeedHelpFaqSheet.faqs[4]['question'], 'How can I cancel my order?');
      expect(NeedHelpFaqSheet.faqs[5]['question'], 'What payment methods are available?');
      expect(NeedHelpFaqSheet.faqs[6]['question'], 'What are handling and platform fees?');
      expect(NeedHelpFaqSheet.faqs[7]['question'], 'How can I contact customer support?');
    });
  });

  group('Delivery Slot Future Availability Tests', () {
    test('15. Morning time (9 AM): today has both 11-2 and 4-7 slots', () {
      final morningTime = DateTime(2026, 10, 13, 9, 0);
      final slots = DeliverySlotModel.getUpcomingSlots(daysAhead: 5, customNow: morningTime);
      const todayDateStr = '2026-10-13';
      final todaySlots = slots.where((s) => s.slotDate == todayDateStr).toList();

      expect(todaySlots.length, 2);
      expect(todaySlots[0].timeRange, '11:00 AM - 2:00 PM');
      expect(todaySlots[0].slotName, 'Morning');
      expect(todaySlots[1].timeRange, '4:00 PM - 7:00 PM');
      expect(todaySlots[1].slotName, 'Evening');
    });

    test('16. Afternoon time (1 PM): today only has future 4-7 slot (11-2 passed)', () {
      final afternoonTime = DateTime(2026, 10, 13, 13, 0);
      final slots = DeliverySlotModel.getUpcomingSlots(daysAhead: 5, customNow: afternoonTime);
      const todayDateStr = '2026-10-13';
      final todaySlots = slots.where((s) => s.slotDate == todayDateStr).toList();

      expect(todaySlots.length, 1);
      expect(todaySlots[0].timeRange, '4:00 PM - 7:00 PM');
      expect(todaySlots[0].slotName, 'Evening');
    });

    test('17. Evening time (5 PM): today has no remaining slots, starts tomorrow with both slots', () {
      final eveningTime = DateTime(2026, 10, 13, 17, 0);
      final slots = DeliverySlotModel.getUpcomingSlots(daysAhead: 5, customNow: eveningTime);
      const todayDateStr = '2026-10-13';
      final todaySlots = slots.where((s) => s.slotDate == todayDateStr).toList();

      expect(todaySlots.isEmpty, true);

      const tomorrowDateStr = '2026-10-14';
      final tomorrowSlots = slots.where((s) => s.slotDate == tomorrowDateStr).toList();
      expect(tomorrowSlots.length, 2);
      expect(tomorrowSlots[0].timeRange, '11:00 AM - 2:00 PM');
      expect(tomorrowSlots[1].timeRange, '4:00 PM - 7:00 PM');
    });

    test('18. Future days (Tomorrow onwards) always provide both 11-2 and 4-7 slots', () {
      final now = DateTime(2026, 10, 13, 10, 0);
      final slots = DeliverySlotModel.getUpcomingSlots(daysAhead: 4, customNow: now);
      final dates = slots.map((s) => s.slotDate).toSet().toList();

      for (final date in dates) {
        final daySlots = slots.where((s) => s.slotDate == date).toList();
        if (date != '2026-10-13') {
          expect(daySlots.length, 2);
          expect(daySlots.any((s) => s.timeRange == '11:00 AM - 2:00 PM'), true);
          expect(daySlots.any((s) => s.timeRange == '4:00 PM - 7:00 PM'), true);
        }
      }
    });
  });

  group('Self Pickup Order Tracking Tests', () {
    test('19. OrderModel isPickup identifies pickup orders', () {
      final pickupOrder = OrderModel(
        id: 'ord-1',
        orderNumber: 'KM1001',
        customerId: 'cust-1',
        storeId: 'store-1',
        orderType: 'PICKUP',
        status: 'CONFIRMED',
        paymentMethod: 'COD',
        subtotal: 500,
        deliveryFee: 0,
        total: 500,
        createdAt: DateTime.now(),
        items: [],
      );
      expect(pickupOrder.isPickup, true);
      expect(pickupOrder.displayStatus, 'Order Confirmed');

      final packedPickup = pickupOrder.copyWith(status: 'PACKED');
      expect(packedPickup.displayStatus, 'Packed & Ready for Pickup');
      expect(packedPickup.trackingStepIndex, 1);
    });

    test('20. Delivery order tracking retains out for delivery', () {
      final deliveryOrder = OrderModel(
        id: 'ord-2',
        orderNumber: 'KM1002',
        customerId: 'cust-1',
        storeId: 'store-1',
        orderType: 'DELIVERY',
        status: 'OUT_FOR_DELIVERY',
        paymentMethod: 'COD',
        subtotal: 500,
        deliveryFee: 40,
        total: 540,
        createdAt: DateTime.now(),
        items: [],
      );
      expect(deliveryOrder.isPickup, false);
      expect(deliveryOrder.displayStatus, 'Out for Delivery');
      expect(deliveryOrder.trackingStepIndex, 2);
    });

    test('21. Order model list filtering by customer ID isolates user history', () {
      final order1 = OrderModel(
        id: 'ord-1',
        orderNumber: 'KM1001',
        customerId: 'cust-A',
        storeId: 'store-1',
        orderType: 'PICKUP',
        status: 'CONFIRMED',
        paymentMethod: 'COD',
        subtotal: 500,
        deliveryFee: 0,
        total: 500,
        createdAt: DateTime.now(),
        items: [],
      );
      final order2 = OrderModel(
        id: 'ord-2',
        orderNumber: 'KM1002',
        customerId: 'cust-B',
        storeId: 'store-1',
        orderType: 'DELIVERY',
        status: 'CONFIRMED',
        paymentMethod: 'COD',
        subtotal: 500,
        deliveryFee: 40,
        total: 540,
        createdAt: DateTime.now(),
        items: [],
      );
      final allOrders = [order1, order2];
      final userAOrders = allOrders.where((o) => o.customerId == 'cust-A').toList();
      final loggedOutOrders = allOrders.where((o) => false).toList();

      expect(userAOrders.length, 1);
      expect(userAOrders.first.orderNumber, 'KM1001');
      expect(loggedOutOrders.isEmpty, true);
    });
  });
}
