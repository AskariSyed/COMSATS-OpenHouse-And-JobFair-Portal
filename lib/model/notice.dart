class Notice {
  final int noticeId;
  final String title;
  final String content;
  final String audience;
  final DateTime createdAt;

  Notice({
    required this.noticeId,
    required this.title,
    required this.content,
    required this.audience,
    required this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      noticeId: json['noticeId'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      audience: json['audience'] ?? 'All',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noticeId': noticeId,
      'title': title,
      'content': content,
      'audience': audience,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
