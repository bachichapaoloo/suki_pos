import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';

class CartCalculator {
  static TaxDiscountBreakdown calculate({
    required List<CartItem> items,
    double manualDiscountPercentage = 0.0,
    double manualDiscountFixed = 0.0,
    Discount? appliedDiscount,
  }) {
    double grossSubtotal = 0.0;
    double discountableGross = 0.0;

    for (final item in items) {
      final linePrice = item.totalPrice;
      grossSubtotal += linePrice;

      if (!item.item.isDiscountExempt) {
        discountableGross += linePrice;
      }
    }

    // 1. Check if the applied discount is Senior/PWD/Special VAT Exempt
    final isSpecialVatExempt = appliedDiscount?.isSpecialVatExempt ?? false;

    double discountAmount = 0.0;
    double vatableSales = 0.0;
    double vatAmount = 0.0;
    double vatExemptSales = 0.0;
    double netTotal = 0.0;

    if (isSpecialVatExempt) {
      // --- Case A: Senior / PWD 20% + VAT Exemption ---
      final percentage = appliedDiscount?.percentage ?? 20.0;

      // Strip 12% VAT from discountable items
      final netOfVatGross = discountableGross / 1.12;

      // Compute discount on net of VAT
      discountAmount = netOfVatGross * (percentage / 100);

      // Check cap if configured
      if (appliedDiscount?.capAmount != null && discountAmount > appliedDiscount!.capAmount!) {
        discountAmount = appliedDiscount!.capAmount!;
      }

      // Non-discountable items retain their normal VAT treatment
      final nonDiscountableGross = grossSubtotal - discountableGross;
      final nonDiscountableVatable = nonDiscountableGross / 1.12;
      final nonDiscountableVat = nonDiscountableGross - nonDiscountableVatable;

      vatExemptSales = netOfVatGross - discountAmount;
      vatableSales = nonDiscountableVatable;
      vatAmount = nonDiscountableVat;
      netTotal = vatExemptSales + nonDiscountableGross;
    } else {
      // --- Case B: Regular / Commercial Discount ---
      if (manualDiscountPercentage > 0) {
        discountAmount = discountableGross * (manualDiscountPercentage / 100);
      } else if (manualDiscountFixed > 0) {
        discountAmount = manualDiscountFixed > discountableGross ? discountableGross : manualDiscountFixed;
      }

      // Check cap if configured
      if (appliedDiscount?.capAmount != null && discountAmount > appliedDiscount!.capAmount!) {
        discountAmount = appliedDiscount!.capAmount!;
      }

      netTotal = grossSubtotal - discountAmount;

      // 12% Inclusive VAT breakdown on Net Total
      vatableSales = netTotal / 1.12;
      vatAmount = netTotal - vatableSales;
      vatExemptSales = 0.0;
    }

    return TaxDiscountBreakdown(
      grossSubtotal: grossSubtotal,
      manualDiscountAmount: discountAmount,
      vatableSales: vatableSales,
      vatAmount: vatAmount,
      vatExemptSales: vatExemptSales,
      zeroRatedSales: 0.0,
      netTotal: netTotal,
    );
  }
}
