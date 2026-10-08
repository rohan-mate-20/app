import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _indianFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _indianFormatWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(num amount) {
    if (amount % 1 == 0) {
      return _indianFormat.format(amount);
    }
    return _indianFormatWithDecimals.format(amount);
  }

  static String formatNumber(num amount) {
    if (amount % 1 == 0) {
      return NumberFormat('##,##,##0', 'en_IN').format(amount);
    }
    return NumberFormat('##,##,##0.00', 'en_IN').format(amount);
  }
}