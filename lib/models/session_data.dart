class SessionData {
  final String studentId;
  final DateTime startTime;
  DateTime? endTime;
  final List<EmotionFrame> frames;
  final Map<String, int> emotionCounts;
  double averageFocus;
  int totalFrames;

  SessionData({
    required this.studentId,
    required this.startTime,
    this.endTime,
    List<EmotionFrame>? frames,
    Map<String, int>? emotionCounts,
    this.averageFocus = 0.0,
    this.totalFrames = 0,
  })  : frames = frames ?? [],
        emotionCounts = emotionCounts ?? {};

  // Add a new emotion frame
  void addFrame(EmotionFrame frame) {
    frames.add(frame);
    totalFrames++;

    // Update emotion counts
    emotionCounts[frame.emotion] = (emotionCounts[frame.emotion] ?? 0) + 1;

    // Recalculate average focus
    if (frames.isNotEmpty) {
      averageFocus = frames.map((f) => f.focusScore).reduce((a, b) => a + b) / frames.length;
    }
  }

  // Get session duration in seconds
  int get durationSeconds {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds;
  }

  // Get session duration formatted
  String get formattedDuration {
    final duration = durationSeconds;
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Get dominant emotion (most frequent)
  String get dominantEmotion {
    if (emotionCounts.isEmpty) return 'neutral';
    
    return emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get emotion distribution as percentages
  Map<String, double> get emotionDistribution {
    if (totalFrames == 0) return {};
    
    return emotionCounts.map(
      (emotion, count) => MapEntry(emotion, (count / totalFrames) * 100.0),
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'frames': frames.map((f) => f.toJson()).toList(),
      'emotion_counts': emotionCounts,
      'average_focus': averageFocus,
      'total_frames': totalFrames,
      'duration_seconds': durationSeconds,
    };
  }

  // Create from JSON (local storage)
  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      studentId: json['student_id'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      frames: (json['frames'] as List<dynamic>?)
          ?.map((f) => EmotionFrame.fromJson(f as Map<String, dynamic>))
          .toList(),
      emotionCounts: Map<String, int>.from(json['emotion_counts'] ?? {}),
      averageFocus: (json['average_focus'] ?? 0.0).toDouble(),
      totalFrames: json['total_frames'] ?? 0,
    );
  }

  // Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'duration': formattedDuration,
      'total_frames': totalFrames,
      'average_focus': averageFocus,
      'dominant_emotion': dominantEmotion,
      'emotion_distribution': emotionDistribution,
      'peak_focus': frames.isEmpty 
          ? 0.0 
          : frames.map((f) => f.focusScore).reduce((a, b) => a > b ? a : b),
      'lowest_focus': frames.isEmpty 
          ? 0.0 
          : frames.map((f) => f.focusScore).reduce((a, b) => a < b ? a : b),
    };
  }

  // Format duration for display (shorter version)
  String get shortDuration {
    final duration = durationSeconds;
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get focus level label
  String get focusLevel {
    if (averageFocus >= 0.9) return 'Excellent';
    if (averageFocus >= 0.8) return 'Very Good';
    if (averageFocus >= 0.7) return 'Good';
    if (averageFocus >= 0.6) return 'Average';
    if (averageFocus >= 0.5) return 'Below Average';
    return 'Needs Improvement';
  }

  // Get focus percentage as integer
  int get focusPercentage => (averageFocus * 100).round();

  // Check if session is active
  bool get isActive => endTime == null;

  // Get all unique emotions detected
  List<String> get detectedEmotions => emotionCounts.keys.toList();

  // Get emotion frequency (sorted by count)
  List<MapEntry<String, int>> get sortedEmotions {
    final entries = emotionCounts.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

class EmotionFrame {
  final String emotion;
  final double focusScore;
  final DateTime timestamp;
  final double? confidence;
  final String? recommendation;

  EmotionFrame({
    required this.emotion,
    required this.focusScore,
    required this.timestamp,
    this.confidence,
    this.recommendation,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'focus_score': focusScore,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'recommendation': recommendation,
    };
  }

  // Create from JSON
  factory EmotionFrame.fromJson(Map<String, dynamic> json) {
    return EmotionFrame(
      emotion: json['emotion'] ?? 'neutral',
      focusScore: (json['focus_score'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      confidence: json['confidence'] != null 
          ? (json['confidence'] as num).toDouble() 
          : null,
      recommendation: json['recommendation'],
    );
  }

  // Get focus score as percentage
  int get focusPercentage => (focusScore * 100).round();

  // Get time elapsed since frame capture
  Duration get timeSinceCapture => DateTime.now().difference(timestamp);

  // Format timestamp
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  // Check if emotion is positive
  bool get isPositiveEmotion {
    return ['happy', 'focused', 'surprised', 'excited'].contains(emotion.toLowerCase());
  }

  // Check if emotion indicates distraction
  bool get isDistracted {
    return ['bored', 'confused', 'sleepy', 'distracted'].contains(emotion.toLowerCase());
  }

  // Get emoji for emotion
  String get emoji {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'surprised':
        return '😲';
      case 'neutral':
        return '😐';
      case 'focused':
        return '🎯';
      case 'confused':
        return '😕';
      case 'bored':
        return '😴';
      default:
        return '😐';
    }
  }
}
