DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isWeekend(DateTime date) => date.weekday >= DateTime.saturday;

const weekdayKo = ['월', '화', '수', '목', '금', '토', '일'];

String formatFullDate(DateTime date) {
  final name = weekdayKo[date.weekday - 1];
  return '${date.year}년 ${date.month}월 ${date.day}일 ($name)';
}

String formatMonthDay(DateTime date) {
  final name = weekdayKo[date.weekday - 1];
  return '${date.month}월 ${date.day}일 ($name)';
}
