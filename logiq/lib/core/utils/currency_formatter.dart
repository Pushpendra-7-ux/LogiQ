/// Formats amounts the Indian way: ₹50,000 / ₹1,25,000.
class CurrencyFormatter {
  CurrencyFormatter._();

  static String group(num amount) {
    final n = amount.round();
    final negative = n < 0;
    final s = n.abs().toString();
    String out;
    if (s.length <= 3) {
      out = s;
    } else {
      final last3 = s.substring(s.length - 3);
      var rest = s.substring(0, s.length - 3);
      final chunks = <String>[];
      while (rest.length > 2) {
        chunks.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) chunks.insert(0, rest);
      out = '${chunks.join(',')},$last3';
    }
    return negative ? '-$out' : out;
  }

  static String format(num amount) => '₹${group(amount)}';

  static String formatCompact(num amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)} L';
    return format(amount);
  }

  static double? parse(String raw) {
    final cleaned =
        raw.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
