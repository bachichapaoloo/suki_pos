import 'package:equatable/equatable.dart';

/// Represents a single tender payment or one leg of a multi-tender Split Payment
/// matching KwikPOS Lite's tender models (`cash_trans`, `card_trans`, `atm_trans`,
/// `bank_check_trans`, `gift_check_trans`, `charge_trans`).
class TenderPaymentLeg extends Equatable {
  final int paymentMethodId;
  final String paymentMethodCode; // 'cash', 'card', 'atm', 'bank_check', 'gift_check', 'charge'
  final String paymentMethodName;

  /// Net amount applied toward the transaction's total due.
  final double amount;

  /// Physical cash tendered or check/GC face value tendered.
  final double cashTendered;

  /// Physical cash change returned to the customer (only > 0 for cash).
  final double changeGiven;

  /// Non-refundable excess amount when Check or Gift Check face value > applied amount.
  final double excessAmount;

  /// Face value / cashless amount for Card, ATM, Check, Gift Check, or Charge.
  final double? cashlessAmount;

  // Card / ATM / Bank Check metadata
  final int? bankId;
  final String? bankName;
  final int? cardType; // 1 = Debit, 2 = Credit, 3 = E-Wallet / ATM
  final String? cardNumber;
  final String? cardExpiry;
  final String? approvalNumber;
  final String? referenceNumber; // Check No, ATM Ref, Charge Ref, Trace No
  final String? merchantTerminal;
  final String? paymentChannel;

  // Gift Check metadata
  final int? giftCheckId;
  final String? giftCheckName;
  final int? giftCheckQty;
  final String? serialNumbers;

  // Charge Account metadata
  final int? chargeAccountId;
  final String? chargeAccountName;

  // Customer / Payor metadata
  final String? customerName;
  final String? customerAddress;
  final String? customerTin;

  const TenderPaymentLeg({
    required this.paymentMethodId,
    required this.paymentMethodCode,
    required this.paymentMethodName,
    required this.amount,
    required this.cashTendered,
    this.changeGiven = 0.0,
    this.excessAmount = 0.0,
    this.cashlessAmount,
    this.bankId,
    this.bankName,
    this.cardType,
    this.cardNumber,
    this.cardExpiry,
    this.approvalNumber,
    this.referenceNumber,
    this.merchantTerminal,
    this.paymentChannel,
    this.giftCheckId,
    this.giftCheckName,
    this.giftCheckQty,
    this.serialNumbers,
    this.chargeAccountId,
    this.chargeAccountName,
    this.customerName,
    this.customerAddress,
    this.customerTin,
  });

  bool get isCash => paymentMethodCode.toLowerCase() == 'cash';
  bool get isCard => paymentMethodCode.toLowerCase() == 'card';
  bool get isAtm =>
      paymentMethodCode.toLowerCase() == 'atm' ||
      paymentMethodCode.toLowerCase() == 'online';
  bool get isBankCheck => paymentMethodCode.toLowerCase() == 'bank_check';
  bool get isGiftCheck =>
      paymentMethodCode.toLowerCase() == 'gift_check' ||
      paymentMethodCode.toLowerCase() == 'coupon';
  bool get isCharge => paymentMethodCode.toLowerCase() == 'charge';

  @override
  List<Object?> get props => [
        paymentMethodId,
        paymentMethodCode,
        paymentMethodName,
        amount,
        cashTendered,
        changeGiven,
        excessAmount,
        cashlessAmount,
        bankId,
        bankName,
        cardType,
        cardNumber,
        cardExpiry,
        approvalNumber,
        referenceNumber,
        merchantTerminal,
        paymentChannel,
        giftCheckId,
        giftCheckName,
        giftCheckQty,
        serialNumbers,
        chargeAccountId,
        chargeAccountName,
        customerName,
        customerAddress,
        customerTin,
      ];
}
