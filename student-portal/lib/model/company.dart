import 'package:student_job_fair_portal/model/job.dart';

class CompanyListResponse {
  final int jobFairId;
  final int totalCompanies;
  final int page;
  final int pageSize;
  final int totalPages;
  final List<Company> companies;

  CompanyListResponse({
    required this.jobFairId,
    required this.totalCompanies,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.companies,
  });

  factory CompanyListResponse.fromJson(Map<String, dynamic> json) {
    return CompanyListResponse(
      jobFairId: json['jobFairId'] ?? 0,
      totalCompanies: json['totalCompanies'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 8,
      totalPages: json['totalPages'] ?? 1,
      companies:
          (json['companies'] as List<dynamic>?)
              ?.map((x) => Company.fromJson(x))
              .toList() ??
          [],
    );
  }
}

// 🔹 NEW: Helper Class for Interview Status
class CompanyInterviewStatus {
  final int requestId;
  final String status; // Pending, Accepted, Rejected
  final String requestedBy; // Student, Company
  final String? currentInterviewStatus;
  final DateTime? interviewScheduledTime;
  final String? interviewRoom;

  CompanyInterviewStatus({
    required this.requestId,
    required this.status,
    required this.requestedBy,
    this.currentInterviewStatus,
    this.interviewScheduledTime,
    this.interviewRoom,
  });

  factory CompanyInterviewStatus.fromJson(Map<String, dynamic> json) {
    return CompanyInterviewStatus(
      requestId: json['requestId'] ?? 0,
      status: json['status'] ?? 'Pending',
      requestedBy: json['requestedBy'] ?? 'Student',
      currentInterviewStatus: json['currentInterviewStatus'],
      interviewScheduledTime: json['interviewScheduledTime'] != null
          ? DateTime.tryParse(json['interviewScheduledTime'].toString())
          : null,
      interviewRoom: json['interviewRoom'],
    );
  }
}

class CompanyLatestInterview {
  final int interviewId;
  final String status;
  final DateTime? scheduledTime;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? room;

  CompanyLatestInterview({
    required this.interviewId,
    required this.status,
    this.scheduledTime,
    this.startedAt,
    this.endedAt,
    this.room,
  });

  factory CompanyLatestInterview.fromJson(Map<String, dynamic> json) {
    return CompanyLatestInterview(
      interviewId: json['interviewId'] ?? 0,
      status: json['status'] ?? 'Queued',
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.tryParse(json['scheduledTime'].toString())
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'].toString())
          : null,
      room: json['room'],
    );
  }
}

class Company {
  final int companyId;
  final String name;
  final String? description;
  final String? industry;
  final String? logoUrl;
  final String? website;
  final String? companyEmail;
  final String? companyPhone;
  final String? address;
  final String focalPersonName;
  final String focalPersonEmail;
  final String focalPersonPhone;
  final int repsCount;
  final int interviewDurationMinutes;
  final int arrivalStatus;
  final int jobCount;
  final List<Job> jobs;

  // 🔹 NEW FIELDS
  final bool canRequestInterview;
  final bool isWalkInInterviewing;
  final CompanyInterviewStatus? interviewRequest;
  final CompanyLatestInterview? latestInterview;
  final bool isInterviewWindowOpen;
  final DateTime? interviewCutoffLocal;

  Company({
    required this.companyId,
    required this.name,
    this.description,
    this.industry,
    this.logoUrl,
    this.website,
    this.companyEmail,
    this.companyPhone,
    this.address,
    required this.focalPersonName,
    required this.focalPersonEmail,
    required this.focalPersonPhone,
    required this.repsCount,
    required this.interviewDurationMinutes,
    required this.arrivalStatus,
    required this.jobCount,
    required this.jobs,
    this.canRequestInterview = true,
    this.isWalkInInterviewing = false,
    this.interviewRequest,
    this.latestInterview,
    this.isInterviewWindowOpen = true,
    this.interviewCutoffLocal,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      companyId: json['companyId'] ?? 0,
      name: json['name'] ?? 'Unknown Company',
      description: json['description'],
      industry: json['industry'],
      logoUrl: json['logoUrl'],
      website: json['website'],
      companyEmail: json['companyEmail'],
      companyPhone: json['companyPhone'],
      address: json['address'],
      focalPersonName: json['focalPersonName'] ?? '',
      focalPersonEmail: json['focalPersonEmail'] ?? '',
      focalPersonPhone: json['focalPersonPhone'] ?? '',
      repsCount: json['repsCount'] ?? 0,
      interviewDurationMinutes: json['interviewDurationMinutes'] ?? 0,
      arrivalStatus: _parseArrivalStatus(json['arrivalStatus']),
      jobCount: json['jobCount'] ?? 0,
      jobs:
          (json['jobs'] as List<dynamic>?)
              ?.map((x) => Job.fromJson(x))
              .toList() ??
          [],

      // 🔹 Parse New Fields
      canRequestInterview: json['canRequestInterview'] ?? true,
      isWalkInInterviewing: json['isWalkInInterviewing'] ?? false,
      interviewRequest: json['interviewRequest'] != null
          ? CompanyInterviewStatus.fromJson(json['interviewRequest'])
          : null,
    );
  }

