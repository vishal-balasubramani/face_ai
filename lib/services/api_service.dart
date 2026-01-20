import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ⚠️ UPDATE THIS WITH YOUR BACKEND URL
  // For Android Emulator:
  static const String baseUrl = 'http://192.168.137.1:8000';
  
  // For iOS Simulator:
  // static const String baseUrl = 'http://localhost:5000';
  
  // For Physical Device (use your computer's IP):
  // static const String baseUrl = 'http://192.168.1.100:5000';
  
  // For Deployed Backend (Railway/Render):
  // static const String baseUrl = 'https://your-app.railway.app';

  // ============================================
  // SESSION MANAGEMENT
  // ============================================

  Future<bool> saveSession({
    required String studentId,
    required String studentName,
    required DateTime startTime,
    required DateTime endTime,
    required double averageFocus,
    required int totalFrames,
    required String dominantEmotion,
    required Map<String, double> emotionDistribution,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'student_name': studentName,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'average_focus': averageFocus,
          'total_frames': totalFrames,
          'dominant_emotion': dominantEmotion,
          'emotion_distribution': emotionDistribution,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Session saved to backend');
        return true;
      } else {
        print('❌ Failed to save session: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error saving session: $e');
      return false;
    }
  }

  // ============================================
  // SESSION HISTORY
  // ============================================

  Future<List<Map<String, dynamic>>> getSessionHistory(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/sessions/$studentId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Fetched ${data.length} sessions for $studentId');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Failed to fetch history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching history: $e');
      return [];
    }
  }

  // ============================================
  // TOTAL STATISTICS
  // ============================================

  Future<Map<String, dynamic>> getTotalStats(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/stats/$studentId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Stats fetched for $studentId');
        return data;
      } else {
        print('❌ Failed to fetch stats: ${response.statusCode}');
        return {
          'total_sessions': 0,
          'total_frames': 0,
          'average_focus': 0.0,
          'total_time': '0m',
        };
      }
    } catch (e) {
      print('❌ Error fetching stats: $e');
      return {
        'total_sessions': 0,
        'total_frames': 0,
        'average_focus': 0.0,
        'total_time': '0m',
      };
    }
  }

  // ============================================
  // LEADERBOARD
  // ============================================

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/leaderboard'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Leaderboard fetched: ${data.length} students');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ Failed to fetch leaderboard: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching leaderboard: $e');
      return [];
    }
  }

  Future<bool> updateLeaderboardScore({
    required String studentId,
    required String studentName,
    required double focusScore,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/leaderboard/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'student_name': studentName,
          'focus_score': focusScore,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Leaderboard updated for $studentId');
        return true;
      } else {
        print('❌ Failed to update leaderboard: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating leaderboard: $e');
      return false;
    }
  }

  // ============================================
  // HEALTH CHECK
  // ============================================

  Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Backend health check failed: $e');
      return false;
    }
  }
}
