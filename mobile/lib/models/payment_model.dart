/// Modelos del flujo de compra (spec 8.1). No tenemos el serializer real
/// de `initiate_purchase` / `create_payment_intent`, así que el parsing
/// asume los nombres de campo más probables dado el resto del contrato.
/// Ajustable en un solo lugar si difiere.
library;

class PurchaseSessionModel {
  final String sessionId;
  final int x;
  final int y;
  final String currency;
  final num? price;

  const PurchaseSessionModel({
    required this.sessionId,
    required this.x,
    required this.y,
    required this.currency,
    this.price,
  });

  factory PurchaseSessionModel.fromJson(Map<String, dynamic> json) {
    return PurchaseSessionModel(
      sessionId: (json['session_id'] ?? json['sessionId'] ?? '').toString(),
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      price: json['price'] as num?,
    );
  }
}

class PaymentIntentModel {
  final String clientSecret;
  final String paymentIntentId;
  final num? amount;
  final String currency;

  const PaymentIntentModel({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.currency,
    this.amount,
  });

  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) {
    final clientSecret =
        json['client_secret'] as String? ?? json['clientSecret'] as String? ?? '';

    // Algunos backends devuelven el payment_intent_id explícito; si no,
    // se puede derivar del propio client_secret (formato pi_xxx_secret_yyy).
    final explicitId = json['payment_intent_id'] as String?;
    final derivedId =
        clientSecret.contains('_secret_') ? clientSecret.split('_secret_').first : clientSecret;

    return PaymentIntentModel(
      clientSecret: clientSecret,
      paymentIntentId: explicitId ?? derivedId,
      amount: json['amount'] as num?,
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}
