class Interview {
  final int interviewId;
  final int? companyId;
  final String companyName;
  final String? companyLogo;
  final DateTime? scheduledTime;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final String room;
  final String status;

  Interview({
    required this.interviewId,
    this.companyId,
    required this.companyName,
    this.companyLogo,
    this.scheduledTime,
    this.startedAt,
    this.endedAt,
    this.durationMinutes,
    required this.room,
    required this.status,
  });

  factory Interview.fromJson(Map<String, dynamic> json) {
    return Interview(
      interviewId: json['interviewId'],
      companyId: json['companyId'],
      companyName: json['companyName'],
      companyLogo: json['companyLogo'],
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      durationMinutes: json['durationMinutes'],
      room: json['room'] ?? 'TBD',
      status: json['status'] ?? 'Queued',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interviewId': interviewId,
      'companyId': companyId,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'room': room,
      'status': status,
    };
  }
}
