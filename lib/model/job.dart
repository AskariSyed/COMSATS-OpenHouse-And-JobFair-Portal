import 'package:student_job_fair_portal/mixins/enums.dart';

class JobListResponse {
  final int totalJobs;
  final List<Job> jobs;

  JobListResponse({required this.totalJobs, required this.jobs});

  factory JobListResponse.fromJson(Map<String, dynamic> json) {
    return JobListResponse(
      totalJobs: json['totalJobs'] ?? 0,
      jobs:
          (json['jobs'] as List<dynamic>?)
              ?.map((x) => Job.fromJson(x))
              .toList() ??
          [],
    );
  }
}

class Job {
  final int jobId;
  final int companyId;
  final String companyName;
  final String? companyLogoUrl;
  final String jobTitle;
  final String? jobDescription;
  final List<String> requiredSkills;
  final JobType jobType;
  final int numberOfJobs; // Added field

  Job({
    required this.jobId,
    required this.companyId,
    required this.companyName,
    this.companyLogoUrl,
    required this.jobTitle,
    this.jobDescription,
    required this.requiredSkills,
    required this.jobType,
    required this.numberOfJobs,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    // 1. Extract the nested company object safely
    final companyObj = json['company'] as Map<String, dynamic>?;

    return Job(
      jobId: json['jobId'] ?? 0,

      // Extract companyId from the nested object or root if flattened
      companyId: companyObj?['companyId'] ?? json['companyId'] ?? 0,

      companyName:
          companyObj?['name'] ?? json['companyName'] ?? 'Unknown Company',
      companyLogoUrl: companyObj?['logoUrl'] ?? json['companyLogoUrl'],

      jobTitle: json['jobTitle'] ?? 'Untitled Job',
      jobDescription: json['jobDescription'],

      requiredSkills:
          (json['requiredSkills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],

      // Convert the Integer to the Enum
      jobType: _mapIntToJobType(json['jobType'] ?? 0),

      // Read number of jobs (default to 1 if missing)
      numberOfJobs: json['numberOfJobs'] ?? 1,
    );
  }

  static JobType _mapIntToJobType(int type) {
    switch (type) {
      case 0:
        return JobType.fullTime;
      case 1:
        return JobType.partTime;
      case 2:
        return JobType.internship;
      case 3:
        return JobType.remote;
      case 4:
        return JobType.onsite;
      default:
        return JobType.other;
    }
  }

  String get jobTypeString {
    switch (jobType) {
      case JobType.fullTime:
        return "Full Time";
      case JobType.partTime:
        return "Part Time";
      case JobType.internship:
        return "Internship";
      case JobType.remote:
        return "Remote";
      case JobType.onsite:
        return "Onsite";
      default:
        return "Other";
    }
  }
}
