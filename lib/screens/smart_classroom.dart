import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/socket_service.dart';
import '../services/camera_service.dart';
import '../services/session_manager_service.dart';
import '../models/emotion_response.dart';
import '../utils/constants.dart';
import '../widgets/premium_drawer.dart';
import 'focus_stats_screen.dart';
import 'settings_screen.dart';
import 'quiz_popup.dart';
import 'leaderboard_screen.dart';

class SmartClassroomScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const SmartClassroomScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<SmartClassroomScreen> createState() => _SmartClassroomScreenState();
}

class _SmartClassroomScreenState extends State<SmartClassroomScreen>
    with TickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final CameraService _cameraService = CameraService();
  final SessionManagerService _sessionManager = SessionManagerService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  // State variables
  String _currentEmotion = 'Ready';
  double _focusScore = 0.0;
  String _recommendation = 'Position your face in camera...';
  bool _isConnected = false;
  bool _isCameraReady = false;
  Timer? _frameTimer;
  int _sessionDuration = 0;
  Timer? _durationTimer;
  int _totalFrames = 0;
  int _streakCount = 0;
  bool _isSheetExpanded = false;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _shimmerController;
  late Animation<double> _progressAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(_shimmerController);

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Start session with student name
    await _sessionManager.startSession(
      widget.studentId,
      studentName: widget.studentName,
    );
    
    final cameras = await availableCameras();
    final cameraSuccess = await _cameraService.initialize(cameras);
    if (cameraSuccess && mounted) {
      setState(() => _isCameraReady = true);
    }

    _connectToBackend();
    _startFrameCapture();
    _startSessionTimer();
  }

  void _connectToBackend() {
    _socketService.onConnected = () {
      if (mounted) {
        setState(() => _isConnected = true);
        _showSnackbar('✅ AI Engine Connected', AppConstants.accentGreen);
      }
    };

    _socketService.onDisconnected = () {
      if (mounted) {
        setState(() => _isConnected = false);
        _showSnackbar('❌ Connection Lost', AppConstants.accentRed);
      }
    };

    _socketService.onEmotionReceived = (EmotionResponse response) async {
      if (mounted) {
        await _sessionManager.addEmotionData(response);
        
        if (response.focusScore >= 70) {
          setState(() => _streakCount++);
        } else {
          setState(() => _streakCount = 0);
        }
        
        double newScore = response.focusScore / 100.0;
        _progressAnimation = Tween<double>(
          begin: _focusScore,
          end: newScore,
        ).animate(CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeInOutCubic,
        ));
        
        _progressController.forward(from: 0);
        
        setState(() {
          _currentEmotion = response.emotion;
          _focusScore = newScore;
          _recommendation = response.recommendation;
          _totalFrames++;
        });
      }
    };

    _socketService.onError = (error) {
      _showSnackbar('⚠️ Connection Error', AppConstants.accentOrange);
    };

    _socketService.connect(widget.studentId);
  }

  void _startFrameCapture() {
    _frameTimer = Timer.periodic(AppConstants.frameInterval, (timer) async {
      if (!_isCameraReady || !_isConnected) return;
      final base64Frame = await _cameraService.captureFrame();
      if (base64Frame != null) {
        _socketService.sendFrame(widget.studentId, base64Frame);
      }
    });
  }

  void _startSessionTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _sessionDuration++);
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppConstants.accentGreen ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.poppins(fontSize: 14))),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getFocusColor() {
    if (_focusScore >= 0.8) return AppConstants.accentGreen;
    if (_focusScore >= 0.6) return AppConstants.accentCyan;
    if (_focusScore >= 0.4) return AppConstants.accentOrange;
    return AppConstants.accentRed;
  }

  String _getFocusLabel() {
    if (_focusScore >= 0.9) return 'OUTSTANDING';
    if (_focusScore >= 0.8) return 'EXCELLENT';
    if (_focusScore >= 0.6) return 'GOOD';
    if (_focusScore >= 0.4) return 'AVERAGE';
    return 'NEEDS FOCUS';
  }

  // END SESSION HANDLER
  Future<void> _handleEndSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: AppConstants.accentRed),
            const SizedBox(width: 12),
            Text(
              'End Session?',
              style: GoogleFonts.orbitron(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your session data will be saved:',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildSessionSummary(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('End Session', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppConstants.darkCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppConstants.accentCyan),
                const SizedBox(height: 20),
                Text(
                  'Saving session...',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );

      // End session
      print('🔚 Ending session from button...');
      await _sessionManager.endSession();

      // Close loading
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        _showSnackbar('✅ Session saved successfully!', AppConstants.accentGreen);

        // Navigate back after delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  Widget _buildSessionSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(Icons.timer, 'Duration', _formatDuration(_sessionDuration)),
          const SizedBox(height: 8),
          _buildSummaryRow(Icons.videocam, 'Frames', '$_totalFrames'),
          const SizedBox(height: 8),
          _buildSummaryRow(Icons.trending_up, 'Avg Focus', '${(_focusScore * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.accentCyan, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      drawer: PremiumDrawer(
        studentId: widget.studentId,
        studentName: widget.studentName,
      ),
      body: Stack(
        children: [
          _buildFullScreenCamera(),
          _buildTopOverlay(),
          _buildDraggableBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildFullScreenCamera() {
    if (!_isCameraReady || _cameraService.controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppConstants.accentCyan),
              const SizedBox(height: 20),
              Text(
                'Initializing Camera...',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Please allow camera access',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraService.controller!.value.previewSize!.height,
          height: _cameraService.controller!.value.previewSize!.width,
          child: CameraPreview(_cameraService.controller!),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildGlassButton(
              icon: Icons.menu_rounded,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppConstants.accentGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_sessionDuration),
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isConnected 
                    ? AppConstants.accentGreen 
                    : AppConstants.accentRed,
                  width: 2,
                ),
              ),
              child: Icon(
                _isConnected ? Icons.wifi : Icons.wifi_off,
                color: _isConnected 
                  ? AppConstants.accentGreen 
                  : AppConstants.accentRed,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.black.withOpacity(0.5),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableBottomSheet() {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        setState(() {
          _isSheetExpanded = notification.extent > 0.4;
        });
        return true;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.25,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.25, 0.9],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppConstants.darkBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: _isSheetExpanded 
              ? _buildExpandedContent(scrollController) 
              : _buildCollapsedContent(scrollController),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedContent(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Center(
          child: Text(
            '↑  Swipe up for details  ↑',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  AppConstants.getEmotionEmoji(_currentEmotion),
                  _currentEmotion.toUpperCase(),
                  AppConstants.getEmotionColor(_currentEmotion),
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return _buildQuickStat(
                      '${(_progressAnimation.value * 100).toInt()}%',
                      'FOCUS',
                      _getFocusColor(),
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildQuickStat(
                  '$_streakCount',
                  'STREAK',
                  AppConstants.accentOrange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Text(
          'LIVE ANALYSIS',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            color: AppConstants.accentCyan,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
        _buildFocusCard(),
        const SizedBox(height: 20),
        _buildEmotionDetailCard(),
        const SizedBox(height: 20),
        _buildStatsGrid(),
        const SizedBox(height: 20),
        _buildRecommendationCard(),
        const SizedBox(height: 20),
        _buildActionButtons(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildFocusCard() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getFocusColor().withOpacity(0.2),
                _getFocusColor().withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getFocusColor().withOpacity(0.5), width: 2),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(_getFocusColor()),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: GoogleFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOCUS LEVEL',
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        color: Colors.grey,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFocusLabel(),
                      style: GoogleFonts.orbitron(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _getFocusColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmotionDetailCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.getEmotionColor(_currentEmotion).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppConstants.getEmotionColor(_currentEmotion).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                AppConstants.getEmotionEmoji(_currentEmotion),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DETECTED EMOTION',
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    color: Colors.grey,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentEmotion.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.getEmotionColor(_currentEmotion),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            Icons.videocam,
            'Frames',
            '$_totalFrames',
            AppConstants.accentCyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            Icons.local_fire_department,
            'Streak',
            '$_streakCount',
            AppConstants.accentOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.yellow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.yellow, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _recommendation,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FocusStatsScreen(
                        studentId: widget.studentId,
                        studentName: widget.studentName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: Text('Stats', style: GoogleFonts.poppins(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentCyan,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuizScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.quiz),
                label: Text('Quiz', style: GoogleFonts.poppins(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaderboardScreen(
                    studentId: widget.studentId,
                    studentName: widget.studentName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.leaderboard, color: AppConstants.accentGreen),
            label: Text(
              'Leaderboard',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppConstants.accentGreen,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppConstants.accentGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // END SESSION BUTTON
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleEndSession,
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            label: Text(
              'End Session',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentRed,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    print('🔚 SmartClassroomScreen dispose() called');
    _frameTimer?.cancel();
    _durationTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    
    // End session on dispose (when navigating back)
    _sessionManager.endSession();
    
    _socketService.disconnect();
    _cameraService.dispose();
    super.dispose();
  }
}

