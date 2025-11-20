import 'package:student_job_fair_portal/model/student.dart';

class Certification {
  final int certificationId;
  final int studentId;
  final String title;
  final String? issuer;
  final DateTime? issueDate;
  final String? credentialUrl;
  final String? credentialId;

  Certification({
    required this.certificationId,
    required this.studentId,
    required this.title,
    this.issuer,
    this.issueDate,
    this.credentialUrl,
    this.credentialId,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      // 🔹 FIX: Default to 0 to prevent "null is not subtype of int" crash
      certificationId: json['certificationId'] ?? 0,
      studentId: json['studentId'] ?? 0,

      title: json['title'] ?? '',
      issuer: json['issuer'],

      // Safe Date Parsing (Using tryParse is safer than assuming format)
      issueDate: json['issueDate'] != null
          ? DateTime.tryParse(json['issueDate'].toString())
          : null,

      credentialUrl: json['credentialUrl'],
      credentialId: json['credentialId'],
    );
  }

  // 🔹 ADDED: copyWith method
  // This allows the Provider to inject the correct studentId after fetching
  Certification copyWith({
    int? certificationId,
    int? studentId,
    String? title,
    String? issuer,
    DateTime? issueDate,
    String? credentialUrl,
    String? credentialId,
  }) {
    return Certification(
      certificationId: certificationId ?? this.certificationId,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      issuer: issuer ?? this.issuer,
      issueDate: issueDate ?? this.issueDate,
      credentialUrl: credentialUrl ?? this.credentialUrl,
      credentialId: credentialId ?? this.credentialId,
    );
  }
}
