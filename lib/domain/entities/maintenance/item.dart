import 'package:equatable/equatable.dart';
import 'package:suki_pos/data/models/maintenance/item_price_model.dart';
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

  final List<ItemPriceModel> prices;

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

  Item copyWith({
    int? id,
    String? itemCode,
    String? barcode,
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
    double? minStockLevel,
    double? maxStockLevel,
    String? assignedPrinter,
    String? displayImage,
    int? buttonIndex,
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
    List<ItemPriceModel>? prices,
  }) {
    return Item(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      barcode: barcode ?? this.barcode,
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
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      assignedPrinter: assignedPrinter ?? this.assignedPrinter,
      displayImage: displayImage ?? this.displayImage,
      buttonIndex: buttonIndex ?? this.buttonIndex,
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
      prices: prices ?? this.prices,
    );
  }

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
