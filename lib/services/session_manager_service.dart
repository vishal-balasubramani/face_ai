import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/session_data.dart';
import '../models/emotion_response.dart';
import 'api_service.dart';

class SessionManagerService {
  static final SessionManagerService _instance = SessionManagerService._internal();
  factory SessionManagerService() => _instance;
  SessionManagerService._internal();

  final ApiService _apiService = ApiService();
  SessionData? currentSession;
  String? _currentStudentId;
  String? _currentStudentName;

  Future<void> startSession(String studentId, {String? studentName}) async {
    _currentStudentId = studentId;
    _currentStudentName = studentName ?? studentId;
    
    currentSession = SessionData(
      studentId: studentId,
      startTime: DateTime.now(),
    );
    
    await _saveSession();
    print('✅ Session started for: $studentId at ${currentSession!.startTime}');
  }

  Future<void> addEmotionData(EmotionResponse response) async {
    if (currentSession == null) {
      print('⚠️ No active session to add emotion data');
      return;
    }

    currentSession!.addFrame(EmotionFrame(
      emotion: response.emotion,
      focusScore: response.focusScore / 100,
      timestamp: DateTime.now(),
    ));

    await _saveSession();
    print('📊 Frame added: ${response.emotion} (${response.focusScore}%) - Total: ${currentSession!.totalFrames}');
  }

  Future<void> endSession() async {
    if (currentSession == null) {
      print('⚠️ No active session to end');
      return;
    }

    currentSession!.endTime = DateTime.now();
    
    print('🔄 Ending session...');
    print('   Student: ${currentSession!.studentId}');
    print('   Frames: ${currentSession!.totalFrames}');
    print('   Focus: ${(currentSession!.averageFocus * 100).toStringAsFixed(1)}%');
    print('   Duration: ${currentSession!.formattedDuration}');
    
    // Save to backend via API
    final success = await _apiService.saveSession(
      studentId: currentSession!.studentId,
      studentName: _currentStudentName ?? currentSession!.studentId,
      startTime: currentSession!.startTime,
      endTime: currentSession!.endTime!,
      averageFocus: currentSession!.averageFocus,
      totalFrames: currentSession!.totalFrames,
      dominantEmotion: currentSession!.dominantEmotion,
      emotionDistribution: currentSession!.emotionDistribution,
    );

    if (success) {
      print('✅ Session saved to backend successfully');
      
      // Update leaderboard
      final leaderboardSuccess = await _apiService.updateLeaderboardScore(
        studentId: currentSession!.studentId,
        studentName: _currentStudentName ?? currentSession!.studentId,
        focusScore: currentSession!.averageFocus * 100,
      );
      
      if (leaderboardSuccess) {
        print('✅ Leaderboard updated');
      } else {
        print('⚠️ Leaderboard update failed');
      }
    } else {
      print('❌ Failed to save session to backend');
    }

    await _saveSession();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString('current_session');
    
    if (sessionJson != null) {
      try {
        currentSession = SessionData.fromJson(json.decode(sessionJson));
        print('✅ Session loaded from local storage');
      } catch (e) {
        print('❌ Error loading session: $e');
      }
    }
  }

  Future<void> _saveSession() async {
    if (currentSession == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_session', json.encode(currentSession!.toJson()));
  }

  // Get session history from backend
  Future<List<SessionData>> getSessionHistory() async {
    if (_currentStudentId == null) {
      print('⚠️ No student ID for history');
      return [];
    }

    print('📊 Fetching history for: $_currentStudentId');
    final history = await _apiService.getSessionHistory(_currentStudentId!);
    print('📊 Found ${history.length} sessions');
    
    return history.map((data) {
      return SessionData(
        studentId: data['student_id'],
        startTime: DateTime.parse(data['start_time']),
        endTime: data['end_time'] != null ? DateTime.parse(data['end_time']) : null,
        frames: [],
      );
    }).toList();
  }

  // Get total stats from backend
  Future<Map<String, dynamic>> getTotalStats() async {
    if (_currentStudentId == null) {
      print('⚠️ No student ID for stats');
      return {
        'total_sessions': 0,
        'total_frames': 0,
        'average_focus': 0.0,
        'total_time': '0m',
      };
    }

    print('📊 Fetching stats for: $_currentStudentId');
    return await _apiService.getTotalStats(_currentStudentId!);
  }
}
