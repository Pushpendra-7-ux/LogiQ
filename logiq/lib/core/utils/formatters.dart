class Formatters {
  Formatters._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  static String shortDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day} ${_months[d.month - 1]}';
  }

  static String dateRange(DateTime? from, DateTime? to) {
    if (from == null || to == null) return '—';
    if (from.year == to.year && from.month == to.month) {
      return '${from.day} – ${to.day} ${_months[to.month - 1]} ${to.year}';
    }
    return '${shortDate(from)} – ${shortDate(to)}';
  }

  static String time(DateTime? d) {
    if (d == null) return '—';
    var hour = d.hour % 12;
    if (hour == 0) hour = 12;
    final mm = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$hour:$mm $ampm';
  }

  /// HH:MM:SS (or MM:SS below one hour) countdown text.
  static String countdown(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$mm:$ss';
  }

  static String greeting({String? firstName}) {
    final hour = DateTime.now().hour;
    final word =
        hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    if (firstName == null || firstName.isEmpty) return word;
    return '$word, $firstName';
  }
}
