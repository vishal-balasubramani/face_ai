import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../utils/constants.dart';
import '../services/quiz_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedOption;
  bool _showResult = false;
  int _score = 0;
  bool _isLoading = true;
  bool _quizCompleted = false;

  late AnimationController _scaleController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    
    final apiQuestions = await _quizService.getQuestions(limit: 5);
    
    List<Map<String, dynamic>> parsedQuestions = [];
    for (var q in apiQuestions) {
      parsedQuestions.add(_quizService.parseQuestion(q));
    }
    
    setState(() {
      _questions = parsedQuestions;
      _isLoading = false;
    });
    
    _scaleController.forward();
  }

  void _nextQuestion() {
    if (_selectedOption == null) return;

    // Check answer
    final correctIndex = _questions[_currentQuestionIndex]['correct_index'];
    if (_selectedOption == correctIndex) {
      _score++;
    }

    setState(() => _showResult = true);

    // Move to next question after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedOption = null;
          _showResult = false;
        });
        _progressController.forward(from: 0);
      } else {
        setState(() => _quizCompleted = true);
      }
    });
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOption = null;
      _showResult = false;
      _score = 0;
      _quizCompleted = false;
    });
    _loadQuestions();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_quizCompleted) {
      return _buildResultScreen();
    }

    return _buildQuizScreen();
  }

  Widget _buildLoadingScreen() {
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppConstants.accentCyan),
              const SizedBox(height: 24),
              Text(
                'Loading Quiz Questions...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fetching CS questions',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final question = currentQuestion['question'] as String;
    final options = currentQuestion['options'] as List<String>;
    final correctIndex = currentQuestion['correct_index'] as int;

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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildQuestionCard(question),
                      const SizedBox(height: 24),
                      ...List.generate(options.length, (index) {
                        return _buildOptionCard(
                          index,
                          options[index],
                          correctIndex,
                        );
                      }),
                      const SizedBox(height: 24),
                      if (!_showResult) _buildNextButton(),
                      if (_showResult) _buildResultIndicator(correctIndex),
                    ],
                  ),
                ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppConstants.blueGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.accentGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.accentGreen),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.yellow, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Score: $_score',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String question) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.accentCyan.withOpacity(0.1),
            AppConstants.primaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppConstants.accentCyan.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.accentCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.help_outline,
              color: AppConstants.accentCyan,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              question,
              style: GoogleFonts.poppins(
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index, String option, int correctIndex) {
    bool isSelected = _selectedOption == index;
    bool isCorrect = index == correctIndex;

    Color getBackgroundColor() {
      if (!_showResult) {
        return isSelected
            ? AppConstants.accentCyan.withOpacity(0.2)
            : Colors.white.withOpacity(0.05);
      }
      if (isCorrect) return AppConstants.accentGreen.withOpacity(0.2);
      if (isSelected && !isCorrect) return AppConstants.accentRed.withOpacity(0.2);
      return Colors.white.withOpacity(0.05);
    }

    Color getBorderColor() {
      if (!_showResult) {
        return isSelected ? AppConstants.accentCyan : Colors.white.withOpacity(0.1);
      }
      if (isCorrect) return AppConstants.accentGreen;
      if (isSelected && !isCorrect) return AppConstants.accentRed;
      return Colors.white.withOpacity(0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showResult ? null : () {
            setState(() => _selectedOption = index);
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: getBackgroundColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: getBorderColor(), width: 2),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected && !_showResult
                        ? AppConstants.accentCyan
                        : _showResult && isCorrect
                            ? AppConstants.accentGreen
                            : _showResult && isSelected
                                ? AppConstants.accentRed
                                : Colors.white.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (_showResult && (isCorrect || (isSelected && !isCorrect)))
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppConstants.accentGreen
                          : AppConstants.accentRed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCorrect ? Icons.check : Icons.close,
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

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _selectedOption == null
            ? LinearGradient(colors: [Colors.grey, Colors.grey])
            : AppConstants.blueGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectedOption == null ? null : _nextQuestion,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              _currentQuestionIndex == _questions.length - 1
                  ? 'FINISH QUIZ'
                  : 'NEXT QUESTION',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultIndicator(int correctIndex) {
    final isCorrect = _selectedOption == correctIndex;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCorrect
              ? [
                  AppConstants.accentGreen.withOpacity(0.3),
                  AppConstants.accentGreen.withOpacity(0.1),
                ]
              : [
                  AppConstants.accentRed.withOpacity(0.3),
                  AppConstants.accentRed.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect ? AppConstants.accentGreen : AppConstants.accentRed,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? AppConstants.accentGreen : AppConstants.accentRed,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isCorrect ? 'Correct! 🎉' : 'Incorrect. Keep learning! 📚',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = ((_score / _questions.length) * 100).round();
    final passed = percentage >= 60;

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.darkBg,
              passed
                  ? AppConstants.accentGreen.withOpacity(0.2)
                  : AppConstants.accentRed.withOpacity(0.2),
              AppConstants.darkBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: passed
                          ? AppConstants.blueGradient
                          : LinearGradient(
                              colors: [
                                AppConstants.accentRed,
                                AppConstants.accentOrange,
                              ],
                            ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      passed ? Icons.emoji_events : Icons.school,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    passed ? 'Excellent!' : 'Good Effort!',
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Score',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_score / ${_questions.length}',
                    style: GoogleFonts.orbitron(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: passed ? AppConstants.accentGreen : AppConstants.accentOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _restartQuiz,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            'TRY AGAIN',
                            style: GoogleFonts.orbitron(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.home, color: Colors.white),
                          label: Text(
                            'HOME',
                            style: GoogleFonts.orbitron(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
