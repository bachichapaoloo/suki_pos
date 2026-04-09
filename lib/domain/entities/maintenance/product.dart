import 'package:equatable/equatable.dart';

/// Represents a product (item) in the system.
class Product extends Equatable {
  /// Creates a [Product].
  const Product({
    required this.id,
    required this.itemCode,
    required this.name,
    required this.printName,
    required this.categoryId,
    required this.departmentId,
    this.barcode,
    this.labelName,
    this.itemDetails,
    this.isLabelSameAsReceipt = true,
    this.unitId,
    this.costPrice = 0,
    this.markupPercentage,
    this.conversionQty = 1,
    this.assignedPrinter,
    this.displayImage,
    this.buttonIndex,
    this.minStockLevel = 0,
    this.maxStockLevel = 0,
    this.isDiscountExempt = false,
    this.isVatExempt = false,
    this.isCombo = false,
    this.isFinishedGood = false,
    this.isComposition = false,
    this.isRawMaterial = false,
    this.isGiftCheck = false,
    this.giftCheckId,
    this.discCapAmount = 0,
    this.discCapPercentage = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String? barcode;
  final String itemCode;
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
  final String? assignedPrinter;
  final String? displayImage;
  final int? buttonIndex;
  final double minStockLevel;
  final double maxStockLevel;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    barcode,
    itemCode,
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
    assignedPrinter,
    displayImage,
    buttonIndex,
    minStockLevel,
    maxStockLevel,
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
    createdAt,
    updatedAt,
  ];

  /// Creates a copy of this [Product] with the given fields replaced.
  Product copyWith({
    int? id,
    String? barcode,
    String? itemCode,
    String? name,
    String? printName,
    String? labelName,
    String? itemDetails,
    bool? isLabelSameAsReceipt,
    int? categoryId,
    int? departmentId,
    int? unitId,
    double? costPrice,
    double? markupPercentage,
    double? conversionQty,
    String? assignedPrinter,
    String? displayImage,
    int? buttonIndex,
    double? minStockLevel,
    double? maxStockLevel,
    bool? isDiscountExempt,
    bool? isVatExempt,
    bool? isCombo,
    bool? isFinishedGood,
    bool? isComposition,
    bool? isRawMaterial,
    bool? isGiftCheck,
    int? giftCheckId,
    double? discCapAmount,
    double? discCapPercentage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      itemCode: itemCode ?? this.itemCode,
      name: name ?? this.name,
      printName: printName ?? this.printName,
      labelName: labelName ?? this.labelName,
      itemDetails: itemDetails ?? this.itemDetails,
      isLabelSameAsReceipt: isLabelSameAsReceipt ?? this.isLabelSameAsReceipt,
      categoryId: categoryId ?? this.categoryId,
      departmentId: departmentId ?? this.departmentId,
      unitId: unitId ?? this.unitId,
      costPrice: costPrice ?? this.costPrice,
      markupPercentage: markupPercentage ?? this.markupPercentage,
      conversionQty: conversionQty ?? this.conversionQty,
      assignedPrinter: assignedPrinter ?? this.assignedPrinter,
      displayImage: displayImage ?? this.displayImage,
      buttonIndex: buttonIndex ?? this.buttonIndex,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      isDiscountExempt: isDiscountExempt ?? this.isDiscountExempt,
      isVatExempt: isVatExempt ?? this.isVatExempt,
      isCombo: isCombo ?? this.isCombo,
      isFinishedGood: isFinishedGood ?? this.isFinishedGood,
      isComposition: isComposition ?? this.isComposition,
      isRawMaterial: isRawMaterial ?? this.isRawMaterial,
      isGiftCheck: isGiftCheck ?? this.isGiftCheck,
      giftCheckId: giftCheckId ?? this.giftCheckId,
      discCapAmount: discCapAmount ?? this.discCapAmount,
      discCapPercentage: discCapPercentage ?? this.discCapPercentage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
