class Currency {
  final String code;
  final String symbol;
  final String name;
  final double rateToUSD;
  final String countryCode;

  Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.rateToUSD,
    required this.countryCode,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      rateToUSD: (json['rateToUSD'] as num).toDouble(),
      countryCode: json['countryCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'symbol': symbol,
      'name': name,
      'rateToUSD': rateToUSD,
      'countryCode': countryCode,
    };
  }
}

class PaymentMethod {
  final String id;
  final String type; // 'credit', 'debit', 'upi', etc.
  final String? last4;
  final int? expiryMonth;
  final int? expiryYear;
  final String? cardholderName;
  final bool isDefault;
  final String name;
  final String countryCode;
  final String? icon;
  final List<String> supportedCurrencies;

  const PaymentMethod({
    required this.id,
    required this.type,
    this.last4,
    this.expiryMonth,
    this.expiryYear,
    this.cardholderName,
    this.isDefault = false,
    required this.name,
    required this.countryCode,
    this.icon,
    required this.supportedCurrencies,
  });

  // Format expiry date as MM/YY
  String get expiryFormatted => expiryMonth != null && expiryYear != null 
      ? '$expiryMonth/${expiryYear! % 100}'
      : '';
  
  // Get card type image
  String get typeImage {
    switch (type.toLowerCase()) {
      case 'visa':
        return 'assets/images/visa.png';
      case 'mastercard':
        return 'assets/images/mastercard.png';
      case 'amex':
        return 'assets/images/amex.png';
      case 'discover':
        return 'assets/images/discover.png';
      default:
        return 'assets/images/card.png';
    }
  }
  
  // Get formatted card number
  String get maskedNumber => last4 != null ? '•••• •••• •••• $last4' : '';

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      countryCode: json['countryCode'] as String,
      icon: json['icon'] as String?,
      supportedCurrencies: List<String>.from(json['supportedCurrencies']),
      last4: json['last4'] as String?,
      expiryMonth: json['expiryMonth'] as int?,
      expiryYear: json['expiryYear'] as int?,
      cardholderName: json['cardholderName'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'countryCode': countryCode,
      'icon': icon,
      'supportedCurrencies': supportedCurrencies,
      'last4': last4,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cardholderName': cardholderName,
      'isDefault': isDefault,
    };
  }
}

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String message;

  PaymentResult({
    required this.success,
    this.paymentId,
    required this.message,
  });
} 