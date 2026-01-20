class StudentProfile {
  final String studentId;
  final String name;
  final String sessionId;

  StudentProfile({
    required this.studentId,
    required this.name,
    required this.sessionId,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      studentId: json['student_id'] ?? '',
      name: json['name'] ?? 'Student',
      sessionId: json['session_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'name': name,
      'session_id': sessionId,
    };
  }
}
