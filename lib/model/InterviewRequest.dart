import 'package:student_job_fair_portal/mixins/enums.dart';

class InterviewRequest {
  final int requestId;
  final int companyId;
  final String companyName;
  final String? logoUrl;
  final String? industry;
  final RequestStatus status;
  final RequestedBy requestedBy;
  final String? reasonForReject;
  final DateTime requestDate;
  final DateTime? responseDate;

  InterviewRequest({
    required this.requestId,
    required this.companyId,
    required this.companyName,
    this.logoUrl,
    this.industry,
    required this.status,
    required this.requestedBy,
    this.reasonForReject,
    required this.requestDate,
    this.responseDate,
  });

  factory InterviewRequest.fromJson(Map<String, dynamic> json) {
    return InterviewRequest(
      requestId: json['requestId'] ?? 0,
      companyId: json['companyId'] ?? 0,
      companyName: json['companyName'] ?? 'Unknown',
      logoUrl: json['logoUrl'],
      industry: json['industry'],
      status: _parseStatus(json['status']),
      requestedBy: _parseRequestedBy(json['requestedBy']),
      reasonForReject: json['reasonForReject'],
      requestDate:
          DateTime.tryParse(json['requestDate'] ?? '') ?? DateTime.now(),
      responseDate: json['responseDate'] != null
          ? DateTime.tryParse(json['responseDate'])
          : null,
    );
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return RequestStatus.Accepted;
      case 'rejected':
        return RequestStatus.Rejected;
      default:
        return RequestStatus.Pending;
    }
  }

  static RequestedBy _parseRequestedBy(String? by) {
    // Default to Student if missing, assuming most lists are student-initiated
    if (by?.toLowerCase() == 'company') return RequestedBy.Company;
    return RequestedBy.Student;
  }
}
