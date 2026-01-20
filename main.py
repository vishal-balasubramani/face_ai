from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from contextlib import asynccontextmanager
import uvicorn
import json
from datetime import datetime
from typing import Optional

# Import all services
from models.emotion_detector import EmotionDetector
from services.frame_processor import FrameProcessor
from services.session_manager import SessionManager
from services.analytics_engine import AnalyticsEngine
from services.report_generator import ReportGenerator
from services.gemini_advisor import GeminiAdvisor
from services.alert_manager import AlertManager
from utils.websocket_manager import ConnectionManager
from utils.config import Config
from utils.logger import logger
from database.db import init_db, get_db_connection  # ← Add get_db_connection


# ============================================================================
# Application Lifecycle
# ============================================================================


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    # Startup
    logger.info("🚀 Starting AI Classroom Backend...")
    Config.validate()
    init_db()
    
    # Initialize services
    app.state.frame_processor = FrameProcessor()
    app.state.session_manager = SessionManager()
    app.state.analytics_engine = AnalyticsEngine(app.state.session_manager)
    app.state.report_generator = ReportGenerator(app.state.analytics_engine)
    app.state.gemini_advisor = GeminiAdvisor()
    app.state.alert_manager = AlertManager()
    app.state.connection_manager = ConnectionManager()
    
    logger.success("✅ All services initialized!")
    logger.info(f"🌐 Server running on {Config.HOST}:{Config.PORT}")
    
    yield
    
    # Shutdown
    logger.info("👋 Shutting down AI Classroom Backend...")


# ============================================================================
# FastAPI Application
# ============================================================================


app = FastAPI(
    title="AI Classroom Backend",
    description="Real-time emotion detection and engagement tracking for classrooms",
    version="2.0.0",
    lifespan=lifespan
)


# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production: specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# REST API Endpoints - Core
# ============================================================================


@app.get("/")
async def root():
    """API health check"""
    return {
        "status": "online",
        "service": "AI Classroom Backend",
        "version": "2.0.0",
        "timestamp": datetime.now().isoformat(),
        "connections": app.state.connection_manager.get_active_count()
    }


@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "services": {
            "emotion_detector": "active",
            "frame_processor": "active",
            "session_manager": "active",
            "database": "connected",
            "gemini_advisor": "active" if app.state.gemini_advisor.model else "limited"
        },
        "connections": app.state.connection_manager.get_active_count()
    }


# ============================================================================
# SESSION ENDPOINTS - Updated with DB Integration
# ============================================================================


@app.post("/api/session/create")
async def create_session(session_data: dict):
    """
    Create a new classroom session
    
    Body: {
        "session_id": "session_001",
        "teacher_id": "teacher_1",
        "subject": "Data Structures"
    }
    """
    session = app.state.session_manager.create_session(
        session_data['session_id'],
        session_data['teacher_id'],
        session_data['subject']
    )
    logger.success(f"✅ Session created: {session_data['session_id']}")
    return session


@app.post("/api/session/{session_id}/end")
async def end_session(session_id: str):
    """End a session and generate analytics"""
    session = app.state.session_manager.end_session(session_id)
    
    if 'error' in session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    # Generate analytics
    analytics = {
        'emotion_distribution': app.state.analytics_engine.generate_emotion_distribution(session_id),
        'engagement_timeline': app.state.analytics_engine.generate_engagement_timeline(session_id),
        'student_comparison': app.state.analytics_engine.generate_student_comparison(session_id),
        'attention_heatmap': app.state.analytics_engine.generate_attention_heatmap(session_id)
    }
    
    # Generate AI suggestions
    suggestions = app.state.gemini_advisor.generate_teaching_suggestions(session, analytics)
    
    logger.success(f"✅ Session ended: {session_id}")
    
    return {
        'session': session,
        'analytics': analytics,
        'ai_suggestions': suggestions
    }


@app.get("/api/session/{session_id}/analytics")
async def get_analytics(session_id: str):
    """Get real-time analytics for a session"""
    session = app.state.session_manager.get_session_data(session_id)
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    analytics = {
        'emotion_distribution': app.state.analytics_engine.generate_emotion_distribution(session_id),
        'engagement_timeline': app.state.analytics_engine.generate_engagement_timeline(session_id),
        'student_comparison': app.state.analytics_engine.generate_student_comparison(session_id)
    }
    
    return analytics


