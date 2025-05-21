class PaymentMethod {
  final String id;
  final String type; // 'credit', 'debit', 'upi', etc.
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final String cardholderName;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardholderName,
    this.isDefault = false,
  });

  // Format expiry date as MM/YY
  String get expiryFormatted => '$expiryMonth/${expiryYear % 100}';
  
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
  String get maskedNumber => '•••• •••• •••• $last4';
  
  // Convert to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'last4': last4,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cardholderName': cardholderName,
      'isDefault': isDefault,
    };
  }
  
  // Create from a map
  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'],
      type: map['type'],
      last4: map['last4'],
      expiryMonth: map['expiryMonth'],
      expiryYear: map['expiryYear'],
      cardholderName: map['cardholderName'],
      isDefault: map['isDefault'] ?? false,
    );
  }
} 