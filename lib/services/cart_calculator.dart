import 'package:suki_pos/domain/entities/maintenance/discount.dart';
import 'package:suki_pos/domain/entities/orders/cart_item.dart';
import 'package:suki_pos/domain/entities/orders/tax_discount_breakdown.dart';

class CartCalculator {
  static TaxDiscountBreakdown calculate({
    required List<CartItem> items,
    double manualDiscountPercentage = 0.0,
    double manualDiscountFixed = 0.0,
    Discount? appliedDiscount,
    int guestCount = 1,
    int eligibleGuestCount = 0,
    double surchargeAmount = 0.0,
  }) {
    double grossSubtotal = 0.0;
    double itemDiscountAmount = 0.0;
    double discountableGross = 0.0;
    double nonDiscountableGross = 0.0;
    double inherentlyVatExemptGross = 0.0;

    for (final item in items) {
      final undiscountedLine = item.totalPrice;
      final effectiveLine = item.effectiveTotalPrice;
      final lineDisc = item.totalLineDiscount;

      grossSubtotal += undiscountedLine;
      itemDiscountAmount += lineDisc;

      if (item.item.isVatExempt) {
        inherentlyVatExemptGross += effectiveLine;
      }

      // Check exemption from order-level discounts
      final isExemptFromOrderDiscount = item.isDiscountExempt || item.item.isDiscountExempt || item.isFreeItem;

      if (!isExemptFromOrderDiscount) {
        discountableGross += effectiveLine;
      } else {
        nonDiscountableGross += effectiveLine;
      }
    }

    // 1. Check if the applied discount is Senior/PWD/Special VAT Exempt
    final isSpecialVatExempt = appliedDiscount?.isSpecialVatExempt ?? false;

    double orderDiscountAmount = 0.0;
    double vatableSales = 0.0;
    double vatAmount = 0.0;
    double vatExemptSales = 0.0;
    double netTotal = 0.0;

    if (isSpecialVatExempt) {
      // --- Case A: Senior / PWD 20% + VAT Exemption ---
      final percentage = appliedDiscount?.percentage ?? 20.0;

      // If guest count > 1 and eligible guest count is specified, apply proportional sharing
      final safeGuestCount = guestCount > 0 ? guestCount : 1;
      double eligiblePortion = discountableGross;
      if (safeGuestCount > 1 && eligibleGuestCount > 0 && eligibleGuestCount < safeGuestCount) {
        final ratio = eligibleGuestCount / safeGuestCount;
        eligiblePortion = discountableGross * ratio;
        nonDiscountableGross += (discountableGross - eligiblePortion);
      }

      // Strip 12% VAT from discountable items
      final netOfVatGross = eligiblePortion / 1.12;

      // Compute discount on net of VAT
      orderDiscountAmount = netOfVatGross * (percentage / 100);

      // Check cap if configured
      if (appliedDiscount?.capAmount != null && orderDiscountAmount > appliedDiscount!.capAmount!) {
        orderDiscountAmount = appliedDiscount!.capAmount!;
      }

      // Non-discountable items retain their standard 12% VAT
      final nonDiscountableVatable = nonDiscountableGross / 1.12;
      final nonDiscountableVat = nonDiscountableGross - nonDiscountableVatable;

      vatExemptSales = (netOfVatGross - orderDiscountAmount) + inherentlyVatExemptGross;
      vatableSales = nonDiscountableVatable;
      vatAmount = nonDiscountableVat;
      netTotal = vatExemptSales + nonDiscountableGross + surchargeAmount;
    } else {
      // --- Case B: Regular / Commercial Discount ---
      if (appliedDiscount != null) {
        if (appliedDiscount.isPercentage && (appliedDiscount.percentage ?? 0) > 0) {
          orderDiscountAmount = discountableGross * (appliedDiscount.percentage! / 100);
        } else if ((appliedDiscount.fixedAmount ?? 0) > 0) {
          orderDiscountAmount = appliedDiscount.fixedAmount!;
        }
      } else if (manualDiscountPercentage > 0) {
        orderDiscountAmount = discountableGross * (manualDiscountPercentage / 100);
      } else if (manualDiscountFixed > 0) {
        orderDiscountAmount = manualDiscountFixed;
      }

      if (orderDiscountAmount > discountableGross) {
        orderDiscountAmount = discountableGross;
      }

      // Check cap if configured
      if (appliedDiscount?.capAmount != null && orderDiscountAmount > appliedDiscount!.capAmount!) {
        orderDiscountAmount = appliedDiscount!.capAmount!;
      }

      final subtotalAfterAllDiscounts = (grossSubtotal - itemDiscountAmount - orderDiscountAmount);
      netTotal = (subtotalAfterAllDiscounts > 0 ? subtotalAfterAllDiscounts : 0.0) + surchargeAmount;

      // 12% Inclusive VAT breakdown on Net Total
      if (inherentlyVatExemptGross > 0) {
        final vatablePortion = netTotal > inherentlyVatExemptGross ? (netTotal - inherentlyVatExemptGross) : 0.0;
        vatableSales = vatablePortion / 1.12;
        vatAmount = vatablePortion - vatableSales;
        vatExemptSales = inherentlyVatExemptGross;
      } else {
        vatableSales = netTotal / 1.12;
        vatAmount = netTotal - vatableSales;
        vatExemptSales = 0.0;
      }
    }

    return TaxDiscountBreakdown(
      grossSubtotal: grossSubtotal,
      itemDiscountAmount: itemDiscountAmount,
      manualDiscountAmount: orderDiscountAmount,
      surchargeAmount: surchargeAmount,
      vatableSales: vatableSales,
      vatAmount: vatAmount,
      vatExemptSales: vatExemptSales,
      zeroRatedSales: 0.0,
      nonVatSales: 0.0,
      netTotal: netTotal,
    );
  }
}
