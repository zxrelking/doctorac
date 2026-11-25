class ArabicDateFormatter {
  ArabicDateFormatter._();

  static const List<String> months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const List<String> weekdays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<String> shortWeekdays = [
    'اثن',
    'ثلا',
    'أرب',
    'خمي',
    'جمع',
    'سبت',
    'أحد',
  ];

  /// Example: "ديسمبر 2026"
  static String monthYear(DateTime date) =>
      '${months[date.month - 1]} ${date.year}';

  /// Example: "الخميس، 24 ديسمبر"
  static String weekdayDayMonth(DateTime date) =>
      '${weekdays[date.weekday - 1]}، ${date.day} ${months[date.month - 1]}';

  /// Example: "الخميس، 24 ديسمبر 2026"
  static String fullArabicDate(DateTime date) =>
      '${weekdays[date.weekday - 1]}، ${date.day} ${months[date.month - 1]} ${date.year}';

  /// Example: "22 نوفمبر 2026"
  static String dayMonthYear(DateTime date) =>
      '${date.day} ${months[date.month - 1]} ${date.year}';

  /// Converts "6:30 م" -> "6:30 مساءً", "9:00 ص" -> "9:00 صباحاً"
  static String expandPeriod(String slot) {
    final trimmed = slot.trim();
    if (trimmed.endsWith('م') && !trimmed.endsWith('مساءً')) {
      return '${trimmed.substring(0, trimmed.length - 1).trim()} مساءً';
    }
    if (trimmed.endsWith('ص') && !trimmed.endsWith('صباحاً')) {
      return '${trimmed.substring(0, trimmed.length - 1).trim()} صباحاً';
    }
    return trimmed;
  }

  /// Generates a realistic Doctorac booking code like DRC-261224-128
  static String generateBookingRef({String prefix = 'DRC', DateTime? date}) {
    final d = date ?? DateTime.now();
    final yy = (d.year % 100).toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final rand = (100 + (DateTime.now().microsecondsSinceEpoch % 899));
    return '$prefix-$yy$mm$dd-$rand';
  }

  static String formatPrice(int price) => '$price جنيه';

  static String toIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
