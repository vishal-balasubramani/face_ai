import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../utils/constants.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _particleController;
  late AnimationController _iconController;
  final List<Particle> _particles = [];

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.psychology_rounded,
      title: 'AI-Powered Learning',
      description: 'Advanced emotion detection tracks your engagement in real-time using cutting-edge AI technology',
      color: AppConstants.accentCyan,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppConstants.accentCyan, AppConstants.primaryBlue],
      ),
      features: [
        'Real-time emotion detection',
        'Smart engagement tracking',
        'Instant feedback system',
      ],
    ),
    OnboardingPage(
      icon: Icons.trending_up_rounded,
      title: 'Track Your Focus',
      description: 'Get instant feedback on your attention levels and receive personalized recommendations to stay engaged',
      color: AppConstants.accentGreen,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppConstants.accentGreen, const Color(0xFF34D399)],
      ),
      features: [
        'Focus score analytics',
        'Personalized insights',
        'Performance trends',
      ],
    ),
    OnboardingPage(
      icon: Icons.emoji_events_rounded,
      title: 'Achieve More',
      description: 'View detailed analytics, compete on leaderboards, and unlock achievements as you learn and grow',
      color: AppConstants.accentOrange,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppConstants.accentOrange, const Color(0xFFFBBF24)],
      ),
      features: [
        'Interactive leaderboards',
        'Achievement system',
        'Progress tracking',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _initializeParticles();
    _iconController.forward();
  }

  void _initializeParticles() {
    final random = Random();
    for (int i = 0; i < 40; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 4 + 2,
          speedX: (random.nextDouble() - 0.5) * 0.0003,
          speedY: (random.nextDouble() - 0.5) * 0.0003,
          opacity: random.nextDouble() * 0.4 + 0.2,
        ),
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _iconController.reset();
    _iconController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _skipToLogin() {
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _particleController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Particle Effect
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  animationValue: _particleController.value,
                  color: _pages[_currentPage].color,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPageContent(_pages[index]);
                    },
                  ),
                ),
                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0E27),
            _pages[_currentPage].color.withOpacity(0.3),
            const Color(0xFF0A0E27),
            _pages[_currentPage].color.withOpacity(0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo/Brand
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _pages[_currentPage].gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Classroom',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Skip Button
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skipToLogin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'SKIP',
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon with Glow
          AnimatedBuilder(
            animation: _iconController,
            builder: (context, child) {
              return Transform.scale(
                scale: Curves.elasticOut.transform(_iconController.value),
                child: Transform.rotate(
                  angle: (_iconController.value - 1) * 0.3,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: page.color.withOpacity(0.5),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: page.gradient,
                      ),
                      child: Icon(
                        page.icon,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 60),

          // Title with Gradient
          ShaderMask(
            shaderCallback: (bounds) => page.gradient.createShader(bounds),
            child: Text(
              page.title,
              style: GoogleFonts.orbitron(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Feature Cards
          _buildFeatureCards(page),
        ],
      ),
    );
  }

  Widget _buildFeatureCards(OnboardingPage page) {
    return Column(
      children: page.features.map((feature) {
        final index = page.features.indexOf(feature);
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 600 + (index * 100)),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: page.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: page.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: page.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    feature,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Page Indicators
          _buildPageIndicators(),
          const SizedBox(height: 32),

          // Action Button
          _buildActionButton(),

          const SizedBox(height: 16),

          // Progress Text
          Text(
            '${_currentPage + 1} of ${_pages.length}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        bool isActive = index == _currentPage;
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isActive ? 40 : 12,
            height: 12,
            decoration: BoxDecoration(
              gradient: isActive
                  ? _pages[_currentPage].gradient
                  : null,
              color: isActive ? null : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: _pages[_currentPage].color.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: _pages[_currentPage].gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _pages[_currentPage].color.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _nextPage,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentPage == _pages.length - 1 ? 'GET STARTED' : 'CONTINUE',
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Onboarding Page Model
class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Gradient gradient;
  final List<String> features;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.gradient,
    required this.features,
  });
}

// Particle Class
class Particle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });

  void update() {
    x += speedX;
    y += speedY;

    if (x < 0) x = 1;
    if (x > 1) x = 0;
    if (y < 0) y = 1;
    if (y > 1) y = 0;
  }
}

// Particle Painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = color.withOpacity(particle.opacity * 0.6)
        ..style = PaintingStyle.fill;

      final position = Offset(
        particle.x * size.width,
        particle.y * size.height,
      );

      // Draw particle
      canvas.drawCircle(position, particle.size, paint);

      // Draw glow
      final glowPaint = Paint()
        ..color = color.withOpacity(particle.opacity * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(position, particle.size * 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
