// lib/features/dashboard/widgets/project_progress_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../projects/models/project_models.dart';
import '../../projects/services/project_service.dart';
import '../../tasks/models/custom_task_model.dart';


class ProjectProgressWidget extends StatefulWidget {
const ProjectProgressWidget({Key? key}) : super(key: key);

@override
_ProjectProgressWidgetState createState() => _ProjectProgressWidgetState();
}

class _ProjectProgressWidgetState extends State<ProjectProgressWidget> {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final ProjectService _projectService = ProjectService();

StreamSubscription<List<Project>>? _projectsSub;
List<_ProjectData> _projectsData = [];
bool _isLoading = true;

@override
void initState() {
super.initState();
_subscribeToProjects();
}

void _subscribeToProjects() {
_projectsSub = _projectService.getProjectsStream().listen(
(projectList) async {
await _loadAllTasks(projectList);
},
onError: (error) {
debugPrint('Erreur stream projets : $error');
if (mounted) {
setState(() => _isLoading = false);
}
},
);
}

Future<void> _loadAllTasks(List<Project> projects) async {
setState(() {
_isLoading = true;
_projectsData = [];
});

final List<_ProjectData> temp = [];
final List<Future<void>> futures = [];

for (final project in projects) {
futures.add(_fetchTasksForProject(project).then((pd) {
if (pd != null) temp.add(pd);
}));
}

await Future.wait(futures);
temp.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

if (mounted) {
setState(() {
_projectsData = temp;
_isLoading = false;
});
}
}

Future<_ProjectData?> _fetchTasksForProject(Project project) async {
try {
final snap = await _firestore
    .collection('projects')
    .doc(project.id)
    .collection('tasks')
    .get();

final tasks = snap.docs
    .map((doc) => CustomTask.fromMap(doc.data(), doc.id))
    .toList();

return _ProjectData(
projectId: project.id,
title: project.name,
tasks: tasks,
);
} catch (e) {
debugPrint('Erreur chargement tâches pour ${project.id}: $e');
return null;
}
}

@override
void dispose() {
_projectsSub?.cancel();
super.dispose();
}

@override
Widget build(BuildContext context) {
if (_isLoading) {
return const Center(child: CircularProgressIndicator());
}
if (_projectsData.isEmpty) {
return const Center(
child: Text(
'Aucun projet trouvé',
style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
),
);
}

return ListView.builder(
padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
itemCount: _projectsData.length,
itemBuilder: (context, index) {
final pd = _projectsData[index];
return _buildProjectCard(pd, context);
},
);
}

Widget _buildProjectCard(_ProjectData pd, BuildContext context) {
final tasks = pd.tasks;
final totalTasks = tasks.length;
final completedTasks = tasks.where((t) => _isTaskCompleted(t)).length;

final progressValue =
(totalTasks > 0) ? (completedTasks / totalTasks) : 0.0;
final progressPct = (progressValue * 100).toStringAsFixed(0) + '% achevé';

return Card(
margin: const EdgeInsets.symmetric(vertical: 8.0),
elevation: 4,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// ───────────
// HEADER TITRE (en majuscules)
// ───────────
Container(
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
),
padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
child: Text(
pd.title.toUpperCase(),
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w700,
color: Theme.of(context).colorScheme.primary,
),
),
),

const SizedBox(height: 12),

// ─────────────────────────────────
// SECTION AVANCEMENT (BARRE + POURCENTAGE)
// ─────────────────────────────────
if (totalTasks > 0)
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16.0),
child: Column(
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text(
'Avancement',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
),
),
Text(
progressPct,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
),
),
],
),
const SizedBox(height: 8),
Container(
decoration: BoxDecoration(
color: Colors.grey[900], // Fond noir autour de la barre
borderRadius: BorderRadius.circular(8),
),
padding: const EdgeInsets.all(2),
child: ClipRRect(
borderRadius: BorderRadius.circular(6),
child: LinearProgressIndicator(
value: progressValue,
minHeight: 12,
backgroundColor: Colors.grey[900], // Fond noir de la barre
valueColor: AlwaysStoppedAnimation<Color>(
Theme.of(context).colorScheme.primary,
),
),
),
),
const SizedBox(height: 12),
],
),
)
else
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16.0),
child: Text(
'Aucune tâche pour ce projet',
style: Theme.of(context)
    .textTheme
    .bodyMedium
    ?.copyWith(fontStyle: FontStyle.italic),
),
),

