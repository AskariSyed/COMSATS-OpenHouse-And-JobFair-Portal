import 'package:student_job_fair_portal/model/student.dart';

class Education {
  final int educationId;
  final int studentId;
  final String institutionName;
  final String degree;
  final String? fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String? gradeType;
  final double? gradeValue;
  final double? marksObtained;
  final double? totalMarks;
  final double? cgpa;
  final String? location;

  Education({
    required this.educationId,
    required this.studentId,
    required this.institutionName,
    required this.degree,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    required this.isCurrent,
    this.gradeType,
    this.gradeValue,
    this.marksObtained,
    this.totalMarks,
    this.cgpa,
    this.location,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      // 🔹 FIX: Use '?? 0' to handle missing studentId without crashing
      educationId: json['educationId'] ?? 0,
      studentId: json['studentId'] ?? 0,

      institutionName: json['institutionName'] ?? '',
      degree: json['degree'] ?? '',
      fieldOfStudy: json['fieldOfStudy'],
      startDate: Student.safeParseDate(json['startDate']),
      endDate: Student.safeParseDate(json['endDate']),
      isCurrent: json['isCurrent'] ?? false,
      gradeType: json['gradeType'],
      gradeValue: (json['gradeValue'] as num?)?.toDouble(),
      marksObtained: (json['marksObtained'] as num?)?.toDouble(),
      totalMarks: (json['totalMarks'] as num?)?.toDouble(),
      cgpa: (json['cgpa'] as num?)?.toDouble(),
      location: json['location'],
    );
  }

  // 🔹 Add copyWith to allow the Provider to fix the ID later
  Education copyWith({
    int? educationId,
    int? studentId,
    String? institutionName,
    String? degree,
    String? fieldOfStudy,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    String? gradeType,
    double? gradeValue,
    double? marksObtained,
    double? totalMarks,
    double? cgpa,
    String? location,
  }) {
    return Education(
      educationId: educationId ?? this.educationId,
      studentId: studentId ?? this.studentId,
      institutionName: institutionName ?? this.institutionName,
      degree: degree ?? this.degree,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      gradeType: gradeType ?? this.gradeType,
      gradeValue: gradeValue ?? this.gradeValue,
      marksObtained: marksObtained ?? this.marksObtained,
      totalMarks: totalMarks ?? this.totalMarks,
      cgpa: cgpa ?? this.cgpa,
      location: location ?? this.location,
    );
  }
}
