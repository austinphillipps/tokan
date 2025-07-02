import 'package:flutter/material.dart';
import '../../../main.dart';

class CalendarMenuBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;
  final VoidCallback onToggleMonthPopup;
  final String monthYearDisplay;
  final int currentMonth;
  final bool automaticallyImplyLeading;

  const CalendarMenuBar({
    Key? key,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onToday,
    required this.onToggleMonthPopup,
    required this.monthYearDisplay,
    required this.currentMonth,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  IconData _iconForMonth(int month) {
    if (month == 12 || month == 1 || month == 2) {
      return Icons.ac_unit; // Hiver
    } else if (month >= 3 && month <= 5) {
      return Icons.local_florist; // Printemps
    } else if (month >= 6 && month <= 8) {
      return Icons.wb_sunny; // Été
    } else {
      return Icons.beach_access; // Automne
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;
    final iconColor = Colors.white;
    final borderColor = Colors.white.withOpacity(0.7);

    return AppBar(
      backgroundColor: AppColors.glassHeader,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleSpacing: 0,
      title: Row(
        children: [
          const Spacer(),
          OutlinedButton(
            onPressed: onToday,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor, width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'AUJOURD\'HUI',
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onPreviousWeek,
            icon: Icon(Icons.chevron_left, color: iconColor),
            tooltip: 'Semaine précédente',
          ),
          IconButton(
            onPressed: onNextWeek,
            icon: Icon(Icons.chevron_right, color: iconColor),
            tooltip: 'Semaine suivante',
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggleMonthPopup,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconForMonth(currentMonth),
                    color: iconColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    monthYearDisplay,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: iconColor),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