const Divider(height: 1, thickness: 1),
const SizedBox(height: 8),

// ─────────────────
// SECTION “TÂCHES”
// ─────────────────
if (totalTasks > 0)
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16.0),
child: const Text(
'Détails des tâches',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w600,
),
),
),

if (totalTasks > 0)
const SizedBox(height: 8),

if (totalTasks > 0)
Padding(
padding: const EdgeInsets.only(bottom: 12.0),
child: Column(
children: _buildTaskList(tasks, 0, context),
),
),
],
),
);
}

/// Détermine si [task] est terminée :
/// - si pas de sous‐tâches et que le status vaut "completed" ou "terminé/terminée", ou
/// - si elle a des sous‐tâches et que toutes ses sous‐tâches sont terminées (récursivement).
bool _isTaskCompleted(CustomTask task) {
final lower = task.status.toLowerCase();
if (task.subTasks.isEmpty) {
return lower == 'completed' ||
lower == 'terminé' ||
lower == 'terminee';
} else {
for (final sub in task.subTasks) {
if (!_isTaskCompleted(sub)) return false;
}
return true;
}
}

List<Widget> _buildTaskList(
List<CustomTask> tasks, int indent, BuildContext context) {
final List<Widget> widgets = [];

for (final task in tasks) {
final hasSubtasks = task.subTasks.isNotEmpty;
final int totalSub = hasSubtasks ? task.subTasks.length : 0;
final int completedSub =
hasSubtasks ? _countCompletedImmediateSubtasks(task) : 0;
final int percentSub =
totalSub > 0 ? ((completedSub / totalSub) * 100).round() : 0;

final bool isCompleted = _isTaskCompleted(task);
final icon = isCompleted ? '✅' : '⏺';
final textStyle = isCompleted
? Theme.of(context)
    .textTheme
    .bodyLarge
    ?.copyWith(decoration: TextDecoration.lineThrough)
    : Theme.of(context).textTheme.bodyLarge;

if (hasSubtasks) {
// Si la tâche a des sous‐tâches : ExpansionTile sans fond blanc
widgets.add(
Padding(
padding: EdgeInsets.only(left: indent * 12.0, right: 16.0),
child: Theme(
data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
child: ExpansionTile(
backgroundColor: Colors.transparent,
collapsedBackgroundColor: Colors.transparent,
tilePadding: EdgeInsets.zero,
childrenPadding: EdgeInsets.only(left: (indent + 1) * 12.0, right: 16.0),
title: Row(
children: [
Text(icon, style: const TextStyle(fontSize: 18)),
const SizedBox(width: 6),
Expanded(
child: Text(
task.name,
style: textStyle,
),
),
const SizedBox(width: 6),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 6.0, vertical: 2.0),
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
borderRadius: BorderRadius.circular(6),
),
child: Text(
'$percentSub %',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
color: Theme.of(context).colorScheme.primary,
),
),
),
],
),
children: _buildTaskList(task.subTasks, indent + 1, context),
),
),
),
);
} else {
// Tâche simple (sans sous‐tâches), sans fond blanc
widgets.add(
Padding(
padding: EdgeInsets.only(
left: indent * 12.0, right: 16.0, bottom: 4.0),
child: ListTile(
contentPadding: EdgeInsets.zero,
tileColor: Colors.transparent,
leading: Text(icon, style: const TextStyle(fontSize: 18)),
title: Text(
task.name,
style: textStyle,
),
),
),
);
}

// Séparateur entre les tâches (sauf après la dernière à ce niveau)
if (task != tasks.last) {
widgets.add(const Padding(
padding: EdgeInsets.symmetric(horizontal: 16.0),
child: Divider(height: 1),
));
}
}

return widgets;
}

int _countCompletedImmediateSubtasks(CustomTask task) {
int count = 0;
for (final sub in task.subTasks) {
if (_isTaskCompleted(sub)) count++;
}
return count;
}
}

/// Structure interne pour stocker un projet + ses tâches.
class _ProjectData {
final String projectId;
final String title;
final List<CustomTask> tasks;

_ProjectData({
required this.projectId,
required this.title,
required this.tasks,
});
}
