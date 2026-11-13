import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_AR',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _numberFormatter = NumberFormat.decimalPattern('es_AR');

  static String formatCurrency(num amount) {
    return _currencyFormatter.format(amount);
  }

  static String formatNumber(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return _numberFormatter.format(value);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'es').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm', 'es').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm', 'es').format(dateTime);
  }

  static String formatDateLong(DateTime date) {
    return DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'es').format(date);
  }

  static String formatPresupuestoNumber(int id) {
    return 'PRE-${id.toString().padLeft(4, '0')}';
  }
}

