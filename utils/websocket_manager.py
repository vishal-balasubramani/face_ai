from fastapi import WebSocket
from typing import Dict, List
import json

class ConnectionManager:
    """
    Manage WebSocket connections for students and teachers
    """
    
    def __init__(self):
        self.active_students: Dict[str, WebSocket] = {}
        self.active_teachers: List[WebSocket] = []
        self.student_sessions: Dict[str, str] = {}  # student_id -> session_id
    
    async def connect_student(self, websocket: WebSocket, student_id: str, session_id: str):
        """Connect a student"""
        await websocket.accept()
        self.active_students[student_id] = websocket
        self.student_sessions[student_id] = session_id
        print(f"📱 Student {student_id} connected to session {session_id}")
    
    async def connect_teacher(self, websocket: WebSocket):
        """Connect a teacher dashboard"""
        await websocket.accept()
        self.active_teachers.append(websocket)
        print(f"📊 Teacher dashboard connected (Total: {len(self.active_teachers)})")
    
    def disconnect_student(self, student_id: str):
        """Disconnect a student"""
        if student_id in self.active_students:
            del self.active_students[student_id]
            del self.student_sessions[student_id]
            print(f"📱 Student {student_id} disconnected")
    
    def disconnect_teacher(self, websocket: WebSocket):
        """Disconnect a teacher"""
        if websocket in self.active_teachers:
            self.active_teachers.remove(websocket)
            print(f"📊 Teacher dashboard disconnected")
    
    async def send_to_student(self, student_id: str, message: dict):
        """Send message to specific student"""
        if student_id in self.active_students:
            try:
                await self.active_students[student_id].send_text(json.dumps(message))
            except Exception as e:
                print(f"❌ Error sending to {student_id}: {e}")
                self.disconnect_student(student_id)
    
    async def broadcast_to_teachers(self, message: dict):
        """Broadcast message to all teacher dashboards"""
        dead_connections = []
        
        for websocket in self.active_teachers:
            try:
                await websocket.send_text(json.dumps(message))
            except Exception as e:
                print(f"❌ Error broadcasting to teacher: {e}")
                dead_connections.append(websocket)
        
        # Remove dead connections
        for websocket in dead_connections:
            self.disconnect_teacher(websocket)
    
    async def broadcast_to_session(self, session_id: str, message: dict):
        """Send message to all students in a session"""
        for student_id, s_id in self.student_sessions.items():
            if s_id == session_id:
                await self.send_to_student(student_id, message)
    
    def get_session_students(self, session_id: str) -> List[str]:
        """Get all students in a session"""
        return [
            student_id for student_id, s_id in self.student_sessions.items()
            if s_id == session_id
        ]
    
    def get_active_count(self) -> Dict[str, int]:
        """Get connection statistics"""
        return {
            'students': len(self.active_students),
            'teachers': len(self.active_teachers),
            'total': len(self.active_students) + len(self.active_teachers)
        }
