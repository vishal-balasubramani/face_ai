from datetime import datetime
from typing import Dict, List
from collections import deque

class AlertManager:
    """
    Manage real-time alerts for teacher dashboard
    """
    
    def __init__(self):
        self.alert_history = deque(maxlen=100)
        self.alert_cooldown = {}  # student_id -> last_alert_time
        self.cooldown_seconds = 30  # Don't spam same alert
    
    def check_and_create_alert(self, student_id: str, frame_data: Dict) -> Dict | None:
        """
        Determine if an alert should be generated
        
        Args:
            student_id: Student identifier
            frame_data: Processed frame data
            
        Returns:
            Alert dict or None
        """
        prediction = frame_data.get('prediction', {})
        engagement = frame_data.get('engagement_score', 1.0)
        emotion = frame_data.get('emotion', 'neutral')
        
        alert = None
        
        # Critical: Very low engagement
        if engagement < 0.3:
            if self._should_alert(student_id, 'critical'):
                alert = {
                    'type': 'critical',
                    'priority': 'high',
                    'student_id': student_id,
                    'message': f"{student_id} shows very low engagement ({engagement*100:.0f}%)",
                    'action': 'Immediate intervention recommended',
                    'timestamp': datetime.now().isoformat()
                }
        
        # Warning: Declining trend
        elif prediction.get('prediction') == 'warning':
            time_to_critical = prediction.get('time_to_critical_minutes')
            if time_to_critical and time_to_critical < 5:
                if self._should_alert(student_id, 'warning'):
                    alert = {
                        'type': 'warning',
                        'priority': 'medium',
                        'student_id': student_id,
                        'message': f"{student_id} engagement declining. Critical in {time_to_critical:.1f} min",
                        'action': 'Consider checking on student',
                        'timestamp': datetime.now().isoformat()
                    }
        
        # Emotion: Confused/Sad
        elif emotion in ['sad', 'fear'] and engagement < 0.5:
            if self._should_alert(student_id, 'emotion'):
                alert = {
                    'type': 'emotion',
                    'priority': 'medium',
                    'student_id': student_id,
                    'message': f"{student_id} appears {emotion}. May need clarification",
                    'action': 'Pause and ask if anyone has questions',
                    'timestamp': datetime.now().isoformat()
                }
        
        # Store alert
        if alert:
            self.alert_history.append(alert)
            self.alert_cooldown[student_id] = datetime.now()
        
        return alert
    
    def _should_alert(self, student_id: str, alert_type: str) -> bool:
        """Check if enough time passed since last alert"""
        if student_id not in self.alert_cooldown:
            return True
        
        last_alert = self.alert_cooldown[student_id]
        seconds_since = (datetime.now() - last_alert).total_seconds()
        
        return seconds_since > self.cooldown_seconds
    
    def get_recent_alerts(self, limit: int = 10) -> List[Dict]:
        """Get recent alerts for dashboard"""
        return list(self.alert_history)[-limit:]
    
    def get_alert_summary(self) -> Dict:
        """Get summary statistics"""
        total = len(self.alert_history)
        
        by_type = {}
        by_priority = {}
        
        for alert in self.alert_history:
            alert_type = alert.get('type', 'unknown')
            priority = alert.get('priority', 'low')
            
            by_type[alert_type] = by_type.get(alert_type, 0) + 1
            by_priority[priority] = by_priority.get(priority, 0) + 1
        
        return {
            'total_alerts': total,
            'by_type': by_type,
            'by_priority': by_priority
        }
