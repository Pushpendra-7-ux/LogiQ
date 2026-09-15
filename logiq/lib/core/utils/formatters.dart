import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount) =>
      '₹${NumberFormat('#,##0').format(amount)}';

  static String date(DateTime dt) =>
      DateFormat('dd MMM yyyy').format(dt);

  static String dateRange(DateTime start, DateTime end) =>
      '${date(start)} – ${date(end)}';

  static String time(DateTime dt) =>
      DateFormat('hh:mm a').format(dt);

  static String dateTime(DateTime dt) =>
      '${date(dt)} ${time(dt)}';

  static String timer(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';

    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static String route(String from, String to) =>
      '$from → $to';
}