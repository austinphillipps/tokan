import 'package:flutter/material.dart';
import '../models/custom_task_model.dart';

class SubTaskListWidget extends StatefulWidget {
  final List<CustomTask> subTasks;
  final void Function(int index) onEdit;
  final void Function(int index) onDelete;
  final void Function(int index) onToggleStatus;
  final void Function(String newTaskName) onAdd;

  const SubTaskListWidget({
    Key? key,
    required this.subTasks,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onAdd,
  }) : super(key: key);

  @override
  _SubTaskListWidgetState createState() => _SubTaskListWidgetState();
}

class _SubTaskListWidgetState extends State<SubTaskListWidget> {
  bool showNewSubTaskField = false;
  String newSubTaskText = "";
  final FocusNode newSubTaskFocusNode = FocusNode();

  void _confirmNewSubTask() {
    final text = newSubTaskText.trim();
    if (text.isNotEmpty) {
      widget.onAdd(text);
    }
    setState(() {
      newSubTaskText = "";
      showNewSubTaskField = false;
    });
  }

  void _showNewSubTaskField() {
    setState(() {
      showNewSubTaskField = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(newSubTaskFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sous-tâches",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.subTasks.length,
          itemBuilder: (context, index) {
            final subTask = widget.subTasks[index];
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => widget.onEdit(index),
                child: Card(
                  color: Colors.grey[800],
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: IconButton(
                      icon: subTask.status == 'terminé'
                          ? const Icon(Icons.check, color: Colors.white)
                          : const Icon(Icons.circle_outlined, color: Colors.white70),
                      onPressed: () => widget.onToggleStatus(index),
                    ),
                    title: Text(
                      subTask.name,
                      style: TextStyle(
                        color: subTask.status == 'terminé' ? Colors.greenAccent : Colors.white,
                        decoration: subTask.status == 'terminé' ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => widget.onDelete(index),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (showNewSubTaskField)
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) _confirmNewSubTask();
            },
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: newSubTaskFocusNode,
                    onChanged: (value) {
                      setState(() {
                        newSubTaskText = value;
                      });
                    },
                    onSubmitted: (_) => _confirmNewSubTask(),
                    decoration: InputDecoration(
                      hintText: "Nouvelle sous-tâche",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _confirmNewSubTask,
                ),
              ],
            ),
          ),
        ElevatedButton.icon(
          onPressed: () {
            if (!showNewSubTaskField) {
              _showNewSubTaskField();
            } else {
              _confirmNewSubTask();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text("Ajouter une sous-tâche"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[700]),
        ),
      ],
    );
  }
}