  static int _parseArrivalStatus(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      if (value.toLowerCase() == 'onspot') return 1;
      return 0;
    }
    return 0;
  }
}

class CompanyDetail {
  final int companyId;
  final String name;
  final String? description;
  final String? industry;
  final String? logoUrl;
  final String? website;
  final String? address;
  final String? email;
  final String? phone;
  final int interviewDurationMinutes;
  final int repsCount;
  final String? focalPersonName;

  final List<CompanyContactLink> contactLinks;
  final int totalJobs;
  final List<Job> jobs;
  final List<String> uniqueSkillsRequired;
  final int arrivalStatus;

  // 🔹 NEW FIELDS
  final bool canRequestInterview;
  final bool isWalkInInterviewing;
  final CompanyInterviewStatus? interviewRequest;
  final CompanyLatestInterview? latestInterview;
  final bool isInterviewWindowOpen;
  final DateTime? interviewCutoffLocal;

  bool get isPresent => arrivalStatus == 1;

  CompanyDetail({
    required this.companyId,
    required this.name,
    this.description,
    this.industry,
    this.logoUrl,
    this.website,
    this.address,
    this.email,
    this.phone,
    required this.interviewDurationMinutes,
    required this.repsCount,
    this.focalPersonName,
    required this.contactLinks,
    required this.totalJobs,
    required this.jobs,
    required this.uniqueSkillsRequired,
    this.arrivalStatus = 0,
    this.canRequestInterview = true,
    this.isWalkInInterviewing = false,
    this.interviewRequest,
    this.latestInterview,
    this.isInterviewWindowOpen = true,
    this.interviewCutoffLocal,
  });

  factory CompanyDetail.fromJson(Map<String, dynamic> json) {
    final contactObj = json['companyContact'] as Map<String, dynamic>?;

    return CompanyDetail(
      companyId: json['companyId'] ?? 0,
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      industry: json['industry'],
      logoUrl: json['logoUrl'],
      website: json['website'],
      address: json['address'],
      email: contactObj?['email'] ?? json['companyEmail'],
      phone: contactObj?['phone'] ?? json['companyPhone'],
      interviewDurationMinutes: json['interviewDurationMinutes'] ?? 0,
      repsCount: json['repsCount'] ?? 0,
      focalPersonName: json['focalPersonName'],
      arrivalStatus: Company._parseArrivalStatus(json['arrivalStatus']),
      contactLinks:
          (json['contactLinks'] as List<dynamic>?)
              ?.map((x) => CompanyContactLink.fromJson(x))
              .toList() ??
          [],
      totalJobs: json['totalJobs'] ?? 0,
      jobs:
          (json['jobs'] as List<dynamic>?)
              ?.map((x) => Job.fromJson(x))
              .toList() ??
          [],
      uniqueSkillsRequired:
          (json['uniqueSkillsRequired'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],

      // 🔹 Parse New Fields
      canRequestInterview: json['canRequestInterview'] ?? true,
      isWalkInInterviewing: json['isWalkInInterviewing'] ?? false,
      interviewRequest: json['interviewRequest'] != null
          ? CompanyInterviewStatus.fromJson(json['interviewRequest'])
          : null,
      latestInterview: json['latestInterview'] != null
          ? CompanyLatestInterview.fromJson(json['latestInterview'])
          : null,
      isInterviewWindowOpen: json['isInterviewWindowOpen'] ?? true,
      interviewCutoffLocal: json['interviewCutoffLocal'] != null
          ? DateTime.tryParse(json['interviewCutoffLocal'].toString())
          : null,
    );
  }
}

class CompanyContactLink {
  final int linkId;
  final String platform;
  final String url;

  CompanyContactLink({
    required this.linkId,
    required this.platform,
    required this.url,
  });

  factory CompanyContactLink.fromJson(Map<String, dynamic> json) {
    return CompanyContactLink(
      linkId: json['linkId'] ?? 0,
      platform: json['platform'] ?? 'Web',
      url: json['url'] ?? '',
    );
  }
}
