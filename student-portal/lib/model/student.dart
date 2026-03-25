import 'package:student_job_fair_portal/mixins/contactPlatform.dart';
import 'package:student_job_fair_portal/model/achievement.dart';
import 'package:student_job_fair_portal/model/certification.dart';
import 'package:student_job_fair_portal/model/contact_link.dart';
import 'package:student_job_fair_portal/model/education.dart';
import 'package:student_job_fair_portal/model/experience.dart';
import 'package:student_job_fair_portal/model/project.dart';
import 'package:student_job_fair_portal/model/user.dart';

class Student {
  // --- Nested User Object ---
  final User user;

  // --- Student-Specific Fields ---
  final int studentId;
  final String registrationNo;
  final String? profilePicUrl;
  final String? cvUrl;
  final String? department;
  final double cgpa;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // --- FYP Fields (Derived) ---
  final String? fypTitle;
  final String? fypDescription;
  final String? fypDemoUrl;
  final String? fypGithubUrl;

  // --- Profile Lists ---
  final List<String> skills;
  final List<Project> projects; // 👈 Updated Type
  final List<ContactLink> contactLinks;
  final List<Experience> experiences;
  final List<Education> educations;
  final List<Achievement> achievements;
  final List<Certification> certifications;

  Student({
    required this.user,
    required this.studentId,
    required this.registrationNo,
    this.profilePicUrl,
    this.cvUrl,
    this.department,
    required this.cgpa,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
    this.fypTitle,
    this.fypDescription,
    this.fypDemoUrl,
    this.fypGithubUrl,
    required this.projects,
    required this.skills,
    required this.contactLinks,
    required this.experiences,
    required this.educations,
    required this.achievements,
    required this.certifications,
  });

  // Helper to safely parse DateTime
  static DateTime? safeParseDate(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Helper to read values regardless of backend key casing.
  static dynamic _pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }
    return null;
  }

  // Helper to safely parse lists
  static List<T> _parseList<T>(
    Map<String, dynamic> json,
    List<String> keys,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _pick(json, keys);
    if (raw == null || raw is! List) return [];
    return raw.map((item) => fromJson(item as Map<String, dynamic>)).toList();
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    // 1. Parse Projects List First
    List<Project> parsedProjects = _parseList(json, [
      'projects',
      'Projects',
    ], Project.fromJson);

    // 2. Extract FYP Data from the projects list if it exists
    Project? fypData;
    try {
      fypData = parsedProjects.firstWhere(
        (p) => p.type == ProjectType.FinalYear,
      );
    } catch (_) {
      fypData = null;
    }

    // 3. Parse Links (handling both formats)
    List<ContactLink> parsedLinks = [];
    final contactLinksRaw = _pick(json, ['contactLinks', 'ContactLinks']);
    if (contactLinksRaw != null) {
      parsedLinks = _parseList(json, [
        'contactLinks',
        'ContactLinks',
      ], ContactLink.fromJson);
    } else if (_pick(json, ['links', 'Links']) is Map) {
      final linksMap = (_pick(json, ['links', 'Links']) as Map)
          .cast<String, dynamic>();
      linksMap.forEach((key, value) {
        parsedLinks.add(
          ContactLink(
            linkId: 0,
            studentId: (_pick(json, ['studentId', 'StudentId']) as int?) ?? 0,
            platform: contactPlatformFromString(key),
            url: value,
          ),
        );
      });
    }

    return Student(
      user: User.fromJson(
        (_pick(json, ['user', 'User']) as Map<String, dynamic>?) ?? {},
      ),
      studentId: (_pick(json, ['studentId', 'StudentId']) as int?) ?? 0,
      registrationNo:
          (_pick(json, ['registrationNo', 'RegistrationNo']) as String?) ?? '',
      profilePicUrl: _pick(json, ['profilePicUrl', 'ProfilePicUrl']) as String?,
      cvUrl: _pick(json, ['cvUrl', 'CvUrl']) as String?,
      department: _pick(json, ['department', 'Department']) as String?,
      cgpa: ((_pick(json, ['cgpa', 'CGPA']) as num?)?.toDouble()) ?? 0.0,
      fcmToken: _pick(json, ['fcmToken', 'FcmToken']) as String?,
      createdAt: safeParseDate(
        (_pick(json, ['createdAt', 'CreatedAt']) as String?),
      ),
      updatedAt: safeParseDate(
        (_pick(json, ['updatedAt', 'UpdatedAt']) as String?),
      ),

      // Derived FYP Fields
      fypTitle: fypData?.title,
      fypDescription: fypData?.description,
      fypDemoUrl: fypData?.demoUrl,
      fypGithubUrl: fypData?.gitHubUrl,

      // Lists
      projects: parsedProjects,
      skills: ((_pick(json, ['skills', 'Skills']) as List?) ?? [])
          .map((s) => s.toString())
          .toList(),
      contactLinks: parsedLinks,
      experiences: _parseList(json, [
        'experiences',
        'Experiences',
      ], Experience.fromJson),
      educations: _parseList(json, [
        'educations',
        'Educations',
      ], Education.fromJson),
      achievements: _parseList(json, [
        'achievements',
        'Achievements',
      ], Achievement.fromJson),
      certifications: _parseList(json, [
        'certifications',
        'Certifications',
      ], Certification.fromJson),
    );
  }

  Student copyWith({
    User? user,
    int? studentId,
    String? registrationNo,
    String? profilePicUrl,
    String? cvUrl,
    String? department,
    double? cgpa,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fypTitle,
    String? fypDescription,
    String? fypDemoUrl,
    String? fypGithubUrl,
    List<Project>? projects,
    List<String>? skills,
    List<ContactLink>? contactLinks,
    List<Experience>? experiences,
    List<Education>? educations,
    List<Achievement>? achievements,
    List<Certification>? certifications,
  }) {
    return Student(
      user: user ?? this.user,
      studentId: studentId ?? this.studentId,
      registrationNo: registrationNo ?? this.registrationNo,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      cvUrl: cvUrl ?? this.cvUrl,
      department: department ?? this.department,
      cgpa: cgpa ?? this.cgpa,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fypTitle: fypTitle ?? this.fypTitle,
      fypDescription: fypDescription ?? this.fypDescription,
      fypDemoUrl: fypDemoUrl ?? this.fypDemoUrl,
      fypGithubUrl: fypGithubUrl ?? this.fypGithubUrl,
      projects: projects ?? this.projects,
      skills: skills ?? this.skills,
      contactLinks: contactLinks ?? this.contactLinks,
      experiences: experiences ?? this.experiences,
      educations: educations ?? this.educations,
      achievements: achievements ?? this.achievements,
      certifications: certifications ?? this.certifications,
    );
  }
}
