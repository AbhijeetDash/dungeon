/// Tiny date helpers. We deliberately avoid the `intl` package — its version is
/// often pinned by the Flutter SDK and causes resolution headaches. The few
/// formats we need are trivial to build by hand.
class DateX {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _weekdaysLong = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static String _2(int n) => n.toString().padLeft(2, '0');

  /// API format: YYYY-MM-DD (local date).
  static String ymd(DateTime d) => '${d.year}-${_2(d.month)}-${_2(d.day)}';

  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// The next [count] days starting today (for the date strip).
  static List<DateTime> upcoming(int count) =>
      List.generate(count, (i) => today().add(Duration(days: i)));

  static String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];
  static String weekdayLong(DateTime d) => _weekdaysLong[d.weekday - 1];
  static String monthShort(DateTime d) => _months[d.month - 1];

  /// "Oct 24, 2026"
  static String pretty(DateTime d) => '${monthShort(d)} ${d.day}, ${d.year}';

  /// "Wed, Jun 10" — used on booking cards.
  static String prettyShort(DateTime d) =>
      '${weekdayLong(d).substring(0, 3)}, ${monthShort(d)} ${d.day}';

  /// Parse "YYYY-MM-DD" back into a DateTime (for display of stored bookings).
  static DateTime? parseYmd(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// "06:00" for an integer hour.
  static String hourLabel(int hour) => '${_2(hour)}:00';
}
