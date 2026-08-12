import 'package:equatable/equatable.dart';

class TaxDiscountBreakdown extends Equatable {
  final double grossSubtotal;
  final double manualDiscountAmount;
  final double vatableSales;
  final double vatAmount;
  final double vatExemptSales;
  final double zeroRatedSales;
  final double netTotal;

  const TaxDiscountBreakdown({
    required this.grossSubtotal,
    required this.manualDiscountAmount,
    required this.vatableSales,
    required this.vatAmount,
    required this.vatExemptSales,
    required this.zeroRatedSales,
    required this.netTotal,
  });

  @override
  List<Object?> get props => [
    grossSubtotal,
    manualDiscountAmount,
    vatableSales,
    vatAmount,
    vatExemptSales,
    zeroRatedSales,
    netTotal,
  ];
}
