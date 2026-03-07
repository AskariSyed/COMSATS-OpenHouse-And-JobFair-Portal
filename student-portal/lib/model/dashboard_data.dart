class DashboardData {
  final StudentProfileSummary studentProfile;
  final MarketOverview marketOverview;
  final ActionsRequired actionsRequired;
  final InterviewStats interviewStats;
  final List<RecommendedJob> recommendedJobs;
  final List<NoticeSummary> notices;

  DashboardData({
    required this.studentProfile,
    required this.marketOverview,
    required this.actionsRequired,
    required this.interviewStats,
    required this.recommendedJobs,
    required this.notices,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      studentProfile: StudentProfileSummary.fromJson(
        json['studentProfile'] ?? {},
      ),
      marketOverview: MarketOverview.fromJson(json['marketOverview'] ?? {}),
      actionsRequired: ActionsRequired.fromJson(json['actionsRequired'] ?? {}),
      interviewStats: InterviewStats.fromJson(json['interviewStats'] ?? {}),
      recommendedJobs:
          (json['recommendedJobs'] as List<dynamic>?)
              ?.map((e) => RecommendedJob.fromJson(e))
              .toList() ??
          [],
      notices:
          (json['notices'] as List<dynamic>?)
              ?.map((e) => NoticeSummary.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class RecommendedJob {
  final int jobId;
  final int companyId;
  final String jobTitle;
  final String companyName;
  final String? companyLogo;
  final int matchCount;
  final List<String> matchedSkills;

  RecommendedJob({
    required this.jobId,
    required this.companyId,
    required this.jobTitle,
    required this.companyName,
    this.companyLogo,
    required this.matchCount,
    required this.matchedSkills,
  });

  factory RecommendedJob.fromJson(Map<String, dynamic> json) {
    return RecommendedJob(
      jobId: json['jobId'] ?? 0,
      companyId: json['companyId'] ?? 0,
      jobTitle: json['jobTitle'] ?? '',
      companyName: json['companyName'] ?? '',
      companyLogo: json['companyLogo'],
      matchCount: json['matchCount'] ?? 0,
      matchedSkills:
          (json['matchedSkills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class StudentProfileSummary {
  final String name;
  final String registrationNo;
  final String? profilePicUrl;
  final int completeness;
  final bool isRegisteredForFair;

  StudentProfileSummary({
    required this.name,
    required this.registrationNo,
    this.profilePicUrl,
    required this.completeness,
    required this.isRegisteredForFair,
  });

  factory StudentProfileSummary.fromJson(Map<String, dynamic> json) {
    return StudentProfileSummary(
      name: json['name'] ?? '',
      registrationNo: json['registrationNo'] ?? '',
      profilePicUrl: json['profilePicUrl'],
      completeness: json['completeness'] ?? 0,
      isRegisteredForFair: json['isRegisteredForFair'] ?? false,
    );
  }
}

class MarketOverview {
  final String? activeFairSemester;
  final int totalCompanies;
  final int totalJobs;

  MarketOverview({
    this.activeFairSemester,
    required this.totalCompanies,
    required this.totalJobs,
  });

  factory MarketOverview.fromJson(Map<String, dynamic> json) {
    return MarketOverview(
      activeFairSemester: json['activeFairSemester'],
      totalCompanies: json['totalCompanies'] ?? 0,
      totalJobs: json['totalJobs'] ?? 0,
    );
  }
}

class ActionsRequired {
  final int pendingInterviewRequestsCount;
  final int pendingProjectInvitesCount;

  ActionsRequired({
    required this.pendingInterviewRequestsCount,
    required this.pendingProjectInvitesCount,
  });

  factory ActionsRequired.fromJson(Map<String, dynamic> json) {
    return ActionsRequired(
      pendingInterviewRequestsCount: json['pendingInterviewRequestsCount'] ?? 0,
      pendingProjectInvitesCount: json['pendingProjectInvitesCount'] ?? 0,
    );
  }
}

class InterviewStats {
  final List<InterviewRequestSummary> pendingRequests;
  final List<InterviewRequestSummary> acceptedRequests;
  final List<InterviewSummary> allInterviews;
  final InterviewSummary? nextInterview;

  InterviewStats({
    required this.pendingRequests,
    required this.acceptedRequests,
    required this.allInterviews,
    this.nextInterview,
  });

  factory InterviewStats.fromJson(Map<String, dynamic> json) {
    return InterviewStats(
      pendingRequests:
          (json['pendingRequests'] as List<dynamic>?)
              ?.map((e) => InterviewRequestSummary.fromJson(e))
              .toList() ??
          [],
      acceptedRequests:
          (json['acceptedRequests'] as List<dynamic>?)
              ?.map((e) => InterviewRequestSummary.fromJson(e))
              .toList() ??
          [],
      allInterviews:
          (json['allInterviews'] as List<dynamic>?)
              ?.map((e) => InterviewSummary.fromJson(e))
              .toList() ??
          [],
      nextInterview: json['nextInterview'] != null
          ? InterviewSummary.fromJson(json['nextInterview'])
          : null,
    );
  }
}

class InterviewRequestSummary {
  final int requestId;
  final String companyName;
  final String? companyLogo;
  final String? requestedBy;
  final DateTime? date;

  InterviewRequestSummary({
    required this.requestId,
    required this.companyName,
    this.companyLogo,
    this.requestedBy,
    this.date,
  });

  factory InterviewRequestSummary.fromJson(Map<String, dynamic> json) {
    return InterviewRequestSummary(
      requestId: json['requestId'] ?? 0,
      companyName: json['companyName'] ?? '',
      companyLogo: json['companyLogo'],
      requestedBy: json['requestedBy'],
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
    );
  }
}

class InterviewSummary {
  final int interviewId;
  final String companyName;
  final String? companyLogo;
  final DateTime? scheduledTime;
  final String status;

  InterviewSummary({
    required this.interviewId,
    required this.companyName,
    this.companyLogo,
    this.scheduledTime,
    required this.status,
  });

  factory InterviewSummary.fromJson(Map<String, dynamic> json) {
    return InterviewSummary(
      interviewId: json['interviewId'] ?? 0,
      companyName: json['companyName'] ?? '',
      companyLogo: json['companyLogo'],
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.tryParse(json['scheduledTime'])
          : null,
      status: json['status'] ?? '',
    );
  }
}

class NoticeSummary {
  final int noticeId;
  final String title;
  final DateTime? createdAt;
  final String content;

  NoticeSummary({
    required this.noticeId,
    required this.title,
    this.createdAt,
    required this.content,
  });

  factory NoticeSummary.fromJson(Map<String, dynamic> json) {
    return NoticeSummary(
      noticeId: json['noticeId'] ?? 0,
      title: json['title'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      content: json['content'] ?? '',
    );
  }
}
