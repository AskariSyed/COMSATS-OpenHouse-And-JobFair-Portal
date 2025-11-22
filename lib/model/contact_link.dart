import 'package:student_job_fair_portal/mixins/contactPlatform.dart';
import 'package:student_job_fair_portal/mixins/enums.dart';

class ContactLink {
  final int linkId;
  final int studentId;
  final ContactPlatform platform;
  final String url;

  ContactLink({
    required this.linkId,
    required this.studentId,
    required this.platform,
    required this.url,
  });

  factory ContactLink.fromJson(Map<String, dynamic> json) {
    return ContactLink(
      linkId: json['linkId'] ?? 0,

      // 🔹 FIX: Default to 0 to prevent crash if backend omits this field
      studentId: json['studentId'] ?? 0,

      // Safely parse platform, assuming the mixin handles strings
      platform: contactPlatformFromString(json['platform']?.toString() ?? ''),
      url: json['url'] ?? '',
    );
  }

  // 🔹 ADDED: copyWith method
  // Necessary for the Provider to inject the correct studentId after fetching
  ContactLink copyWith({
    int? linkId,
    int? studentId,
    ContactPlatform? platform,
    String? url,
  }) {
    return ContactLink(
      linkId: linkId ?? this.linkId,
      studentId: studentId ?? this.studentId,
      platform: platform ?? this.platform,
      url: url ?? this.url,
    );
  }
}
