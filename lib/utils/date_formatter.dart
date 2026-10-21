class AppDateFormatter {
  static const List<String> _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static const List<String> _monthsLong = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<String> _daysShort = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
  ];

  static const List<String> _daysLong = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  static String getDayName(DateTime dt) {
    return _daysLong[dt.weekday - 1];
  }

  static String getMonthShort(DateTime dt) {
    return _monthsShort[dt.month - 1];
  }

  static String formatDayAndDate(DateTime dt) {
    final dayName = _daysLong[dt.weekday - 1];
    final month = _monthsShort[dt.month - 1];
    return '$dayName, ${dt.day} $month';
  }

  static String formatDate(DateTime dt) {
    final month = _monthsShort[dt.month - 1];
    return '${dt.day} $month';
  }

  static String formatDayDateAndTime(DateTime dt, int hour, int minute) {
    final dayName = _daysLong[dt.weekday - 1];
    final month = _monthsShort[dt.month - 1];
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$dayName, ${dt.day} $month, $hh:$mm';
  }

  static String formatShort(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    if (difference.inDays == 0 && dt.day == now.day) {
      return '$hh:$mm';
    } else if (difference.inDays < 7 && dt.weekday >= 1 && dt.weekday <= 7) {
      return '${_daysShort[dt.weekday - 1]}, $hh:$mm';
    } else {
      final month = _monthsShort[dt.month - 1];
      return '${dt.day} $month ${dt.year}';
    }
  }

  static String formatDetail(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final month = _monthsLong[dt.month - 1];
    return '${dt.day} $month ${dt.year}, $hh:$mm';
  }

  static String formatWithTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final month = _monthsShort[dt.month - 1];
    return '${dt.day} $month, $hh:$mm';
  }

  static String formatTimeOnly(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
