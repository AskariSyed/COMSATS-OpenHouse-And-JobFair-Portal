class ProjectInvitation {
  final int id; // The StudentProject ID (Invite ID)
  final int projectId;
  final String projectTitle;
  final String type;
  final String? description;

  ProjectInvitation({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.type,
    this.description,
  });

  factory ProjectInvitation.fromJson(Map<String, dynamic> json) {
    return ProjectInvitation(
      id: json['id'] ?? 0,
      projectId: json['projectId'] ?? 0,
      projectTitle: json['projectTitle'] ?? 'Unknown Project',
      type: json['type'].toString(),
      description: json['description'],
    );
  }
}
