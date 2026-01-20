import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _keyStudentId = 'student_id';
  static const String _keyStudentName = 'student_name';
  static const String _keySessionHistory = 'session_history';

  Future<void> saveStudentId(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStudentId, studentId);
  }

  Future<String?> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStudentId);
  }

  Future<void> saveStudentName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStudentName, name);
  }

  Future<String?> getStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStudentName);
  }

  Future<void> saveSessionData(Map<String, dynamic> sessionData) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSessionHistory();
    history.add(sessionData);
    
    // Keep only last 10 sessions
    if (history.length > 10) {
      history.removeAt(0);
    }
    
    await prefs.setString(_keySessionHistory, jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>> getSessionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySessionHistory);
    
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
