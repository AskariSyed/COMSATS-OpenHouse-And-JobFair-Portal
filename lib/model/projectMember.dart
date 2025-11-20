class ProjectMember {
  final String fullName;
  final String registrationNo;
  final String role;
  final int status; // 0=Pending, 1=Accepted, 2=Rejected
  final bool isCreator;

  ProjectMember({
    required this.fullName,
    required this.registrationNo,
    required this.role,
    required this.status,
    required this.isCreator,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      fullName: json['fullName'] ?? 'Unknown',
      registrationNo: json['registrationNo'] ?? '',
      role: json['role'] ?? 'Member',
      status: json['status'] ?? 0,
      isCreator: json['isCreator'] ?? false,
    );
  }

  String get statusString {
    switch (status) {
      case 1:
        return "Active";
      case 2:
        return "Rejected";
      default:
        return "Pending";
    }
  }
}
