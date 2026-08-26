import 'package:equatable/equatable.dart';

class TransactionLineDetail extends Equatable {
  final int itemId;
  final String itemName;
  final String barcode;
  final int quantity;
  final double unitPrice;
  final double amount;
  final double lineDiscount;
  final bool isFreeItem;
  final List<String> selectedOptions;

  const TransactionLineDetail({
    required this.itemId,
    required this.itemName,
    required this.barcode,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.lineDiscount = 0.0,
    this.isFreeItem = false,
    this.selectedOptions = const [],
  });

  @override
  List<Object?> get props => [
    itemId,
    itemName,
    barcode,
    quantity,
    unitPrice,
    amount,
    lineDiscount,
    isFreeItem,
    selectedOptions,
  ];
}

class TransactionDetail extends Equatable {
  final int transactionId;
  final int salesOrderId;
  final String transactionNo;
  final double grossAmount;
  final double netAmount;
  final double cashTendered;
  final double changeGiven;
  final String paymentMethodName;
  final String cashierName;
  final String orderTypeName;
  final int guestCount;
  final int eligibleGuestCount;
  final String? discountName;
  final double itemDiscountAmount;
  final double orderDiscountAmount;
  final double vatableSales;
  final double vatAmount;
  final double vatExemptSales;
  final double zeroRatedSales;
  final String? beneficiaryName;
  final String? beneficiaryIdNo;
  final DateTime transactionDate;
  final List<TransactionLineDetail> lines;

  const TransactionDetail({
    required this.transactionId,
    required this.salesOrderId,
    required this.transactionNo,
    required this.grossAmount,
    required this.netAmount,
    required this.cashTendered,
    required this.changeGiven,
    required this.paymentMethodName,
    required this.cashierName,
    required this.orderTypeName,
    required this.guestCount,
    this.eligibleGuestCount = 0,
    this.discountName,
    this.itemDiscountAmount = 0.0,
    this.orderDiscountAmount = 0.0,
    this.vatableSales = 0.0,
    this.vatAmount = 0.0,
    this.vatExemptSales = 0.0,
    this.zeroRatedSales = 0.0,
    this.beneficiaryName,
    this.beneficiaryIdNo,
    required this.transactionDate,
    required this.lines,
  });

  @override
  List<Object?> get props => [
    transactionId,
    salesOrderId,
    transactionNo,
    grossAmount,
    netAmount,
    cashTendered,
    changeGiven,
    paymentMethodName,
    cashierName,
    orderTypeName,
    guestCount,
    eligibleGuestCount,
    discountName,
    itemDiscountAmount,
    orderDiscountAmount,
    vatableSales,
    vatAmount,
    vatExemptSales,
    zeroRatedSales,
    beneficiaryName,
    beneficiaryIdNo,
    transactionDate,
    lines,
  ];
}
