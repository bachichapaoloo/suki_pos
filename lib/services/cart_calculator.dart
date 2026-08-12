import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';

class CartCalculator {
  /// Computes gross amounts, 12% BIR VAT breakdown, and discount
  static TaxDiscountBreakdown calculate({
    required List<CartItem> items,
    double manualDiscountPercentage = 0.0,
    double manualDiscountFixed = 0.0,
  }) {
    double grossSubtotal = 0.0;
    double vatableGross = 0.0;
    double vatExemptSales = 0.0;

    for (final item in items) {
      final linePrice = item.totalPrice;
      grossSubtotal += linePrice;

      if (item.item.isVatExempt) {
        vatExemptSales += linePrice;
      } else {
        vatableGross += linePrice;
      }
    }

    // Manual Discount Computation
    double discountAmount = 0.0;
    if (manualDiscountPercentage > 0) {
      discountAmount = grossSubtotal * (manualDiscountPercentage / 100);
    } else if (manualDiscountFixed > 0) {
      discountAmount = manualDiscountFixed;
    }

    // Pro-rate discount across vatable and exempt portions
    final discountRatio = grossSubtotal > 0 ? (1 - (discountAmount / grossSubtotal)) : 1.0;
    final netVatableGross = vatableGross * discountRatio;

    // BIR 12% Inclusive VAT Formula
    final vatableSales = netVatableGross / 1.12;
    final vatAmount = netVatableGross - vatableSales;
    final netTotal = (grossSubtotal - discountAmount);

    return TaxDiscountBreakdown(
      grossSubtotal: grossSubtotal,
      manualDiscountAmount: discountAmount,
      vatableSales: vatableSales,
      vatAmount: vatAmount,
      vatExemptSales: vatExemptSales * discountRatio,
      zeroRatedSales: 0.0,
      netTotal: netTotal,
    );
  }
}
