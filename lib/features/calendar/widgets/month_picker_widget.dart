// lib/features/calendar/views/month_picker_panel.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../main.dart';

class MonthPickerPanel extends StatelessWidget {
  final DateTime currentMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onClose;

  const MonthPickerPanel({
    Key? key,
    required this.currentMonth,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.onClose,
  }) : super(key: key);

  // Navigue vers le mois précédent.
  void _goToPreviousMonth() {
    onMonthChanged(DateTime(currentMonth.year, currentMonth.month - 1, 1));
  }

  // Navigue vers le mois suivant.
  void _goToNextMonth() {
    onMonthChanged(DateTime(currentMonth.year, currentMonth.month + 1, 1));
  }

  String get _monthYearDisplay => DateFormat.yMMMM('fr_FR').format(currentMonth);

  /// Construit la ligne d'en-tête avec flèches et affichage du mois/année.
  Widget _buildHeader(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        IconButton(
          onPressed: _goToPreviousMonth,
          icon: Icon(Icons.chevron_left, color: textColor),
        ),
        Expanded(
          child: Center(
            child: Text(
              _monthYearDisplay,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _goToNextMonth,
          icon: Icon(Icons.chevron_right, color: textColor),
        ),
        IconButton(
          onPressed: onClose,
          icon: Icon(Icons.close, color: textColor),
          tooltip: 'Fermer',
        ),
      ],
    );
  }

  /// Construit la ligne des noms de jours de la semaine.
  Widget _buildWeekDays(BuildContext context) {
    final weekdayColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    const weekDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays
          .map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: weekdayColor,
            ),
          ),
        ),
      ))
          .toList(),
    );
  }

  /// Construit la grille des jours du mois courant.
  List<Widget> _buildDaysGrid(BuildContext context) {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final numDaysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final startingWeekday = firstDay.weekday; // lundi = 1, dimanche = 7

    final bgColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkGreyBackground
        : Colors.white;
    final dayTextColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onBackground
        : Colors.black87;
    final outsideTextColor = dayTextColor.withOpacity(0.5);

    List<Widget> cells = [];
    // Cases vides avant le premier jour (si le mois ne démarre pas le lundi).
    for (int i = 1; i < startingWeekday; i++) {
      cells.add(Container());
    }
    // Création des cellules pour chaque jour.
    for (int day = 1; day <= numDaysInMonth; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      cells.add(
        InkWell(
          onTap: () => onDateSelected(date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.all(4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day.toString(),
              style: TextStyle(
                fontSize: 16,
                color: dayTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final panelBg = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkGreyBackground
        : Colors.white;
    return Center(
      // Utilisation de Center pour positionner la card au centre de l'écran.
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: panelBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              _buildWeekDays(context),
              const SizedBox(height: 10),
              // Grille des jours présentée avec GridView.
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _buildDaysGrid(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
