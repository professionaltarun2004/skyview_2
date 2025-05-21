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
  final String name;
  final String type;
  final String countryCode;
  final String? icon;
  final List<String> supportedCurrencies;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.countryCode,
    this.icon,
    required this.supportedCurrencies,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      countryCode: json['countryCode'] as String,
      icon: json['icon'] as String?,
      supportedCurrencies: List<String>.from(json['supportedCurrencies']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'countryCode': countryCode,
      'icon': icon,
      'supportedCurrencies': supportedCurrencies,
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