import 'package:flutter/material.dart';
import 'package:school_log/format.dart';
import 'package:school_log/theme/app_theme.dart';

class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.selectedDate,
    required this.today,
    required this.onSelect,
  });

  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  @override
  void didUpdateWidget(MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    final previous = DateTime(
      oldWidget.selectedDate.year,
      oldWidget.selectedDate.month,
    );
    if (next != previous) _visibleMonth = next;
  }

  void _shift(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysOf(_visibleMonth);
    final weekCount = days.length ~/ 7;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
        child: Column(
          children: [
            Row(
              children: [
                _Chevron(
                  tooltip: '이전 달',
                  icon: Icons.chevron_left,
                  onPressed: () => _shift(-1),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuChip<int>(
                        label: _koreanMonths[_visibleMonth.month - 1],
                        tooltip: '월 선택',
                        items: [
                          for (var month = 1; month <= 12; month++)
                            PopupMenuItem(
                              value: month,
                              child: Text(_koreanMonths[month - 1]),
                            ),
                        ],
                        onSelected: (month) {
                          setState(() {
                            _visibleMonth = DateTime(_visibleMonth.year, month);
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _MenuChip<int>(
                        label: '${_visibleMonth.year}',
                        tooltip: '연도 선택',
                        items: [
                          for (
                            var year = _visibleMonth.year - 3;
                            year <= _visibleMonth.year + 3;
                            year++
                          )
                            PopupMenuItem(value: year, child: Text('$year')),
                        ],
                        onSelected: (year) {
                          setState(() {
                            _visibleMonth = DateTime(year, _visibleMonth.month);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                _Chevron(
                  tooltip: '다음 달',
                  icon: Icons.chevron_right,
                  onPressed: () => _shift(1),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                for (final name in _koreanWeekdays)
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: Center(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.weekday,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            for (var week = 0; week < weekCount; week++)
              Row(
                children: [
                  for (var day = 0; day < 7; day++)
                    Expanded(
                      child: _DayCell(
                        key: ValueKey(
                          'day-${days[week * 7 + day].year}-${days[week * 7 + day].month}-${days[week * 7 + day].day}',
                        ),
                        date: days[week * 7 + day],
                        visibleMonth: _visibleMonth,
                        selectedDate: widget.selectedDate,
                        today: widget.today,
                        onSelect: widget.onSelect,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

const _koreanMonths = [
  '1월',
  '2월',
  '3월',
  '4월',
  '5월',
  '6월',
  '7월',
  '8월',
  '9월',
  '10월',
  '11월',
  '12월',
];

const _koreanWeekdays = ['일', '월', '화', '수', '목', '금', '토'];

List<DateTime> _daysOf(DateTime month) {
  final first = DateTime(month.year, month.month);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final leading = first.weekday % 7;
  final cellCount = ((leading + daysInMonth + 6) ~/ 7) * 7;
  final start = first.subtract(Duration(days: leading));
  return [
    for (var i = 0; i < cellCount; i++)
      DateTime(start.year, start.month, start.day + i),
  ];
}

class _Chevron extends StatelessWidget {
  const _Chevron({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.ink,
      iconSize: 22,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
    );
  }
}

class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.tooltip,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final String tooltip;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (context) => items,
      offset: const Offset(0, 32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.date,
    required this.visibleMonth,
    required this.selectedDate,
    required this.today,
    required this.onSelect,
  });

  final DateTime date;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final inMonth =
        date.month == visibleMonth.month && date.year == visibleMonth.year;
    final selected = isSameDate(date, selectedDate);
    final isToday = isSameDate(date, today);
    final background = selected
        ? AppColors.ink
        : isToday
        ? AppColors.today
        : Colors.transparent;
    final foreground = selected
        ? Colors.white
        : inMonth
        ? AppColors.ink
        : AppColors.outsideDay;

    return Semantics(
      button: true,
      selected: selected,
      label: formatFullDate(date),
      child: _DayTap(
        onTap: () => onSelect(date),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  height: 1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selects a day on a tap without joining the drag arena, so a sideways
/// slide still moves the page underneath the calendar.
class _DayTap extends StatefulWidget {
  const _DayTap({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_DayTap> createState() => _DayTapState();
}

class _DayTapState extends State<_DayTap> {
  Offset? _origin;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _origin = event.position,
      onPointerUp: (event) {
        final origin = _origin;
        _origin = null;
        if (origin != null && (event.position - origin).distance < 18) {
          widget.onTap();
        }
      },
      onPointerCancel: (_) => _origin = null,
      child: widget.child,
    );
  }
}
