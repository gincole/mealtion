import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class CalendarCard extends StatefulWidget {
  const CalendarCard({
    super.key,
    required this.meals,
  });

  // meals expects: { date: '3 Dec 2025', mood: 'green'|'yellow'|'red' }
  final List<Map<String, dynamic>> meals;

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = _monthYearLabel(_focusedMonth);
    final grid = _buildMonthGrid(_focusedMonth);
    final dotsByDay = _buildDotsByDay(widget.meals);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
              Row(
                children: [
                  _NavIconButton(
                    icon: Icons.chevron_left,
                    onTap: () => setState(() => _focusedMonth = _addMonths(_focusedMonth, -1)),
                  ),
                  const SizedBox(width: 6),
                  _NavIconButton(
                    icon: Icons.chevron_right,
                    onTap: () => setState(() => _focusedMonth = _addMonths(_focusedMonth, 1)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weekday header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _WeekdayLabel('S'),
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
            ],
          ),
          const SizedBox(height: 10),

          // Calendar grid (7 columns)
          GridView.builder(
            itemCount: grid.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, i) {
              final day = grid[i];
              final isCurrentMonth = day.month == _focusedMonth.month;
              final isToday = _isSameDay(day, DateTime.now());

              final dayDots = dotsByDay[_dayKey(day)] ?? const <Color>[];

              return _DayCell(
                day: day,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                dots: dayDots,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.isToday,
    required this.dots,
  });

  final DateTime day;
  final bool isCurrentMonth;
  final bool isToday;
  final List<Color> dots;

  @override
  Widget build(BuildContext context) {
    final textColor = isCurrentMonth ? AppColors.textMain : AppColors.textLight.withOpacity(0.45);
    final dayTextStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: isToday ? AppColors.primary : textColor,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${day.day}', style: dayTextStyle),
        const SizedBox(height: 2),

        // Up to 3 dots under the day number
        SizedBox(
          height: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: dots.take(3).map((c) {
              return Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ---------- Helpers ----------

String _monthYearLabel(DateTime d) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[d.month - 1]} ${d.year}';
}

DateTime _addMonths(DateTime d, int delta) {
  int newMonth = d.month + delta;
  int newYear = d.year;
  
  while (newMonth > 12) {
    newMonth -= 12;
    newYear += 1;
  }
  while (newMonth < 1) {
    newMonth += 12;
    newYear -= 1;
  }
  
  return DateTime(newYear, newMonth, 1);
}

// Build a 6-week grid (42 cells) starting from Sunday of the first week containing the 1st.
List<DateTime> _buildMonthGrid(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final weekday = first.weekday; // Mon=1..Sun=7
  final daysFromSunday = weekday % 7; // Sun=0, Mon=1, ... Sat=6
  final start = first.subtract(Duration(days: daysFromSunday));

  return List.generate(42, (i) => DateTime(start.year, start.month, start.day + i));
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

// Map meals to day dots. Expects meal['date'] like "3 Dec 2025" and meal['mood'] like "green|yellow|red".
// Max 3 dots per day, priority: red > yellow > green (show bad meals first)
Map<String, List<Color>> _buildDotsByDay(List<Map<String, dynamic>> meals) {
  final map = <String, List<String>>{}; // Store mood strings first
  for (final m in meals) {
    final parsed = _parseMealDate(m['date'] as String?);
    if (parsed == null) continue;

    final key = _dayKey(parsed);
    map.putIfAbsent(key, () => []);

    final mood = (m['mood'] ?? '') as String;
    if (mood.isNotEmpty) map[key]!.add(mood);
  }

  // Convert to colors with priority: red > yellow > green, max 3
  final result = <String, List<Color>>{};
  for (final entry in map.entries) {
    final moods = entry.value;
    // Sort by priority: red first, then yellow, then green
    moods.sort((a, b) {
      const priority = {'red': 0, 'yellow': 1, 'green': 2};
      return (priority[a] ?? 3).compareTo(priority[b] ?? 3);
    });
    // Take max 3 and convert to colors
    final colors = moods.take(3).map((m) => _moodToColor(m)).whereType<Color>().toList();
    result[entry.key] = colors;
  }
  return result;
}

Color? _moodToColor(String mood) {
  switch (mood) {
    case 'green':
      return AppColors.green;
    case 'yellow':
      return AppColors.yellow;
    case 'red':
      return AppColors.red;
    default:
      return null;
  }
}

// Parses "3 Dec 2025" into DateTime(2025,12,3)
DateTime? _parseMealDate(String? s) {
  if (s == null) return null;
  final parts = s.split(' ');
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final year = int.tryParse(parts[2]);
  if (day == null || year == null) return null;

  final month = _monthFromShort(parts[1]);
  if (month == null) return null;

  return DateTime(year, month, day);
}

int? _monthFromShort(String m) {
  const short = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };
  return short[m];
}
