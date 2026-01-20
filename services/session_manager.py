from datetime import datetime
from typing import Dict, List, Optional
import json

class SessionManager:
    """
    Manages classroom sessions and stores data
    """
    
    def __init__(self):
        self.active_sessions = {}  # session_id -> session_data
        self.student_data = {}  # student_id -> [frame_data]
    
    def create_session(self, session_id: str, teacher_id: str, subject: str) -> Dict:
        """Create new classroom session"""
        session = {
            'session_id': session_id,
            'teacher_id': teacher_id,
            'subject': subject,
            'start_time': datetime.now().isoformat(),
            'end_time': None,
            'students': [],
            'total_frames_processed': 0,
            'alerts_generated': 0
        }
        
        self.active_sessions[session_id] = session
        return session
    
    def add_student_to_session(self, session_id: str, student_id: str):
        """Register student in session"""
        if session_id in self.active_sessions:
            if student_id not in self.active_sessions[session_id]['students']:
                self.active_sessions[session_id]['students'].append(student_id)
            
            if student_id not in self.student_data:
                self.student_data[student_id] = []
    
    def log_frame_data(self, session_id: str, student_id: str, frame_data: Dict):
        """Store processed frame data"""
        if session_id in self.active_sessions:
            self.active_sessions[session_id]['total_frames_processed'] += 1
            
            if student_id in self.student_data:
                self.student_data[student_id].append({
                    'timestamp': datetime.now().isoformat(),
                    'session_id': session_id,
                    **frame_data
                })
    
    def end_session(self, session_id: str) -> Dict:
        """End session and return summary"""
        if session_id not in self.active_sessions:
            return {'error': 'Session not found'}
        
        session = self.active_sessions[session_id]
        session['end_time'] = datetime.now().isoformat()
        
        # Calculate session statistics
        total_engagement = 0
        student_count = len(session['students'])
        
        for student_id in session['students']:
            if student_id in self.student_data:
                student_frames = self.student_data[student_id]
                if student_frames:
                    avg_engagement = sum([f.get('engagement_score', 0) for f in student_frames]) / len(student_frames)
                    total_engagement += avg_engagement
        
        session['average_class_engagement'] = total_engagement / student_count if student_count > 0 else 0
        session['duration_minutes'] = self._calculate_duration(session['start_time'], session['end_time'])
        
        return session
    
    def get_session_data(self, session_id: str) -> Optional[Dict]:
        """Retrieve session data"""
        return self.active_sessions.get(session_id)
    
    def get_student_session_data(self, session_id: str, student_id: str) -> List[Dict]:
        """Get all frames for a student in a session"""
        if student_id not in self.student_data:
            return []
        
        return [
            frame for frame in self.student_data[student_id]
            if frame.get('session_id') == session_id
        ]
    
    def _calculate_duration(self, start: str, end: str) -> float:
        """Calculate duration in minutes"""
        start_dt = datetime.fromisoformat(start)
        end_dt = datetime.fromisoformat(end)
        duration = (end_dt - start_dt).total_seconds() / 60
        return round(duration, 2)
