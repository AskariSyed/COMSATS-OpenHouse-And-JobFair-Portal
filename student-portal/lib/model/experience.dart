class Experience {
  final int experienceId;
  final int studentId;
  final String companyName;
  final String role;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? location;

  Experience({
    required this.experienceId,
    required this.studentId,
    required this.companyName,
    required this.role,
    this.description,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
    this.location,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      experienceId: json['experienceId'] ?? 0,

      // 🔹 FIX: Default to 0 to prevent "null is not subtype of int" crash
      studentId: json['studentId'] ?? 0,

      companyName: json['companyName'] ?? '',
      role: json['role'] ?? '',
      description: json['description'],

      // Safer Date Parsing
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),

      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,

      isCurrent: json['isCurrent'] ?? false,
      location: json['location'],
    );
  }

  // 🔹 ADDED: copyWith for Provider updates
  Experience copyWith({
    int? experienceId,
    int? studentId,
    String? companyName,
    String? role,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    String? location,
  }) {
    return Experience(
      experienceId: experienceId ?? this.experienceId,
      studentId: studentId ?? this.studentId,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      location: location ?? this.location,
    );
  }
}
