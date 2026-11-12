import 'package:intl/intl.dart';

class AppConstants {
  static const categories = [
    'Shampoo & Conditioner',
    'Hair Treatment',
    'Relaxers & Perms',
    'Skincare',
    'Hair Colour',
    'Styling Products',
    'Tools & Accessories',
    'Other',
  ];
}

class DateFormatter {
  static final _fmt = DateFormat('dd MMM yyyy');
  static final _short = DateFormat('dd/MM/yy');
  static final _currency = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);

  static String format(DateTime d) => _fmt.format(d);
  static String shortFormat(DateTime d) => _short.format(d);
  static String currency(double amount) => _currency.format(amount);
}
