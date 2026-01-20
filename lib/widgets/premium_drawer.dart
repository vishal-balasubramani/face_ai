import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../utils/constants.dart';
import '../screens/focus_stats_screen.dart';
import '../screens/quiz_popup.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/settings_screen.dart';

class PremiumDrawer extends StatelessWidget {
  final String studentId;
  final String studentName;

  const PremiumDrawer({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppConstants.darkBg,
      child: Container(
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
              _buildPremiumProfileHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.home_rounded,
                      title: 'Classroom',
                      subtitle: 'Live session',
                      color: AppConstants.accentCyan,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 12),
                    _buildDrawerItem(
                      context,
                      icon: Icons.analytics_rounded,
                      title: 'My Stats',
                      subtitle: 'Performance analytics',
                      color: AppConstants.accentGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FocusStatsScreen(
                              studentId: studentId,
                              studentName: studentName,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDrawerItem(
                      context,
                      icon: Icons.quiz_rounded,
                      title: 'Take Quiz',
                      subtitle: 'Test your knowledge',
                      color: AppConstants.accentOrange,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDrawerItem(
                      context,
                      icon: Icons.leaderboard_rounded,
                      title: 'Leaderboard',
                      subtitle: 'Rankings & achievements',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LeaderboardScreen(
                              studentId: studentId,
                              studentName: studentName,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      subtitle: 'Preferences & account',
                      color: Colors.grey,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 12),
                    _buildDrawerItem(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get assistance',
                      color: Colors.white70,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Help & Support Coming Soon',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: AppConstants.accentCyan,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppConstants.blueGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppConstants.accentCyan.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with Glow
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow Effect
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    studentName[0].toUpperCase(),
                    style: GoogleFonts.orbitron(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryBlue,
                    ),
                  ),
                ),
              ),
              // Online Badge
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppConstants.accentGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.accentGreen.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            studentName,
            style: GoogleFonts.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // ID Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.badge, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  studentId,
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'AI Classroom v1.0.0',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Powered by Advanced AI',
            style: GoogleFonts.orbitron(
              fontSize: 10,
              color: AppConstants.accentCyan,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
