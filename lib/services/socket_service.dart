import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../utils/constants.dart';
import '../models/emotion_response.dart';

class SocketService {
  WebSocketChannel? _channel;
  Function(EmotionResponse)? onEmotionReceived;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void connect(String studentId) {
    try {
      print('🔌 Connecting to: ${AppConstants.wsStudentUrl}');
      
      _channel = IOWebSocketChannel.connect(
        Uri.parse(AppConstants.wsStudentUrl),
      );
      
      _isConnected = true;
      print('✅ WebSocket connected!');
      onConnected?.call();
      
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            final response = EmotionResponse.fromJson(data);
            onEmotionReceived?.call(response);
          } catch (e) {
            print('❌ Error parsing message: $e');
          }
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _isConnected = false;
          onError?.call(error.toString());
        },
        onDone: () {
          print('🔌 WebSocket disconnected');
          _isConnected = false;
          onDisconnected?.call();
        },
      );
    } catch (e) {
      print('❌ Connection failed: $e');
      _isConnected = false;
      onError?.call(e.toString());
    }
  }

  void sendFrame(String studentId, String base64Image) {
    if (_channel != null && _isConnected) {
      final message = jsonEncode({
        'student_id': studentId,
        'image': base64Image,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _channel!.sink.add(message);
      print('📤 Frame sent for $studentId');
    } else {
      print('⚠️ Not connected. Cannot send frame.');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    print('👋 Disconnected from server');
  }
}
