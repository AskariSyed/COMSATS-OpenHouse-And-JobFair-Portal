class Achievement {
  final int achievementId;
  final int studentId;
  final String title;
  final String? description;
  final DateTime dateAchieved;

  Achievement({
    required this.achievementId,
    required this.studentId,
    required this.title,
    this.description,
    required this.dateAchieved,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      achievementId: json['achievementId'] ?? 0,

      // 🔹 FIX: Default to 0 to prevent "null is not subtype of int" crash
      studentId: json['studentId'] ?? 0,

      title: json['title'] ?? '',
      description: json['description'],

      // Safe Date Parsing
      dateAchieved: json['dateAchieved'] != null
          ? DateTime.tryParse(json['dateAchieved'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // 🔹 ADDED: copyWith method
  // Necessary for the Provider to inject the correct studentId after fetching
  Achievement copyWith({
    int? achievementId,
    int? studentId,
    String? title,
    String? description,
    DateTime? dateAchieved,
  }) {
    return Achievement(
      achievementId: achievementId ?? this.achievementId,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      description: description ?? this.description,
      dateAchieved: dateAchieved ?? this.dateAchieved,
    );
  }
}
