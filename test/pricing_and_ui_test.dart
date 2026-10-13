import 'package:flutter_test/flutter_test.dart';
import 'package:kmart_customer/services/delivery_service.dart';
import 'package:kmart_customer/models/delivery_settings_model.dart';
import 'package:kmart_customer/widgets/need_help_faq_sheet.dart';

void main() {
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
}
