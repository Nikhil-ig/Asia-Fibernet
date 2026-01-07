// lib/widgets/custom_calendar.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../theme/colors.dart';
import '../../attendance/attendance_screen.dart'; // Make sure this path is correct

class CustomCalendar extends StatefulWidget {
  final Map<DateTime, List<AttendanceEvent>>
  events; // Receives events including holidays
  final DateTime selectedDay;
  final DateTime focusedMonth; // Only year/month matter

  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const CustomCalendar({
    super.key,
    required this.events,
    required this.selectedDay,
    required this.focusedMonth,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  List<String> get weekdays => [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      widget.focusedMonth.year,
      widget.focusedMonth.month,
    );
    // Use UTC for first day to match event keys
    final firstDayOfMonth = DateTime.utc(
      widget.focusedMonth.year,
      widget.focusedMonth.month,
      1,
    );
    final startingWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun

    final cells = <Widget>[];

    // Add empty cells before start of month
    for (int i = 1; i < startingWeekday; i++) {
      cells.add(_buildEmptyCell());
    }

    // Add day cells - Use UTC DateTime for consistency
    for (int day = 1; day <= daysInMonth; day++) {
      // Create the date key using UTC, matching how events are stored in the controller
      final dateKey = DateTime.utc(
        widget.focusedMonth.year,
        widget.focusedMonth.month,
        day,
      );
      cells.add(_buildDayCell(dateKey)); // Pass the UTC key
    }

    // Fill trailing empty cells
    final totalCells = cells.length;
    final remainingCells = (7 - (totalCells % 7)) % 7;
    for (int i = 0; i < remainingCells; i++) {
      cells.add(_buildEmptyCell());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 12.h),
        _buildWeekdayLabels(),
        SizedBox(height: 8.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          children: cells,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final monthName = DateFormat('MMMM yyyy').format(widget.focusedMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, size: 24.w),
          onPressed: widget.onPreviousMonth,
          tooltip: "Previous Month",
        ),
        Text(
          monthName,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorPrimary,
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, size: 24.w),
          onPressed: widget.onNextMonth,
          tooltip: "Next Month",
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    return Row(
      children:
          weekdays.map((day) {
            final isWeekend = day == 'Sat' || day == 'Sun';
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        isWeekend
                            ? AppColors.textColorHint
                            : AppColors.textColorPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildEmptyCell() {
    return Container();
  }

  Widget _buildDayCell(DateTime dateKey) {
    // Accept the UTC date key
    // Use the passed dateKey for checking events and isSelected/Today logic
    // The visual day number is derived from this key
    final dayNumber = dateKey.day;

    final isToday = _isSameDayUtc(dateKey, DateTime.now()); // Compare UTC keys
    final isSelected = _isSameDayUtc(
      dateKey,
      widget.selectedDay,
    ); // Compare UTC keys

    // Check for events using the UTC dateKey - This should now work
    final hasEvents =
        widget.events.containsKey(dateKey) &&
        widget.events[dateKey]!.isNotEmpty;

    Widget content;

    if (hasEvents) {
      // Get events for the UTC dateKey
      final events = widget.events[dateKey]!;
      final event = events.first; // Use first event for display logic

      // ✅ Show TEXT for "Present", "Weekend", "REJECTED"
      // ❗ Show ICON for everything else: Absent, Leave, Holiday, etc.
      if (event.status == 'Present' ||
          event.status == 'Weekend' ||
          event.status == "REJECTED") {
        content = Text(
          dayNumber.toString(), // Use the day number
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color:
                event.status == 'Present'
                    ? AppColors.success
                    : _getTextColor(
                      dateKey,
                    ), // Pass the dateKey for color logic
          ),
        );
      } else {
        IconData iconData;
        Color iconColor;

        // Check event type first for clarity and priority
        if (event.type == 'leave') {
          iconData = Iconsax.bezier;
          iconColor = AppColors.warning;
        } else if (event.type == 'holiday') {
          // Specific handling for holidays
          iconData = Iconsax.cake;
          iconColor = Colors.purple;
        } else {
          // Handle other attendance events (like Absent) or fallback
          switch (event.status) {
            case 'Absent':
              iconData = Iconsax.close_circle;
              iconColor = Colors.red;
              break;
            case 'Holiday':
              iconData = Iconsax.cake;
              iconColor = Colors.purple;
              break;
            default:
              iconData = Iconsax.info_circle;
              iconColor = AppColors.textColorSecondary;
          }
        }

        content = Icon(iconData, size: 20.w, color: iconColor);
      }
    } else {
      // No events → show date number
      content = Text(
        dayNumber.toString(), // Use the day number
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: _getTextColor(dateKey), // Pass the dateKey for color logic
        ),
      );
    }

    BoxDecoration? decoration;

    if (isSelected) {
      decoration = BoxDecoration(
        color:
            !isToday
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.success.withOpacity(0.2),
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        color: AppColors.success.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success, width: 1.5),
      );
    }

    return GestureDetector(
      onTap: () => widget.onDaySelected(dateKey), // Pass the UTC dateKey back
      child: Tooltip(
        message: DateFormat(
          'EEEE, MMMM d, yyyy',
        ).format(dateKey), // Show tooltip for the date
        child: AnimatedScale(
          duration: Duration(milliseconds: 150),
          scale: isSelected ? 1.1 : 1.0,
          child: Container(
            decoration: decoration,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }

  Color _getTextColor(DateTime date) {
    // Accept the UTC date key
    // Determine if the date is a weekend based on the key
    final isWeekend = date.weekday == 6 || date.weekday == 7; // Sat or Sun
    // Check if the date belongs to the currently focused month
    final isCurrentMonth = date.month == widget.focusedMonth.month;

    // Check if the date is today (using UTC comparison)
    final isToday = _isSameDayUtc(date, DateTime.now());

    if (!isCurrentMonth) {
      return AppColors.textColorSecondary.withOpacity(0.5);
    } else if (isToday) {
      return AppColors.success;
    } else if (isWeekend) {
      return AppColors.textColorHint;
    } else {
      return AppColors.textColorPrimary;
    }
  }

  // Helper to compare if two DateTime objects represent the same day in UTC
  bool _isSameDayUtc(DateTime a, DateTime b) {
    // Ensure both are compared in UTC
    return a.toUtc().year == b.toUtc().year &&
        a.toUtc().month == b.toUtc().month &&
        a.toUtc().day == b.toUtc().day;
  }
}
