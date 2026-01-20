import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const LeaderboardScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;
  int? _currentUserRank;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.getLeaderboard();
      
      final currentUserIndex = data.indexWhere(
        (entry) => entry['student_id'] == widget.studentId,
      );

      setState(() {
        _leaderboardData = data;
        _currentUserRank = currentUserIndex >= 0 ? currentUserIndex + 1 : null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.darkBg,
              AppConstants.primaryBlue.withOpacity(0.2),
              AppConstants.darkBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_currentUserRank != null) _buildCurrentUserCard(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppConstants.accentCyan,
                        ),
                      )
                    : _leaderboardData.isEmpty
                        ? _buildEmptyState()
                        : _buildLeaderboardList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppConstants.accentCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Global Leaderboard',
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppConstants.accentCyan),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    final userData = _leaderboardData.firstWhere(
      (entry) => entry['student_id'] == widget.studentId,
      orElse: () => {},
    );

    if (userData.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppConstants.blueGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.accentCyan.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Center(
              child: Text(
                '#$_currentUserRank',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rank',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  widget.studentName,
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${userData['avg_focus'].toStringAsFixed(1)}%',
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Avg Focus',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList() {
    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      color: AppConstants.accentCyan,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaderboardData.length,
        itemBuilder: (context, index) {
          final entry = _leaderboardData[index];
          final rank = entry['rank'];
          final isCurrentUser = entry['student_id'] == widget.studentId;

          return _buildLeaderboardCard(
            rank: rank,
            studentName: entry['student_name'],
            avgFocus: entry['avg_focus'].toDouble(),
            sessionCount: entry['session_count'],
            totalFrames: entry['total_frames'],
            isCurrentUser: isCurrentUser,
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardCard({
    required int rank,
    required String studentName,
    required double avgFocus,
    required int sessionCount,
    required int totalFrames,
    required bool isCurrentUser,
  }) {
    Color getRankColor() {
      if (rank == 1) return const Color(0xFFFFD700); // Gold
      if (rank == 2) return const Color(0xFFC0C0C0); // Silver
      if (rank == 3) return const Color(0xFFCD7F32); // Bronze
      return AppConstants.accentCyan;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppConstants.accentCyan.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentUser
              ? AppConstants.accentCyan.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: getRankColor().withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: getRankColor(), width: 2),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: getRankColor(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sessionCount sessions • $totalFrames frames',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${avgFocus.toStringAsFixed(1)}%',
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.accentGreen,
                ),
              ),
              Text(
                'Focus',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Leaderboard Data',
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete sessions to appear on the leaderboard',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