# ============================================================================
# FLUTTER APP ENDPOINTS - NEW (For Student Sessions)
# ============================================================================


@app.post("/api/sessions")
async def save_student_session(session_data: dict):
    """
    Save a completed student session to Neon DB
    
    Body: {
        "student_id": "24CS0101",
        "student_name": "Vishal",
        "start_time": "2025-12-26T16:00:00",
        "end_time": "2025-12-26T16:45:00",
        "average_focus": 0.85,
        "total_frames": 150,
        "dominant_emotion": "focused",
        "emotion_distribution": {"focused": 0.6, "happy": 0.3, "neutral": 0.1}
    }
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO sessions 
            (student_id, student_name, start_time, end_time, average_focus, 
             total_frames, dominant_emotion, emotion_distribution)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        ''', (
            session_data['student_id'],
            session_data['student_name'],
            session_data['start_time'],
            session_data['end_time'],
            session_data['average_focus'],
            session_data['total_frames'],
            session_data['dominant_emotion'],
            json.dumps(session_data['emotion_distribution'])
        ))
        
        session_id = cursor.fetchone()[0]
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.success(f"✅ Session saved: {session_data['student_id']}")
        
        return {
            'success': True,
            'message': 'Session saved successfully',
            'session_id': session_id
        }
        
    except Exception as e:
        logger.error(f"❌ Error saving session: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/sessions/{student_id}")
async def get_student_session_history(student_id: str):
    """
    Get session history for a student
    Returns last 20 sessions
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT 
                id, student_id, student_name, start_time, end_time, 
                average_focus, total_frames, dominant_emotion, 
                emotion_distribution, created_at
            FROM sessions 
            WHERE student_id = %s 
            ORDER BY start_time DESC 
            LIMIT 20
        ''', (student_id,))
        
        columns = [desc[0] for desc in cursor.description]
        sessions = []
        
        for row in cursor.fetchall():
            session_dict = dict(zip(columns, row))
            # Convert datetime to ISO string
            session_dict['start_time'] = session_dict['start_time'].isoformat()
            session_dict['end_time'] = session_dict['end_time'].isoformat()
            if session_dict['created_at']:
                session_dict['created_at'] = session_dict['created_at'].isoformat()
            sessions.append(session_dict)
        
        cursor.close()
        conn.close()
        
        logger.info(f"📊 Fetched {len(sessions)} sessions for {student_id}")
        return sessions
        
    except Exception as e:
        logger.error(f"❌ Error fetching sessions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/stats/{student_id}")
async def get_student_total_stats(student_id: str):
    """
    Get total statistics for a student
    Returns: total sessions, frames, average focus, total time
    """
    logger.info(f"📊 Fetching stats for student: {student_id}")
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get all stats in one query
        cursor.execute('''
            SELECT 
                COUNT(*)::integer as total_sessions,
                COALESCE(SUM(total_frames), 0)::integer as total_frames,
                COALESCE(AVG(average_focus), 0)::numeric as average_focus,
                COALESCE(
                    SUM(
                        CASE 
                            WHEN end_time IS NOT NULL AND start_time IS NOT NULL 
                            THEN EXTRACT(EPOCH FROM (end_time - start_time))
                            ELSE 0 
                        END
                    ), 0
                )::numeric as total_seconds
            FROM sessions 
            WHERE student_id = %s
        ''', (student_id,))
        
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not result:
            logger.warning(f"⚠️ No result for {student_id}")
            return {
                'total_sessions': 0,
                'total_frames': 0,
                'average_focus': 0.0,
                'total_time': '0m'
            }
        
        # Handle both dict (RealDictCursor) and tuple results
        if isinstance(result, dict):
            total_sessions = int(result.get('total_sessions', 0) or 0)
            total_frames = int(result.get('total_frames', 0) or 0)
            average_focus = float(result.get('average_focus', 0) or 0.0)
            total_seconds = float(result.get('total_seconds', 0) or 0.0)
        else:
            total_sessions = int(result[0] or 0)
            total_frames = int(result[1] or 0)
            average_focus = float(result[2] or 0.0)
            total_seconds = float(result[3] or 0.0)
        
        # Format time
        hours = int(total_seconds // 3600)
        minutes = int((total_seconds % 3600) // 60)
        time_str = f'{hours}h {minutes}m' if hours > 0 else f'{minutes}m'
        
        stats = {
            'total_sessions': total_sessions,
            'total_frames': total_frames,
            'average_focus': round(average_focus * 100, 2),
            'total_time': time_str
        }
        
        logger.success(f"✅ Stats for {student_id}: {stats}")
        return stats
        
    except Exception as e:
        logger.error(f"❌ Error fetching stats: {e}")
        import traceback
        logger.error(traceback.format_exc())
        
        # Return default stats on error
        return {
            'total_sessions': 0,
            'total_frames': 0,
            'average_focus': 0.0,
            'total_time': '0m'
        }


# ============================================================================
# LEADERBOARD ENDPOINTS - NEW
# ============================================================================


@app.get("/api/leaderboard")
async def get_leaderboard(limit: int = 50):
    """
    Get global leaderboard
    Returns top students ranked by average focus score
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT 
                student_id,
                student_name,
                AVG(average_focus) as avg_focus,
                COUNT(*) as session_count,
                SUM(total_frames) as total_frames
            FROM sessions
            GROUP BY student_id, student_name
            ORDER BY avg_focus DESC
            LIMIT %s
        ''', (limit,))
        
        leaderboard = []
        for idx, row in enumerate(cursor.fetchall(), 1):
            leaderboard.append({
                'rank': idx,
                'student_id': row[0],
                'student_name': row[1],
                'avg_focus': float(row[2]) * 100,
                'session_count': int(row[3]),
                'total_frames': int(row[4])
            })
        
        cursor.close()
        conn.close()
        
        logger.info(f"🏆 Leaderboard fetched: {len(leaderboard)} students")
        return leaderboard
        
    except Exception as e:
        logger.error(f"❌ Error fetching leaderboard: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/leaderboard/update")
