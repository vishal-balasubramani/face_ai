import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizService {
  // Free API for programming questions
  static const String apiUrl = 'https://quizapi.io/api/v1/questions';
  static const String apiKey = 'YOUR_API_KEY_HERE'; // Get free from quizapi.io
  
  // Fallback questions if API fails
  static final List<Map<String, dynamic>> fallbackQuestions = [
    {
      'question': 'What is the time complexity of Binary Search?',
      'answers': {
        'answer_a': 'O(n)',
        'answer_b': 'O(log n)',
        'answer_c': 'O(n²)',
        'answer_d': 'O(1)',
      },
      'correct_answers': {
        'answer_a_correct': 'false',
        'answer_b_correct': 'true',
        'answer_c_correct': 'false',
        'answer_d_correct': 'false',
      },
    },
    {
      'question': 'Which data structure uses LIFO principle?',
      'answers': {
        'answer_a': 'Queue',
        'answer_b': 'Stack',
        'answer_c': 'Array',
        'answer_d': 'Linked List',
      },
      'correct_answers': {
        'answer_a_correct': 'false',
        'answer_b_correct': 'true',
        'answer_c_correct': 'false',
        'answer_d_correct': 'false',
      },
    },
    {
      'question': 'What does SQL stand for?',
      'answers': {
        'answer_a': 'Strong Question Language',
        'answer_b': 'Structured Query Language',
        'answer_c': 'Simple Query Language',
        'answer_d': 'Standard Question Language',
      },
      'correct_answers': {
        'answer_a_correct': 'false',
        'answer_b_correct': 'true',
        'answer_c_correct': 'false',
        'answer_d_correct': 'false',
      },
    },
    {
      'question': 'Which sorting algorithm has the best average case complexity?',
      'answers': {
        'answer_a': 'Bubble Sort',
        'answer_b': 'Quick Sort',
        'answer_c': 'Selection Sort',
        'answer_d': 'Insertion Sort',
      },
      'correct_answers': {
        'answer_a_correct': 'false',
        'answer_b_correct': 'true',
        'answer_c_correct': 'false',
        'answer_d_correct': 'false',
      },
    },
    {
      'question': 'What is polymorphism in OOP?',
      'answers': {
        'answer_a': 'Having multiple classes',
        'answer_b': 'Ability to take multiple forms',
        'answer_c': 'Data hiding',
        'answer_d': 'Code reusability',
      },
      'correct_answers': {
        'answer_a_correct': 'false',
        'answer_b_correct': 'true',
        'answer_c_correct': 'false',
        'answer_d_correct': 'false',
      },
    },
  ];

  Future<List<Map<String, dynamic>>> getQuestions({int limit = 5}) async {
    try {
      // Try to fetch from API
      final response = await http.get(
        Uri.parse('$apiUrl?apiKey=$apiKey&limit=$limit&category=Code&difficulty=Easy'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('API Error: ${response.statusCode}');
        return _getFallbackQuestions(limit);
      }
    } catch (e) {
      print('Network Error: $e');
      return _getFallbackQuestions(limit);
    }
  }

  List<Map<String, dynamic>> _getFallbackQuestions(int limit) {
    fallbackQuestions.shuffle();
    return fallbackQuestions.take(limit).toList();
  }

  // Parse API response to simple format
  Map<String, dynamic> parseQuestion(Map<String, dynamic> apiQuestion) {
    final answers = apiQuestion['answers'] as Map<String, dynamic>;
    final correctAnswers = apiQuestion['correct_answers'] as Map<String, dynamic>;
    
    // Extract non-null options
    List<String> options = [];
    List<String> keys = ['answer_a', 'answer_b', 'answer_c', 'answer_d'];
    
    for (var key in keys) {
      if (answers[key] != null && answers[key] != '') {
        options.add(answers[key]);
      }
    }
    
    // Find correct answer index
    int correctIndex = 0;
    for (int i = 0; i < keys.length; i++) {
      if (correctAnswers['${keys[i]}_correct'] == 'true') {
        correctIndex = i;
        break;
      }
    }
    
    return {
      'question': apiQuestion['question'] ?? 'Sample Question?',
      'options': options,
      'correct_index': correctIndex,
    };
  }
}
