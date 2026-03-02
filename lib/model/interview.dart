class Interview {
  final int interviewId;
  final String companyName;
  final String? companyLogo;
  final DateTime? scheduledTime;
  final int? durationMinutes;
  final String room;
  final String status;

  Interview({
    required this.interviewId,
    required this.companyName,
    this.companyLogo,
    this.scheduledTime,
    this.durationMinutes,
    required this.room,
    required this.status,
  });

  factory Interview.fromJson(Map<String, dynamic> json) {
    return Interview(
      interviewId: json['interviewId'],
      companyName: json['companyName'],
      companyLogo: json['companyLogo'],
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'])
          : null,
      durationMinutes: json['durationMinutes'],
      room: json['room'] ?? 'TBD',
      status: json['status'] ?? 'Queued',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interviewId': interviewId,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'room': room,
      'status': status,
    };
  }
}
