enum ProjectType { Semester, Freelance, FinalYear, Other }

enum ProjectInviteStatus { Pending, Accepted, Rejected }
// lib/model/project.dart

class Project {
  final int projectId;
  final String title;
  final ProjectType type;
  final String? description;
  final String? skills;
  final String? clientName;
  final String? supervisor;
  final String? demoUrl;
  final String? gitHubUrl;
  final DateTime? startDate;
  final DateTime? endDate;

  // 🔹 New Fields from GetProfile Response
  final String? currentStudentRole;
  final ProjectInviteStatus currentStudentStatus;
  final bool currentStudentIsCreator; // Determines if Edit is allowed
  final List<ProjectPartner> partners; // List of other members

  Project({
    required this.projectId,
    required this.title,
    required this.type,
    this.description,
    this.skills,
    this.clientName,
    this.supervisor,
    this.demoUrl,
    this.gitHubUrl,
    this.startDate,
    this.endDate,
    this.currentStudentRole,
    this.currentStudentStatus = ProjectInviteStatus.Pending,
    this.currentStudentIsCreator = false,
    this.partners = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['projectId'] ?? 0,
      title: json['title'] ?? '',
      type: _parseProjectType(json['type']),
      description: json['description'],
      skills: json['skills'],
      clientName: json['clientName'],
      supervisor: json['supervisor'],
      demoUrl: json['demoUrl'],
      gitHubUrl: json['gitHubUrl'],
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,

      // 🔹 Parse New Fields
      currentStudentRole: json['currentStudentRole'],
      currentStudentStatus: _parseStatus(json['currentStudentStatus']),
      currentStudentIsCreator: json['currentStudentIsCreator'] ?? false,

      // 🔹 Parse Partners
      partners:
          (json['partners'] as List<dynamic>?)
              ?.map((m) => ProjectPartner.fromJson(m))
              .toList() ??
          [],
    );
  }

  static ProjectType _parseProjectType(dynamic type) {
    if (type is int) return ProjectType.values[type];
    switch (type.toString()) {
      case 'Semester':
        return ProjectType.Semester;
      case 'Freelance':
        return ProjectType.Freelance;
      case 'FinalYear':
        return ProjectType.FinalYear;
      default:
        return ProjectType.Other;
    }
  }

  static ProjectInviteStatus _parseStatus(dynamic status) {
    switch (status.toString()) {
      case 'Accepted':
        return ProjectInviteStatus.Accepted;
      case 'Rejected':
        return ProjectInviteStatus.Rejected;
      default:
        return ProjectInviteStatus.Pending;
    }
  }
}

// 🔹 New Model for Partners inside Project
class ProjectPartner {
  final int studentId;
  final String name;
  final String registrationNo;
  final String role;
  final String status;
  final bool isCreator;
  final String? profilePicUrl;

  ProjectPartner({
    required this.studentId,
    required this.name,
    required this.registrationNo,
    required this.role,
    required this.status,
    required this.isCreator,
    this.profilePicUrl,
  });

  factory ProjectPartner.fromJson(Map<String, dynamic> json) {
    return ProjectPartner(
      studentId: json['studentId'] ?? 0,
      name: json['name'] ?? 'Unknown',
      registrationNo: json['registrationNo'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      isCreator: json['isCreator'] ?? false,
      profilePicUrl: json['profilePicUrl'],
    );
  }
}

class StudentProject {
  final int id; // Invite ID or Join ID
  final int studentId;
  final String fullName;
  final String registrationNo;
  final String role;
  final bool isCreator;
  final ProjectInviteStatus status;

  StudentProject({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.registrationNo,
    required this.role,
    required this.isCreator,
    required this.status,
  });

  factory StudentProject.fromJson(Map<String, dynamic> json) {
    return StudentProject(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      fullName: json['fullName'] ?? 'Unknown',
      registrationNo: json['registrationNo'] ?? '',
      role: json['role'] ?? 'Member',
      isCreator: json['isCreator'] ?? false,
      status: _parseStatus(json['status']),
    );
  }

  static ProjectInviteStatus _parseStatus(dynamic status) {
    if (status is int) return ProjectInviteStatus.values[status];
    switch (status.toString()) {
      case 'Accepted':
        return ProjectInviteStatus.Accepted;
      case 'Rejected':
        return ProjectInviteStatus.Rejected;
      default:
        return ProjectInviteStatus.Pending;
    }
  }
}