async def update_leaderboard_score(leaderboard_data: dict):
    """
    Update leaderboard score for a student
    
    Body: {
        "student_id": "24CS0101",
        "student_name": "Vishal",
        "focus_score": 85.5
    }
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Check if student exists in leaderboard
        cursor.execute(
            'SELECT id FROM leaderboard WHERE student_id = %s',
            (leaderboard_data['student_id'],)
        )
        
        existing = cursor.fetchone()
        
        if not existing:
            # Insert new entry
            cursor.execute('''
                INSERT INTO leaderboard 
                (student_id, student_name, total_score, session_count)
                VALUES (%s, %s, %s, 1)
            ''', (
                leaderboard_data['student_id'],
                leaderboard_data['student_name'],
                leaderboard_data['focus_score']
            ))
            logger.info(f"➕ New leaderboard entry: {leaderboard_data['student_id']}")
        else:
            # Update existing entry
            cursor.execute('''
                UPDATE leaderboard 
                SET total_score = total_score + %s,
                    session_count = session_count + 1,
                    last_updated = NOW()
                WHERE student_id = %s
            ''', (
                leaderboard_data['focus_score'],
                leaderboard_data['student_id']
            ))
            logger.info(f"🔄 Updated leaderboard: {leaderboard_data['student_id']}")
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return {'success': True, 'message': 'Leaderboard updated'}
        
    except Exception as e:
        logger.error(f"❌ Error updating leaderboard: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# REPORTS & QUIZ - Existing Endpoints
# ============================================================================


@app.get("/api/session/{session_id}/report/pdf")
async def download_pdf_report(session_id: str):
    """Download PDF report"""
    session = app.state.session_manager.get_session_data(session_id)
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    analytics = {
        'emotion_distribution': app.state.analytics_engine.generate_emotion_distribution(session_id),
        'student_comparison': app.state.analytics_engine.generate_student_comparison(session_id),
        'peak_engagement': 95.0
    }
    
    pdf_path = app.state.report_generator.generate_pdf_report(session_id, session, analytics)
    
    return FileResponse(
        pdf_path,
        media_type='application/pdf',
        filename=f"session_{session_id}_report.pdf"
    )


@app.post("/api/quiz/generate")
async def generate_quiz(quiz_request: dict):
    """
    Generate quiz for intervention
    
    Body: {
        "topic": "Binary Trees",
        "difficulty": "medium"
    }
    """
    quiz = app.state.gemini_advisor.generate_quiz(
        quiz_request['topic'],
        quiz_request.get('difficulty', 'medium')
    )
    return quiz


@app.get("/api/alerts/recent")
async def get_recent_alerts(limit: int = 10):
    """Get recent alerts"""
    return {
        'alerts': app.state.alert_manager.get_recent_alerts(limit),
        'summary': app.state.alert_manager.get_alert_summary()
    }


# ============================================================================
# WebSocket Endpoints
# ============================================================================


@app.websocket("/ws/student")
async def student_websocket(websocket: WebSocket):
    student_id = None
    session_id = "default_session"
    
    try:
        await app.state.connection_manager.connect_student(websocket, "temp", session_id)
        
        while True:
            data = await websocket.receive_text()
            json_data = json.loads(data)
            
            student_id = json_data.get('student_id', 'unknown')
            image_b64 = json_data.get('image')
            
            app.state.session_manager.add_student_to_session(session_id, student_id)
            
            result = await app.state.frame_processor.process_student_frame(
                student_id,
                image_b64
            )
            
            app.state.session_manager.log_frame_data(session_id, student_id, result)
            
            alert = app.state.alert_manager.check_and_create_alert(student_id, result)
            if alert:
                await app.state.connection_manager.broadcast_to_teachers({
                    'type': 'alert',
                    'data': alert
                })
            
            # Ensure proper data types for Flutter
            response = {
                'emotion': str(result.get('emotion', 'neutral')),
                'engagement_score': float(result.get('engagement_score', 0.0)),
                'focus_score': int(result.get('focus_score', 0)),
                'recommendation': str(result.get('recommendation', 'Keep learning!')),
                'timestamp': str(result.get('timestamp', datetime.now().isoformat()))
            }
            
            await websocket.send_text(json.dumps(response))
            
            await app.state.connection_manager.broadcast_to_teachers({
                'type': 'student_update',
                'student_id': student_id,
                'data': result
            })
            
            logger.debug(f"📸 Processed frame for {student_id}: {result.get('emotion')}")
            
    except WebSocketDisconnect:
        if student_id:
            app.state.connection_manager.disconnect_student(student_id)
            logger.info(f"👋 Student disconnected: {student_id}")
    except Exception as e:
        logger.error(f"❌ WebSocket error: {e}")
        if student_id:
            app.state.connection_manager.disconnect_student(student_id)


@app.websocket("/ws/dashboard")
async def dashboard_websocket(websocket: WebSocket):
    """WebSocket endpoint for teacher dashboard"""
    try:
        await app.state.connection_manager.connect_teacher(websocket)
        
        await websocket.send_text(json.dumps({
            'type': 'connected',
            'message': 'Dashboard connected successfully'
        }))
        
        while True:
            data = await websocket.receive_text()
            json_data = json.loads(data)
            
            command = json_data.get('command')
            
            if command == 'generate_quiz':
                quiz = app.state.gemini_advisor.generate_quiz(
                    json_data.get('topic', 'General'),
                    json_data.get('difficulty', 'medium')
                )
                
                session_id = json_data.get('session_id', 'default_session')
                await app.state.connection_manager.broadcast_to_session(session_id, {
                    'type': 'quiz',
                    'data': quiz
                })
            
            elif command == 'get_stats':
                session_id = json_data.get('session_id', 'default_session')
                session_data = app.state.session_manager.get_session_data(session_id)
                await websocket.send_text(json.dumps({
                    'type': 'stats',
                    'data': session_data
                }))
            
    except WebSocketDisconnect:
        app.state.connection_manager.disconnect_teacher(websocket)
        logger.info("👋 Dashboard disconnected")
    except Exception as e:
        logger.error(f"❌ Dashboard WebSocket error: {e}")
        app.state.connection_manager.disconnect_teacher(websocket)


# ============================================================================
# Run Server
# ============================================================================


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=Config.HOST,
        port=Config.PORT,
        reload=Config.DEBUG,
        log_level="info"
    )
