class TaskFolder {
  String id;
  String name;
  String projectId;
  String? parentId;

  TaskFolder({
    this.id = '',
    required this.name,
    required this.projectId,
    this.parentId,
  });

  factory TaskFolder.fromMap(Map<String, dynamic> data, String documentId) {
    return TaskFolder(
      id: documentId,
      name: data['name'] ?? '',
      projectId: data['projectId'] ?? '',
      parentId: data['parentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'projectId': projectId,
      'parentId': parentId,
    };
  }
}
