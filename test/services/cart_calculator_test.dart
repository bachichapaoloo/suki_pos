import 'package:flutter_test/flutter_test.dart';
import 'package:suki_pos/data/models/maintenance/item_price_model.dart';
import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/maintenance/item.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/services/cart_calculator.dart';

void main() {
  Item buildTestItem({
    int id = 1,
    String code = 'ITM-01',
    String name = 'Chicken Ramen',
    double price = 112.0,
    bool isVatExempt = false,
    bool isDiscountExempt = false,
  }) {
    return Item(
      id: id,
      itemCode: code,
      name: name,
      printName: name,
      categoryId: 1,
      departmentId: 1,
      costPrice: 50.0,
      isVatExempt: isVatExempt,
      isDiscountExempt: isDiscountExempt,
      prices: [
        ItemPriceModel(id: 1, priceLevel: 'default', price: price),
      ],
    );
  }

  group('CartCalculator Financial Engine Tests', () {
    test('computes standard 12% VAT-inclusive breakdown on regular items', () {
      final item = buildTestItem(price: 112.0);
      final cart = [
        CartItem(id: 'line-1', item: item, quantity: 2), // 224.00 gross
      ];

      final breakdown = CartCalculator.calculate(items: cart);

      expect(breakdown.grossSubtotal, closeTo(224.0, 0.001));
      expect(breakdown.vatableSales, closeTo(200.0, 0.001));
      expect(breakdown.vatAmount, closeTo(24.0, 0.001));
      expect(breakdown.vatExemptSales, closeTo(0.0, 0.001));
      expect(breakdown.netTotal, closeTo(224.0, 0.001));
    });

    test('computes Senior Citizen 20% discount + 12% VAT exemption for solo guest', () {
      final item = buildTestItem(price: 112.0); // Net of VAT = 100.00
      final cart = [CartItem(id: 'line-1', item: item, quantity: 1)];

      const seniorDiscount = Discount(
        id: 1,
        discountTypeId: 1,
        discountTypeCode: 'senior',
        discountTypeName: 'Senior Citizen',
        name: 'SC 20%',
        percentage: 20.0,
      );

      final breakdown = CartCalculator.calculate(
        items: cart,
        appliedDiscount: seniorDiscount,
        guestCount: 1,
        eligibleGuestCount: 1,
      );

      // 112 / 1.12 = 100.00 net of VAT; 20% discount = 20.00; net due = 80.00
      expect(breakdown.grossSubtotal, closeTo(112.0, 0.001));
      expect(breakdown.manualDiscountAmount, closeTo(20.0, 0.001));
      expect(breakdown.vatExemptSales, closeTo(80.0, 0.001));
      expect(breakdown.vatableSales, closeTo(0.0, 0.001));
      expect(breakdown.vatAmount, closeTo(0.0, 0.001));
      expect(breakdown.netTotal, closeTo(80.0, 0.001));
    });

    test('computes proportional Senior/PWD sharing when 1 of 2 guests is eligible', () {
      final item = buildTestItem(price: 224.0); // Total for 2 guests = 224.00
      final cart = [CartItem(id: 'line-1', item: item, quantity: 1)];

      const pwdDiscount = Discount(
        id: 2,
        discountTypeId: 2,
        discountTypeCode: 'pwd',
        discountTypeName: 'PWD',
        name: 'PWD 20%',
        percentage: 20.0,
      );

      final breakdown = CartCalculator.calculate(
        items: cart,
        appliedDiscount: pwdDiscount,
        guestCount: 2,
        eligibleGuestCount: 1,
      );

      // Half (112.0) is eligible -> 100 net of VAT - 20 discount = 80 VAT-exempt
      // Other half (112.0) is regular -> 100 VATable + 12 VAT = 112
      // Total net due = 80 + 112 = 192.00
      expect(breakdown.manualDiscountAmount, closeTo(20.0, 0.001));
      expect(breakdown.vatExemptSales, closeTo(80.0, 0.001));
      expect(breakdown.vatableSales, closeTo(100.0, 0.001));
      expect(breakdown.vatAmount, closeTo(12.0, 0.001));
      expect(breakdown.netTotal, closeTo(192.0, 0.001));
    });

    test('enforces discount capAmount on both statutory and regular discounts', () {
      final item = buildTestItem(price: 1000.0);
      final cart = [CartItem(id: 'line-1', item: item, quantity: 1)];

      const cappedPromo = Discount(
        id: 3,
        discountTypeId: 3,
        discountTypeCode: 'promo',
        name: '20% Promo (Max 100)',
        percentage: 20.0,
        capAmount: 100.0,
      );

      final breakdown = CartCalculator.calculate(
        items: cart,
        appliedDiscount: cappedPromo,
      );

      expect(breakdown.manualDiscountAmount, closeTo(100.0, 0.001));
      expect(breakdown.netTotal, closeTo(900.0, 0.001));
    });

    test('computes service charge before and after discount and honors waiver', () {
      final item = buildTestItem(price: 1000.0);
      final cart = [CartItem(id: 'line-1', item: item, quantity: 1)];

      // 10% discount + 10% service charge BEFORE discount -> SC = 100, Net = 1000 - 100 + 100 = 1000
      final beforeDisc = CartCalculator.calculate(
        items: cart,
        manualDiscountPercentage: 10.0,
        isServiceChargeActive: true,
        serviceChargeRate: 10.0,
        computeServiceChargeBeforeDiscount: true,
      );
      expect(beforeDisc.surchargeAmount, closeTo(100.0, 0.001));
      expect(beforeDisc.netTotal, closeTo(1000.0, 0.001));

      // 10% discount + 10% service charge AFTER discount -> SC = 90, Net = 900 + 90 = 990
      final afterDisc = CartCalculator.calculate(
        items: cart,
        manualDiscountPercentage: 10.0,
        isServiceChargeActive: true,
        serviceChargeRate: 10.0,
        computeServiceChargeBeforeDiscount: false,
      );
      expect(afterDisc.surchargeAmount, closeTo(90.0, 0.001));
      expect(afterDisc.netTotal, closeTo(990.0, 0.001));

      // Waived service charge -> SC = 0
      final waived = CartCalculator.calculate(
        items: cart,
        manualDiscountPercentage: 10.0,
        isServiceChargeActive: true,
        serviceChargeRate: 10.0,
        isServiceChargeWaived: true,
      );
      expect(waived.surchargeAmount, closeTo(0.0, 0.001));
      expect(waived.netTotal, closeTo(900.0, 0.001));
    });

    test('handles line-item discounts and free items accurately', () {
      final item = buildTestItem(price: 100.0);
      final cart = [
        CartItem(id: 'line-1', item: item, quantity: 1, isFreeItem: true),
        CartItem(id: 'line-2', item: item, quantity: 2, itemDiscountPercent: 25.0),
      ];

      final breakdown = CartCalculator.calculate(items: cart);

      // Gross = 100 + 200 = 300; Line discounts = 100 (free) + 50 (25% of 200) = 150
      expect(breakdown.grossSubtotal, closeTo(300.0, 0.001));
      expect(breakdown.itemDiscountAmount, closeTo(150.0, 0.001));
      expect(breakdown.netTotal, closeTo(150.0, 0.001));
    });
  });
}
