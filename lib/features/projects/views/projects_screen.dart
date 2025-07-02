// lib/features/projects/views/projects_screen.dart

import 'package:flutter/material.dart';
import '../models/project_models.dart';
import '../services/project_service.dart';
import '../widgets/project_detail_panel_widget.dart';
import '../widgets/editable_project_shortcut_widget.dart';
import '../../../main.dart'; // Pour AppColors

class ProjectsScreen extends StatelessWidget {
  ProjectsScreen({Key? key}) : super(key: key);

  final ProjectService _projectService = ProjectService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fond général : on peut laisser transparent si un background en verre est utilisé plus haut
    final backgroundColor = theme.scaffoldBackgroundColor;

    // Couleur du titre
    final titleColor =
        theme.textTheme.headlineLarge?.color ?? theme.colorScheme.onBackground;

    // Largeur de l’écran, calculs de grille
    const spacing = 16.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final gridWidth = screenWidth * 0.9;
    final cardWidth = (gridWidth - 3 * spacing) / 4;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.9,
          child: StreamBuilder<List<Project>>(
            stream: _projectService.getProjectsStream(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.blue),
                  ),
                );
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Erreur : ${snap.error}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }
              final projects = snap.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        'Mes Projets',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      alignment: WrapAlignment.center,
                      children: projects
                          .map((p) => _buildProjectCard(ctx, p, cardWidth))
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkGreyBackground
                            : theme.colorScheme.surface,
                        foregroundColor: theme.colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer un projet'),
                      onPressed: () => _showCreateProjectDialog(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Carte d’un projet existant : ouvre le panel de détail (onglet Tâches)
  Widget _buildProjectCard(
      BuildContext context, Project project, double width) {
    return SizedBox(
      width: width,
      child: EditableProjectShortcutWidget(
        project: project,
        onTap: () => _openDetailPanel(context, project),
        onRename: (newName) {
          final updated = project.copyWith(name: newName.trim());
          _projectService.updateProject(updated);
        },
        onDelete: () => _confirmDelete(context, project),
      ),
    );
  }

  /// Dialogue pour créer un projet
  Future<void> _showCreateProjectDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.darkGreyBackground : theme.colorScheme.surface,
        title: Text(
          'Nouveau projet',
          style:
          theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onBackground),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nom du projet',
                  hintText: 'Entrez un nom',
                  labelStyle: TextStyle(color: theme.colorScheme.onBackground),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.colorScheme.onBackground.withOpacity(0.3),
                    ),
                  ),
                ),
                style: TextStyle(color: theme.colorScheme.onBackground),
                validator: (v) => v == null || v.trim().isEmpty ? 'Le nom est requis' : null,
                autofocus: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(color: theme.colorScheme.onBackground),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              try {
                await _projectService.createProject(
                  Project(
                    id: '',
                    name: nameCtrl.text.trim(),
                    description: '',
                    ownerId: '', // sera géré par le service
                    collaborators: const [],
                    color: null,
                    type: ProjectType.simple,
                  ),
                );
                Navigator.of(c).pop(true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur création : $e")),
                );
              }
            },
            child: Text(
              'Créer',
              style: TextStyle(color: theme.colorScheme.onBackground),
            ),
          ),
        ],
      ),
    );

    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projet créé avec succès')),
      );
    }
  }

  /// Confirmation avant suppression
  Future<void> _confirmDelete(
      BuildContext context, Project project) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor:
        isDark ? AppColors.darkGreyBackground : theme.colorScheme.surface,
        title: Text(
          'Supprimer ce projet ?',
          style:
          theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onBackground),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer « ${project.name} » ?',
          style: TextStyle(color: theme.colorScheme.onBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: Text(
              'Annuler',
              style: TextStyle(color: theme.colorScheme.onBackground),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: Text(
              'Supprimer',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _projectService.deleteProject(project.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projet supprimé')),
      );
    }
  }

  /// Ouvre le ProjectDetailPanel pour modification (onglet Tâches)
  void _openDetailPanel(BuildContext context, Project project) {
    final theme = Theme.of(context);
    final pageBg = theme.scaffoldBackgroundColor;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            child: ProjectDetailPanel(
              project: project,
              initialTab: 1, // toujours sur "Tâches"
              onSave: (updated) => _projectService.updateProject(updated),
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}