import 'package:intl/intl.dart';

/// Formateadores compartidos (spec 8.2: "Monto mostrado: Formato de moneda").
class Formatters {
  Formatters._();

  /// Formatea un monto según el código de moneda (USD/CLP/EUR). CLP no usa
  /// decimales por convención; USD/EUR sí.
  static String currency(num amount, String currencyCode) {
    final upper = currencyCode.toUpperCase();
    switch (upper) {
      case 'CLP':
        return NumberFormat.currency(
          locale: 'es_CL',
          symbol: '\$',
          decimalDigits: 0,
        ).format(amount);
      case 'EUR':
        return NumberFormat.currency(
          locale: 'es_ES',
          symbol: '€',
          decimalDigits: 2,
        ).format(amount);
      case 'USD':
      default:
        return NumberFormat.currency(
          locale: 'en_US',
          symbol: '\$',
          decimalDigits: 2,
        ).format(amount);
    }
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }
}
