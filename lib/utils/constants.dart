import 'package:flutter/material.dart';

class AppConstants {
  // ============================================
  // BACKEND CONFIGURATION
  // ============================================
  
  // ⚠️ UPDATE THIS WITH YOUR BACKEND URL

  // For Android Emulator (FastAPI on localhost:8000)
  static const String backendUrl = 'http://192.168.137.243:8000';
 
  static String get wsStudentUrl => backendUrl.replaceFirst('http', 'ws') + '/ws/student';
  static String get wsDashboardUrl => backendUrl.replaceFirst('http', 'ws') + '/ws/dashboard';
  
  // ============================================
  // SESSION CONFIGURATION
  // ============================================
  
  static const String defaultSessionId = 'default_session';
  static const Duration frameInterval = Duration(seconds: 2); // Send frame every 2 seconds
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const int maxReconnectAttempts = 5;
  
  // ============================================
  // COLORS - Dark Theme
  // ============================================
  
  // Primary Colors
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  
  // Background Colors
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkSurface = Color(0xFF1E293B);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textTertiary = Color(0xFF94A3B8);
  
  // ============================================
  // GRADIENTS
  // ============================================
  
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============================================
  // EMOTION MAPPINGS
  // ============================================
  
  // Emotion Colors
  static Color getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return const Color(0xFF10B981); // Green
      case 'focused':
      case 'attentive':
        return accentCyan; // Cyan
      case 'surprise':
      case 'surprised':
        return const Color(0xFFF59E0B); // Orange
      case 'neutral':
      case 'calm':
        return const Color(0xFF6B7280); // Gray
      case 'sad':
      case 'sadness':
        return const Color(0xFF3B82F6); // Blue
      case 'fear':
      case 'anxious':
        return const Color(0xFF8B5CF6); // Purple
      case 'angry':
      case 'anger':
        return accentRed; // Red
      case 'disgust':
        return const Color(0xFFEC4899); // Pink
      case 'confused':
        return const Color(0xFFFBBF24); // Yellow
      case 'bored':
        return const Color(0xFF9CA3AF); // Light Gray
      default:
        return Colors.grey;
    }
  }
  
  // Emotion Emojis
  static String getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return '😊';
      case 'focused':
      case 'attentive':
        return '🎯';
      case 'surprise':
      case 'surprised':
        return '😲';
      case 'neutral':
      case 'calm':
        return '😐';
      case 'sad':
      case 'sadness':
        return '😢';
      case 'fear':
      case 'anxious':
        return '😰';
      case 'angry':
      case 'anger':
        return '😠';
      case 'disgust':
        return '🤢';
      case 'confused':
        return '😕';
      case 'bored':
        return '😴';
      case 'excited':
        return '🤩';
      case 'thinking':
        return '🤔';
      default:
        return '😐';
    }
  }
  
  // Emotion Labels (Human Readable)
  static String getEmotionLabel(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return 'Happy';
      case 'focused':
        return 'Focused';
      case 'surprise':
        return 'Surprised';
      case 'neutral':
        return 'Neutral';
      case 'sad':
        return 'Sad';
      case 'fear':
        return 'Fearful';
      case 'angry':
        return 'Angry';
      case 'disgust':
        return 'Disgusted';
      case 'confused':
        return 'Confused';
      case 'bored':
        return 'Bored';
      default:
        return emotion.toUpperCase();
    }
  }
  
  // ============================================
  // FOCUS LEVEL MAPPINGS
  // ============================================
  
  static Color getFocusColor(double focusScore) {
    if (focusScore >= 0.8) return accentGreen;
    if (focusScore >= 0.6) return accentCyan;
    if (focusScore >= 0.4) return accentOrange;
    return accentRed;
  }
  
  static String getFocusLabel(double focusScore) {
    if (focusScore >= 0.9) return 'OUTSTANDING';
    if (focusScore >= 0.8) return 'EXCELLENT';
    if (focusScore >= 0.7) return 'VERY GOOD';
    if (focusScore >= 0.6) return 'GOOD';
    if (focusScore >= 0.5) return 'AVERAGE';
    if (focusScore >= 0.4) return 'BELOW AVERAGE';
    return 'NEEDS FOCUS';
  }
  
  static IconData getFocusIcon(double focusScore) {
    if (focusScore >= 0.8) return Icons.emoji_events;
    if (focusScore >= 0.6) return Icons.thumb_up;
    if (focusScore >= 0.4) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }
  
  // ============================================
  // UI CONSTANTS
  // ============================================
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;
  
  // Spacing
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  
  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // ============================================
  // QUIZ CONFIGURATION
  // ============================================
  
  static const String quizApiUrl = 'https://opentdb.com/api.php?amount=5&category=18&difficulty=medium&type=multiple';
  static const int quizQuestionCount = 5;
  static const int quizTimeLimit = 60; // seconds per question
  
  // ============================================
  // APP INFORMATION
  // ============================================
  
  static const String appName = 'AI Classroom';
  static const String appVersion = '2.0.0';
  static const String appDescription = 'Real-time emotion detection and engagement tracking';
  static const String poweredBy = 'Powered by Advanced AI';
  
  // ============================================
  // HELPER METHODS
  // ============================================
  
  // Format duration
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
  
  // Format percentage
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
  
  // Get connection status color
  static Color getConnectionColor(bool isConnected) {
    return isConnected ? accentGreen : accentRed;
  }
  
  // Get connection status text
  static String getConnectionText(bool isConnected) {
    return isConnected ? 'Connected' : 'Disconnected';
  }
  
  // Validate backend URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
