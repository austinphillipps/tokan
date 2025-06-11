// lib/features/projects/widgets/editable_project_shortcut_widget.dart

import 'package:flutter/material.dart';
import '../models/project_models.dart';
import '../../../main.dart'; // pour AppColors

/// Une carte de projet “shortcut” modifiable :
/// • Taper sur la carte (ouvre/renomme)
/// • Menu “…” pour renommer/supprimer
class EditableProjectShortcutWidget extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final ValueChanged<String>? onRename;
  final VoidCallback? onDelete;

  const EditableProjectShortcutWidget({
    Key? key,
    required this.project,
    this.onTap,
    this.onRename,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Fond en « verre sombre » pour laisser transparaître l'image
    final cardColor = AppColors.glassBackground;

    // Couleur du texte principal (titre du projet)
    final textColor = theme.colorScheme.onSurface;

    // Couleur de fond du menu contextuel (PopupMenu)
    final menuBgColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceVariant
        : theme.colorScheme.surface;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap ?? () => _startEditingName(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              // Titre du projet
              Expanded(
                child: Text(
                  project.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Menu renommer / supprimer
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: textColor.withOpacity(0.7)),
                color: menuBgColor,
                onSelected: (action) {
                  switch (action) {
                    case 'rename':
                      _startEditingName(context);
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  if (onRename != null)
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(
                        'Renommer',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Supprimer',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startEditingName(BuildContext context) {
    final controller = TextEditingController(text: project.name);
    final theme = Theme.of(context);
    final dialogBg = theme.colorScheme.surface; // blanc en clair, gris clair en sombre

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dialogBg,
        title: const Text('Renommer le projet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nom du projet'),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop();
            onRename?.call(value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRename?.call(controller.text.trim());
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
