import numpy as np
from typing import Dict, List
from collections import deque

class AttentionAnalyzer:
    """
    Advanced attention tracking using gaze patterns and head pose
    """
    
    def __init__(self):
        self.gaze_history = deque(maxlen=30)  # 1 minute of data
        self.blink_count = 0
        self.distraction_events = []
    
    def analyze_attention(self, emotion_data: Dict) -> Dict:
        """
        Analyze attention level from emotion and facial features
        
        Args:
            emotion_data: Output from emotion_detector
            
        Returns:
            Attention metrics
        """
        engagement = emotion_data.get('engagement_score', 0.5)
        emotion = emotion_data.get('emotion', 'neutral')
        
        # Track gaze (simplified - in production use eye tracking)
        self.gaze_history.append(engagement)
        
        # Calculate attention metrics
        if len(self.gaze_history) >= 3:
            recent_engagement = list(self.gaze_history)[-10:]
            attention_score = np.mean(recent_engagement)
            attention_stability = 1.0 - np.std(recent_engagement)
            
            # Detect distraction (sudden drop)
            if len(recent_engagement) >= 2:
                if recent_engagement[-1] < recent_engagement[-2] - 0.3:
                    self.distraction_events.append({
                        'timestamp': emotion_data.get('timestamp'),
                        'drop': recent_engagement[-2] - recent_engagement[-1]
                    })
        else:
            attention_score = engagement
            attention_stability = 0.5
        
        # Categorize attention level
        if attention_score > 0.8:
            attention_level = 'high'
        elif attention_score > 0.5:
            attention_level = 'medium'
        else:
            attention_level = 'low'
        
        return {
            'attention_score': float(attention_score),
            'attention_level': attention_level,
            'stability': float(attention_stability),
            'distraction_count': len(self.distraction_events),
            'focus_duration_seconds': len(self.gaze_history) * 2  # 2 sec intervals
        }
    
    def get_attention_summary(self) -> Dict:
        """Get summary statistics"""
        if len(self.gaze_history) == 0:
            return {}
        
        history = np.array(list(self.gaze_history))
        
        return {
            'average_attention': float(np.mean(history)),
            'peak_attention': float(np.max(history)),
            'lowest_attention': float(np.min(history)),
            'total_distractions': len(self.distraction_events),
            'samples_analyzed': len(history)
        }
