import 'package:equatable/equatable.dart';

class TaxDiscountBreakdown extends Equatable {
  final double grossSubtotal; // Undiscounted total
  final double itemDiscountAmount; // Sum of line-level discounts & free items
  final double manualDiscountAmount; // Order-level discount amount (e.g. Senior, PWD, Commercial)
  final double surchargeAmount; // Delivery or service charges
  final double vatableSales; // 12% vatable sales net of vat
  final double vatAmount; // 12% output vat
  final double vatExemptSales; // Senior / PWD / VAT-exempt item sales
  final double zeroRatedSales;
  final double nonVatSales;
  final double netTotal; // Final payable amount

  const TaxDiscountBreakdown({
    required this.grossSubtotal,
    this.itemDiscountAmount = 0.0,
    required this.manualDiscountAmount,
    this.surchargeAmount = 0.0,
    required this.vatableSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.zeroRatedSales,
    this.nonVatSales = 0.0,
    required this.netTotal,
  });

  double get totalDiscountAmount => manualDiscountAmount + itemDiscountAmount;
  double get subtotalAfterItemDiscount => grossSubtotal - itemDiscountAmount;

  @override
  List<Object?> get props => [
        grossSubtotal,
        itemDiscountAmount,
        manualDiscountAmount,
        surchargeAmount,
        vatableSales,
        vatAmount,
        vatExemptSales,
        zeroRatedSales,
        nonVatSales,
        netTotal,
      ];
}
