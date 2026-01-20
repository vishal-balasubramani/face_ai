class EmotionResponse {
  final String emotion;
  final double engagementScore;
  final int focusScore;
  final String recommendation;
  final String timestamp;

  EmotionResponse({
    required this.emotion,
    required this.engagementScore,
    required this.focusScore,
    required this.recommendation,
    required this.timestamp,
  });

  factory EmotionResponse.fromJson(Map<String, dynamic> json) {
    return EmotionResponse(
      emotion: json['emotion']?.toString() ?? 'unknown',
      engagementScore: _parseDouble(json['engagement_score']),
      focusScore: _parseInt(json['focus_score']),
      recommendation: json['recommendation']?.toString() ?? 'Stay focused!',
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  // Helper to safely parse double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper to safely parse int
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'engagement_score': engagementScore,
      'focus_score': focusScore,
      'recommendation': recommendation,
      'timestamp': timestamp,
    };
  }
}
