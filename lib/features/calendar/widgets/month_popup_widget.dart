// lib/features/calendar/views/month_popup_widget.dart

import 'package:flutter/material.dart';
import '../../../main.dart';

/// Widget qui enveloppe un DropdownButton pour lui ajouter un effet de survol.
class HoverableDropdown<T> extends StatefulWidget {
  final DropdownButton<T> dropdown;
  const HoverableDropdown({Key? key, required this.dropdown}) : super(key: key);

  @override
  _HoverableDropdownState<T> createState() => _HoverableDropdownState<T>();
}

class _HoverableDropdownState<T> extends State<HoverableDropdown<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = _isHovered
        ? AppColors.darkGreyBackground
        : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: widget.dropdown,
      ),
    );
  }
}

/// Widget représentant une cellule de jour dans la grille du calendrier.
class _DayCell extends StatefulWidget {
  final int day;
  final bool isCurrentMonth; // Faux si le jour n'appartient pas au mois courant.
  final VoidCallback onTap;

  const _DayCell({
    Key? key,
    required this.day,
    required this.isCurrentMonth,
    required this.onTap,
  }) : super(key: key);

  @override
  _DayCellState createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isCurrentMonth
        ? AppColors.darkGreyBackground
        : Colors.transparent;
    final hoverColor = AppColors.darkBackground;
    final bgColor = widget.isCurrentMonth && _isHovered
        ? hoverColor
        : baseColor;

    return MouseRegion(
      onEnter: (_) {
        if (widget.isCurrentMonth) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.isCurrentMonth) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${widget.day}',
            style: TextStyle(
              color: widget.isCurrentMonth
                  ? Theme.of(context).colorScheme.onBackground
                  : Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class MonthPopup extends StatefulWidget {
  /// La date qui détermine le mois affiché initialement.
  final DateTime initialMonth;
  /// Callback appelé lors de la sélection d’un jour.
  final Function(DateTime) onDateSelected;
  /// Callback appelé lorsque le popup doit se fermer.
  final VoidCallback onClose;

  const MonthPopup({
    Key? key,
    required this.initialMonth,
    required this.onDateSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  _MonthPopupState createState() => _MonthPopupState();
}

class _MonthPopupState extends State<MonthPopup> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = widget.initialMonth;
  }

  String _monthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return months[month - 1];
  }

  /// Retourne une icône saisonnière pour le mois.
  IconData _iconForMonth(int month) {
    if (month == 12 || month == 1 || month == 2) {
      return Icons.ac_unit; // Hiver
    } else if (month >= 3 && month <= 5) {
      return Icons.local_florist; // Printemps
    } else if (month >= 6 && month <= 8) {
      return Icons.wb_sunny; // Été
    } else {
      return Icons.emoji_nature; // Automne
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthDropdown = DropdownButton<int>(
      value: _displayedMonth.month,
      dropdownColor: AppColors.darkGreyBackground,
      underline: const SizedBox(),
      iconEnabledColor: Theme.of(context).colorScheme.onSurface,
      items: List.generate(12, (index) {
        final month = index + 1;
        return DropdownMenuItem(
          value: month,
          child: Row(
            children: [
              Icon(_iconForMonth(month), color: Theme.of(context).colorScheme.onSurface, size: 18),
              const SizedBox(width: 4),
              Text(_monthName(month), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        );
      }),
      onChanged: (newMonth) {
        if (newMonth != null) {
          setState(() {
            _displayedMonth = DateTime(_displayedMonth.year, newMonth, 1);
          });
        }
      },
    );

    final currentYear = DateTime.now().year;
    final yearDropdown = DropdownButton<int>(
      value: _displayedMonth.year,
      dropdownColor: AppColors.darkGreyBackground,
      underline: const SizedBox(),
      iconEnabledColor: Theme.of(context).colorScheme.onSurface,
      items: List.generate(11, (index) {
        final year = currentYear - 5 + index;
        return DropdownMenuItem(
          value: year,
          child: Text('$year', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        );
      }),
      onChanged: (newYear) {
        if (newYear != null) {
          setState(() {
            _displayedMonth = DateTime(newYear, _displayedMonth.month, 1);
          });
        }
      },
    );

    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final firstWeekday = firstDay.weekday;
    final lastDay = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final int blankCells = firstWeekday - 1;
    final int totalCells = ((blankCells + lastDay) / 7).ceil() * 7;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 320,
        color: AppColors.darkGreyBackground,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HoverableDropdown<int>(dropdown: monthDropdown),
                    const SizedBox(width: 10),
                    HoverableDropdown<int>(dropdown: yearDropdown),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: totalCells,
                  itemBuilder: (context, index) {
                    int dayNum;
                    bool isCurrentMonth;
                    if (index < blankCells) {
                      int prevMonth = _displayedMonth.month - 1;
                      int prevYear = _displayedMonth.year;
                      if (prevMonth < 1) {
                        prevMonth = 12;
                        prevYear -= 1;
                      }
                      int daysInPrev = DateTime(prevYear, prevMonth + 1, 0).day;
                      dayNum = daysInPrev - (blankCells - index) + 1;
                      isCurrentMonth = false;
                    } else if (index >= blankCells + lastDay) {
                      int nextMonth = _displayedMonth.month + 1;
                      int nextYear = _displayedMonth.year;
                      if (nextMonth > 12) {
                        nextMonth = 1;
                        nextYear += 1;
                      }
                      dayNum = index - blankCells - lastDay + 1;
                      isCurrentMonth = false;
                    } else {
                      dayNum = index - blankCells + 1;
                      isCurrentMonth = true;
                    }
                    return _DayCell(
                      day: dayNum,
                      isCurrentMonth: isCurrentMonth,
                      onTap: () {
                        DateTime selectedDate;
                        if (!isCurrentMonth) {
                          if (index < blankCells) {
                            int prevMonth = _displayedMonth.month - 1;
                            int prevYear = _displayedMonth.year;
                            if (prevMonth < 1) {
                              prevMonth = 12;
                              prevYear -= 1;
                            }
                            selectedDate = DateTime(prevYear, prevMonth, dayNum);
                          } else {
                            int nextMonth = _displayedMonth.month + 1;
                            int nextYear = _displayedMonth.year;
                            if (nextMonth > 12) {
                              nextMonth = 1;
                              nextYear += 1;
                            }
                            selectedDate = DateTime(nextYear, nextMonth, dayNum);
                          }
                        } else {
                          selectedDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayNum);
                        }
                        widget.onDateSelected(selectedDate);
                        widget.onClose();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
