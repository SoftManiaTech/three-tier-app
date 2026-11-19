import 'package:intl/intl.dart';
import '../constants/app_config.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConfig.currencySymbol,
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  /// Formats a numerical price into Indian Rupee format (e.g., ₹1,249.00)
  static String formatCurrency(double? amount) {
    if (amount == null || amount.isNaN) return '${AppConfig.currencySymbol}0.00';
    return _currencyFormat.format(amount);
  }

  /// Formats a DateTime or parses an ISO / SQL date string
  static String formatDate(dynamic date) {
    if (date == null) return 'Recently added';
    try {
      DateTime dt;
      if (date is DateTime) {
        dt = date;
      } else if (date is String) {
        if (date.trim().isEmpty) return 'Recently added';
        // Handle SQL format 'YYYY-MM-DD HH:MM:SS' by replacing space with 'T'
        final cleanStr = date.trim().contains(' ') && !date.contains('T')
            ? date.trim().replaceFirst(' ', 'T')
            : date.trim();
        dt = DateTime.parse(cleanStr);
      } else {
        return 'Recently added';
      }
      return _dateFormat.format(dt);
    } catch (_) {
      return 'Recently added';
    }
  }
}
