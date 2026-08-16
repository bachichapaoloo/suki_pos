import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';

class CartCalculator {
  /// Computes gross amounts, 12% BIR VAT breakdown, discount exemptions, and net total.
  static TaxDiscountBreakdown calculate({
    required List<CartItem> items,
    double manualDiscountPercentage = 0.0,
    double manualDiscountFixed = 0.0,
  }) {
    double grossSubtotal = 0.0;
    double discountableGross = 0.0;
    double vatableGross = 0.0;
    double vatExemptGross = 0.0;

    for (final item in items) {
      final linePrice = item.totalPrice;
      grossSubtotal += linePrice;

      if (!item.item.isDiscountExempt) {
        discountableGross += linePrice;
      }

      if (item.item.isVatExempt) {
        vatExemptGross += linePrice;
      } else {
        vatableGross += linePrice;
      }
    }

    // Manual Discount Computation (applies only to non-exempt items)
    double discountAmount = 0.0;
    if (manualDiscountPercentage > 0) {
      discountAmount = discountableGross * (manualDiscountPercentage / 100);
    } else if (manualDiscountFixed > 0) {
      discountAmount = manualDiscountFixed > discountableGross ? discountableGross : manualDiscountFixed;
    }

    // Pro-rate discount between vatable and exempt portions (if applicable)
    final discountRatio = grossSubtotal > 0 ? (1.0 - (discountAmount / grossSubtotal)) : 1.0;
    final netVatableGross = vatableGross * discountRatio;
    final netVatExemptSales = vatExemptGross * discountRatio;

    // BIR 12% Inclusive VAT Formula
    final vatableSales = netVatableGross / 1.12;
    final vatAmount = netVatableGross - vatableSales;
    final netTotal = grossSubtotal - discountAmount;

    return TaxDiscountBreakdown(
      grossSubtotal: grossSubtotal,
      manualDiscountAmount: discountAmount,
      vatableSales: vatableSales,
      vatAmount: vatAmount,
      vatExemptSales: netVatExemptSales,
      zeroRatedSales: 0.0,
      netTotal: netTotal,
    );
  }
}
