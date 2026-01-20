import google.generativeai as genai
import os
from typing import Dict, List

class GeminiAdvisor:
    """
    AI-powered teaching advisor using Google Gemini
    """
    
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            print("⚠️ WARNING: GEMINI_API_KEY not set. AI suggestions disabled.")
            self.model = None
            return
        
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-pro')
        print("✅ Gemini AI Advisor initialized")
    
    def generate_teaching_suggestions(self, session_data: dict, analytics: dict) -> Dict:
        """
        Generate personalized teaching recommendations
        
        Args:
            session_data: Session information
            analytics: Analytics from session
            
        Returns:
            dict with suggestions and action items
        """
        if not self.model:
            return {
                'suggestions': ['Gemini API not configured'],
                'action_items': []
            }
        
        avg_engagement = session_data.get('average_class_engagement', 0) * 100
        duration = session_data.get('duration_minutes', 0)
        subject = session_data.get('subject', 'the topic')
        
        emotion_dist = analytics.get('emotion_distribution', {})
        
        prompt = f"""
You are an expert teaching advisor. Analyze this classroom session and provide actionable suggestions.

Session Details:
- Subject: {subject}
- Duration: {duration} minutes
- Average Engagement: {avg_engagement:.1f}%
- Emotion Distribution: {emotion_dist}

Provide:
1. 3 specific suggestions to improve engagement
2. 3 action items for the next class
3. 1 positive highlight from the session

Format as JSON:
{{
  "suggestions": ["...", "...", "..."],
  "action_items": ["...", "...", "..."],
  "highlight": "..."
}}
"""
        
        try:
            response = self.model.generate_content(prompt)
            # Parse JSON response
            import json
            result = json.loads(response.text.strip().replace('``````', ''))
            return result
        except Exception as e:
            print(f"❌ Gemini API error: {e}")
            return {
                'suggestions': [
                    f"Class engagement was {avg_engagement:.0f}%. Consider interactive activities.",
                    "Add more visual aids and examples",
                    "Include Q&A sessions every 15 minutes"
                ],
                'action_items': [
                    "Prepare quiz questions for next class",
                    "Review topics where engagement dropped",
                    "Encourage more student participation"
                ],
                'highlight': "Students showed good initial engagement"
            }
    
    def generate_quiz(self, topic: str, difficulty: str = 'medium') -> Dict:
        """
        Generate quiz questions for real-time intervention
        
        Args:
            topic: Current topic being taught
            difficulty: easy/medium/hard
            
        Returns:
            Quiz with questions and answers
        """
        if not self.model:
            return self._fallback_quiz(topic)
        
        prompt = f"""
Create a quick 3-question multiple choice quiz on: {topic}
Difficulty: {difficulty}

Return JSON format:
{{
  "title": "Quick Check: [topic]",
  "questions": [
    {{
      "question": "Question text?",
      "options": ["A", "B", "C", "D"],
      "correct_index": 0,
      "explanation": "Brief explanation"
    }}
  ]
}}
"""
        
        try:
            response = self.model.generate_content(prompt)
            import json
            quiz = json.loads(response.text.strip().replace('``````', ''))
            return quiz
        except Exception as e:
            print(f"❌ Quiz generation failed: {e}")
            return self._fallback_quiz(topic)
    
    def _fallback_quiz(self, topic: str) -> Dict:
        """Fallback quiz when API fails"""
        return {
            "title": f"Quick Check: {topic}",
            "questions": [
                {
                    "question": f"What is the main concept of {topic}?",
                    "options": ["Option A", "Option B", "Option C", "Option D"],
                    "correct_index": 0,
                    "explanation": "Review the key concepts"
                }
            ]
        }
    
    def generate_content_suggestion(self, topic: str, engagement_issue: str) -> str:
        """
        Generate content to re-engage students
        
        Args:
            topic: Current topic
            engagement_issue: 'bored' / 'confused' / 'distracted'
            
        Returns:
            Suggestion text
        """
        if not self.model:
            return f"Consider adding a real-world example related to {topic}"
        
        prompt = f"""
Students are {engagement_issue} during a lesson on {topic}.
Suggest ONE quick (<30 words) engaging activity or example to recapture attention.
"""
        
        try:
            response = self.model.generate_content(prompt)
            return response.text.strip()
        except:
            return f"Try a quick hands-on demo or real-world application of {topic}"
