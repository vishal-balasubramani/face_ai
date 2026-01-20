from models.emotion_detector import EmotionDetector
from models.lstm_predictor import LSTMPredictor
from models.attention_analyzer import AttentionAnalyzer
from typing import Dict
import asyncio
from datetime import datetime

class FrameProcessor:
    def __init__(self):
        print("🔧 Initializing Frame Processor...")
        self.emotion_detector = EmotionDetector()
        self.student_predictors = {}
        self.attention_analyzers = {}
        print("✅ Frame Processor ready!")
    
    async def process_student_frame(self, student_id: str, base64_image: str) -> Dict:
        emotion_result = await asyncio.to_thread(
            self.emotion_detector.process_base64_image,
            base64_image
        )
        
        if not emotion_result.get('face_detected', False):
            return {
                'student_id': student_id,
                'status': 'no_face',
                'emotion': 'No Face',
                'message': 'Please position your face in camera',
                'engagement_score': 0.0,
                'focus_score': 0,
                'recommendation': 'Position your face in the camera frame',
                'timestamp': datetime.now().isoformat()
            }
        
        if student_id not in self.student_predictors:
            self.student_predictors[student_id] = LSTMPredictor()
            self.attention_analyzers[student_id] = AttentionAnalyzer()
        
        predictor = self.student_predictors[student_id]
        analyzer = self.attention_analyzers[student_id]
        
        engagement_score = emotion_result['engagement_score']
        emotion = emotion_result['emotion']
        predictor.add_datapoint(engagement_score, emotion)
        
        prediction = predictor.predict_trend()
        attention = analyzer.analyze_attention(emotion_result)
        
        alert_needed = prediction['prediction'] in ['warning', 'critical']
        recommendation = self._generate_recommendation(emotion, engagement_score, prediction['trend'])
        
        return {
            'student_id': student_id,
            'status': 'success',
            'emotion': emotion,
            'confidence': float(emotion_result['confidence']),
            'engagement_score': float(engagement_score),
            'prediction': prediction,
            'attention': attention,
            'alert_needed': alert_needed,
            'recommendation': recommendation,
            'focus_score': int(engagement_score * 100),
            'timestamp': datetime.now().isoformat()
        }
    
    def _generate_recommendation(self, emotion: str, score: float, trend: str) -> str:
        if score > 0.8:
            return "🔥 You're on fire! Keep up the excellent focus!"
        elif score > 0.6:
            return "👍 Great job! You're doing well."
        elif score > 0.4:
            return "💡 Try taking notes to stay engaged."
        elif emotion == 'sad' or emotion == 'fear':
            return "🤔 Feeling confused? Don't hesitate to ask questions."
        else:
            return "💤 Take a deep breath and refocus on the content."
    
    def get_student_summary(self, student_id: str) -> Dict:
        if student_id not in self.student_predictors:
            return {'error': 'Student not found'}
        
        predictor = self.student_predictors[student_id]
        analyzer = self.attention_analyzers[student_id]
        
        return {
            'student_id': student_id,
            'engagement_stats': predictor.get_stats(),
            'attention_stats': analyzer.get_attention_summary(),
            'current_prediction': predictor.predict_trend()
        }
