class QuizModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final QuizDifficulty difficulty;
  final String category;
  final int timeLimit; // seconds
  final int points;

  QuizModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.difficulty = QuizDifficulty.medium,
    this.category = 'General',
    this.timeLimit = 30,
    this.points = 10,
  });

  // Check if answer is correct
  bool isCorrect(int selectedIndex) {
    return selectedIndex == correctIndex;
  }

  // Get correct answer text
  String get correctAnswer {
    return options[correctIndex];
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct_index': correctIndex,
      'explanation': explanation,
      'difficulty': difficulty.name,
      'category': category,
      'time_limit': timeLimit,
      'points': points,
    };
  }

  // Create from JSON
  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correct_index'] ?? 0,
      explanation: json['explanation'] ?? '',
      difficulty: QuizDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => QuizDifficulty.medium,
      ),
      category: json['category'] ?? 'General',
      timeLimit: json['time_limit'] ?? 30,
      points: json['points'] ?? 10,
    );
  }
}

enum QuizDifficulty {
  easy,
  medium,
  hard,
}

class QuizAttempt {
  final String quizId;
  final String studentId;
  final int selectedIndex;
  final bool isCorrect;
  final DateTime attemptTime;
  final int timeTaken; // seconds
  final int pointsEarned;

  QuizAttempt({
    required this.quizId,
    required this.studentId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.attemptTime,
    required this.timeTaken,
    required this.pointsEarned,
  });

  Map<String, dynamic> toJson() {
    return {
      'quiz_id': quizId,
      'student_id': studentId,
      'selected_index': selectedIndex,
      'is_correct': isCorrect,
      'attempt_time': attemptTime.toIso8601String(),
      'time_taken': timeTaken,
      'points_earned': pointsEarned,
    };
  }

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      quizId: json['quiz_id'] ?? '',
      studentId: json['student_id'] ?? '',
      selectedIndex: json['selected_index'] ?? 0,
      isCorrect: json['is_correct'] ?? false,
      attemptTime: DateTime.parse(json['attempt_time']),
      timeTaken: json['time_taken'] ?? 0,
      pointsEarned: json['points_earned'] ?? 0,
    );
  }
}

class QuizStatistics {
  final int totalAttempts;
  final int correctAttempts;
  final int wrongAttempts;
  final int totalPoints;
  final double averageTimeTaken;
  final Map<String, int> categoryWiseScore;

  QuizStatistics({
    this.totalAttempts = 0,
    this.correctAttempts = 0,
    this.wrongAttempts = 0,
    this.totalPoints = 0,
    this.averageTimeTaken = 0.0,
    Map<String, int>? categoryWiseScore,
  }) : categoryWiseScore = categoryWiseScore ?? {};

  double get accuracy {
    if (totalAttempts == 0) return 0.0;
    return (correctAttempts / totalAttempts) * 100;
  }

  String get accuracyText {
    return '${accuracy.toStringAsFixed(1)}%';
  }

  Map<String, dynamic> toJson() {
    return {
      'total_attempts': totalAttempts,
      'correct_attempts': correctAttempts,
      'wrong_attempts': wrongAttempts,
      'total_points': totalPoints,
      'average_time_taken': averageTimeTaken,
      'accuracy': accuracy,
      'category_wise_score': categoryWiseScore,
    };
  }

  factory QuizStatistics.fromJson(Map<String, dynamic> json) {
    return QuizStatistics(
      totalAttempts: json['total_attempts'] ?? 0,
      correctAttempts: json['correct_attempts'] ?? 0,
      wrongAttempts: json['wrong_attempts'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
      averageTimeTaken: (json['average_time_taken'] ?? 0.0).toDouble(),
      categoryWiseScore: Map<String, int>.from(json['category_wise_score'] ?? {}),
    );
  }
}
