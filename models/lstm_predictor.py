import numpy as np
from typing import Dict, List
from collections import Counter, deque
from datetime import datetime




class AnalyticsEngine:
    """
    Generate analytics data for charts and reports
    """
    
    def __init__(self, session_manager):
        self.session_manager = session_manager
    
    def generate_emotion_distribution(self, session_id: str) -> Dict:
        """
        Generate data for pie chart showing emotion distribution
        
        Returns:
            {emotion: percentage}
        """
        session = self.session_manager.get_session_data(session_id)
        if not session:
            return {}
        
        all_emotions = []
        for student_id in session['students']:
            frames = self.session_manager.get_student_session_data(session_id, student_id)
            all_emotions.extend([f.get('emotion', 'neutral') for f in frames])
        
        if not all_emotions:
            return {}
        
        emotion_counts = Counter(all_emotions)
        total = len(all_emotions)
        
        return {
            emotion: round((count / total) * 100, 2)
            for emotion, count in emotion_counts.items()
        }
    
    def generate_engagement_timeline(self, session_id: str) -> Dict:
        """
        Generate time-series data for engagement over time
        
        Returns:
            {timestamps: [], engagement_scores: []}
        """
        session = self.session_manager.get_session_data(session_id)
        if not session:
            return {'timestamps': [], 'engagement_scores': []}
        
        # Collect all data points with timestamps
        timeline_data = []
        for student_id in session['students']:
            frames = self.session_manager.get_student_session_data(session_id, student_id)
            for frame in frames:
                timeline_data.append({
                    'timestamp': frame.get('timestamp'),
                    'engagement': frame.get('engagement_score', 0)
                })
        
        # Sort by timestamp
        timeline_data.sort(key=lambda x: x['timestamp'])
        
        # Group by minute and average
        minute_buckets = {}
        for data in timeline_data:
            minute = data['timestamp'][:16]  # YYYY-MM-DDTHH:MM
            if minute not in minute_buckets:
                minute_buckets[minute] = []
            minute_buckets[minute].append(data['engagement'])
        
        timestamps = sorted(minute_buckets.keys())
        engagement_scores = [
            round(np.mean(minute_buckets[ts]) * 100, 1)
            for ts in timestamps
        ]
        
        return {
            'timestamps': timestamps,
            'engagement_scores': engagement_scores
        }
    
    def generate_student_comparison(self, session_id: str) -> Dict:
        """
        Generate radar chart data comparing students
        
        Returns:
            {student_id: {metric: score}}
        """
        session = self.session_manager.get_session_data(session_id)
        if not session:
            return {}
        
        comparison = {}
        for student_id in session['students']:
            frames = self.session_manager.get_student_session_data(session_id, student_id)
            
            if not frames:
                continue
            
            engagements = [f.get('engagement_score', 0) for f in frames]
            emotions = [f.get('emotion', 'neutral') for f in frames]
            
            # Calculate metrics
            comparison[student_id] = {
                'average_engagement': round(np.mean(engagements) * 100, 1),
                'consistency': round((1 - np.std(engagements)) * 100, 1),
                'peak_focus': round(np.max(engagements) * 100, 1),
                'participation': len(frames),
                'positive_emotions': sum([1 for e in emotions if e in ['happy', 'surprise']]) / len(emotions) * 100
            }
        
        return comparison
    
    def generate_attention_heatmap(self, session_id: str) -> List[List[float]]:
        """
        Generate minute-by-minute heatmap of class attention
        
        Returns:
            2D array [students][minutes] with engagement scores
        """
        session = self.session_manager.get_session_data(session_id)
        if not session:
            return []
        
        # Get minute-wise data for each student
        heatmap = []
        for student_id in session['students']:
            frames = self.session_manager.get_student_session_data(session_id, student_id)
            
            # Group by minute
            minute_buckets = {}
            for frame in frames:
                minute = frame.get('timestamp', '')[:16]
                if minute not in minute_buckets:
                    minute_buckets[minute] = []
                minute_buckets[minute].append(frame.get('engagement_score', 0))
            
            # Average per minute
            student_timeline = [
                round(np.mean(scores) * 100, 1)
                for scores in minute_buckets.values()
            ]
            
            heatmap.append(student_timeline)
        
        return heatmap
    
    def generate_topic_difficulty(self, session_id: str, topics: List[Dict]) -> Dict:
        """
        Analyze which topics were difficult based on engagement drops
        
        Args:
            topics: [{'name': 'Binary Trees', 'start_time': '...', 'end_time': '...'}]
        
        Returns:
            {topic_name: difficulty_score}
        """
        difficulty_scores = {}
        
        for topic in topics:
            topic_name = topic['name']
            start = topic['start_time']
            end = topic['end_time']
            
            # Get engagement during this topic
            session = self.session_manager.get_session_data(session_id)
            if not session:
                continue
            
            topic_engagements = []
            for student_id in session['students']:
                frames = self.session_manager.get_student_session_data(session_id, student_id)
                for frame in frames:
                    ts = frame.get('timestamp', '')
                    if start <= ts <= end:
                        topic_engagements.append(frame.get('engagement_score', 0))
            
            if topic_engagements:
                avg_engagement = np.mean(topic_engagements)
                # Invert score: low engagement = high difficulty
                difficulty = (1 - avg_engagement) * 100
                difficulty_scores[topic_name] = round(difficulty, 1)
        
        return difficulty_scores
    
class LSTMPredictor:
    def __init__(self, window_size=10):
        self.window_size = window_size
        self.engagement_history = deque(maxlen=window_size)
        self.emotion_history = deque(maxlen=window_size)
    
    def add_datapoint(self, engagement_score, emotion):
        self.engagement_history.append(engagement_score)
        self.emotion_history.append(emotion)
    
    def predict_trend(self):
        if len(self.engagement_history) < 3:
            return {
                'prediction': 'insufficient_data',
                'trend': 'unknown',
                'confidence': 0.0,
                'time_to_critical_minutes': None,
                'current_engagement': 0.0
            }
        history = np.array(list(self.engagement_history))
        n = len(history)
        x = np.arange(n)
        slope = np.polyfit(x, history, 1)[0]
        current_avg = np.mean(history[-3:])
        if slope < -0.05:
            trend = 'declining'
        elif slope > 0.05:
            trend = 'improving'
        else:
            trend = 'stable'
        time_to_critical_min = None
        if trend == 'declining' and current_avg > 0.3 and slope != 0:
            time_to_critical = (0.3 - current_avg) / slope
            time_to_critical_min = abs(time_to_critical * 2 / 60)
        if current_avg < 0.3:
            prediction = 'critical'
        elif trend == 'declining' and time_to_critical_min and time_to_critical_min < 5:
            prediction = 'warning'
        else:
            prediction = 'normal'
        confidence = min(n / self.window_size, 1.0)
        return {
            'prediction': prediction,
            'trend': trend,
            'confidence': float(confidence),
            'time_to_critical_minutes': float(time_to_critical_min) if time_to_critical_min else None,
            'current_engagement': float(current_avg),
            'slope': float(slope)
        }
    
    def get_stats(self):
        if len(self.engagement_history) == 0:
            return {}
        history = np.array(list(self.engagement_history))
        return {
            'mean': float(np.mean(history)),
            'std': float(np.std(history)),
            'min': float(np.min(history)),
            'max': float(np.max(history)),
            'current': float(history[-1]) if len(history) > 0 else 0.0,
            'samples': len(history)
        }

