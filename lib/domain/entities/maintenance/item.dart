import 'package:equatable/equatable.dart';
import 'item_price.dart';

class Item extends Equatable {
  final int? id;
  final String itemCode;
  final String? barcode;
  final String name;
  final String printName;
  final String? labelName;
  final String? itemDetails;
  final bool isLabelSameAsReceipt;

  final int categoryId;
  final int departmentId;
  final int? unitId;

  final double costPrice;
  final double? markupPercentage;
  final double conversionQty;
  final double minStockLevel;
  final double maxStockLevel;

  final String? assignedPrinter;
  final String? displayImage;
  final int? buttonIndex;

  // Boolean Flags
  final bool isDiscountExempt;
  final bool isVatExempt;
  final bool isCombo;
  final bool isFinishedGood;
  final bool isComposition;
  final bool isRawMaterial;
  final bool isGiftCheck;

  final int? giftCheckId;
  final double discCapAmount;
  final double discCapPercentage;
  final bool isActive;

  final List<ItemPrice> prices;

  const Item({
    this.id,
    required this.itemCode,
    this.barcode,
    required this.name,
    required this.printName,
    this.labelName,
    this.itemDetails,
    this.isLabelSameAsReceipt = true,
    required this.categoryId,
    required this.departmentId,
    this.unitId,
    required this.costPrice,
    this.markupPercentage,
    this.conversionQty = 1.0,
    this.minStockLevel = 0.0,
    this.maxStockLevel = 0.0,
    this.assignedPrinter,
    this.displayImage,
    this.buttonIndex,
    this.isDiscountExempt = false,
    this.isVatExempt = false,
    this.isCombo = false,
    this.isFinishedGood = false,
    this.isComposition = false,
    this.isRawMaterial = false,
    this.isGiftCheck = false,
    this.giftCheckId,
    this.discCapAmount = 0.0,
    this.discCapPercentage = 0.0,
    this.isActive = true,
    this.prices = const [],
  });

  @override
  List<Object?> get props => [
    id,
    itemCode,
    barcode,
    name,
    printName,
    labelName,
    itemDetails,
    isLabelSameAsReceipt,
    categoryId,
    departmentId,
    unitId,
    costPrice,
    markupPercentage,
    conversionQty,
    minStockLevel,
    maxStockLevel,
    assignedPrinter,
    displayImage,
    buttonIndex,
    isDiscountExempt,
    isVatExempt,
    isCombo,
    isFinishedGood,
    isComposition,
    isRawMaterial,
    isGiftCheck,
    giftCheckId,
    discCapAmount,
    discCapPercentage,
    isActive,
    prices,
  ];
}
