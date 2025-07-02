import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskWidget extends StatelessWidget {
  final Task task;
  final double height;
  final Color backgroundColor;
  final Color textColor;
  final void Function(Task task) onTap;
  final void Function(Task task, bool isResizing) onPanStart;
  final void Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onPanEnd;

  const TaskWidget({
    Key? key,
    required this.task,
    required this.height,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Appui court => ouvrir les détails de la tâche
      onTap: () => onTap(task),
      // Début du drag => déterminer si on redimensionne (si près du bas) ou si on déplace
      onPanStart: (DragStartDetails details) {
        // On considère qu'un contact à moins de 10px du bas correspond à un redimensionnement
        bool isResize = (details.localPosition.dy > height - 10);
        onPanStart(task, isResize);
      },
      onPanUpdate: onPanUpdate,
      onPanEnd: (DragEndDetails details) => onPanEnd(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.black54),
          borderRadius: BorderRadius.circular(4.0),
        ),
        padding: EdgeInsets.all(4.0),
        child: Text(
          task.title,
          style: TextStyle(color: textColor, fontSize: 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
