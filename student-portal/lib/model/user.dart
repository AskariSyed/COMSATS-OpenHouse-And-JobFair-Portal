import 'package:student_job_fair_portal/model/student.dart';

class User {
  final int userId;
  final String email;
  final String? fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.userId,
    required this.email,
    this.fullName,
    this.phone,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String roleString;

    // --- THIS IS THE FIX ---
    // Check if 'role' is an int (from profileComplete=false)
    if (json['role'] is int) {
      // Assuming 0=Admin, 1=Student, 2=Company from your C# UserRole enum
      switch (json['role']) {
        case 0:
          roleString = 'Admin';
          break;
        case 1:
          roleString = 'Student';
          break;
        case 2:
          roleString = 'Company';
          break;
        default:
          roleString = 'Student'; // Default fallback
      }
    } else {
      // Otherwise, treat it as a String (from profileComplete=true)
      roleString = json['role'] ?? 'Student';
    }
    // --- END OF FIX ---

    return User(
      userId: json['userId'],
      email: json['email'],
      fullName: json['fullName'],
      phone: json['phone'],
      role: roleString,
      isActive: json['isActive'] ?? false,
      createdAt: Student.safeParseDate(json['createdAt']),
      updatedAt: Student.safeParseDate(json['updatedAt']),
    );
  }

  User copyWith({
    int? userId,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
