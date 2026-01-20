import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv
from utils.logger import logger

load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL')


def get_db_connection():
    """Create and return a database connection"""
    try:
        conn = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)
        return conn
    except Exception as e:
        logger.error(f"❌ Database connection error: {e}")
        raise


def init_db():
    """Initialize database tables"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Create sessions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS sessions (
                id SERIAL PRIMARY KEY,
                student_id VARCHAR(100) NOT NULL,
                student_name VARCHAR(255) NOT NULL,
                start_time TIMESTAMP NOT NULL,
                end_time TIMESTAMP NOT NULL,
                average_focus DECIMAL(5,2) NOT NULL,
                total_frames INTEGER NOT NULL,
                dominant_emotion VARCHAR(50),
                emotion_distribution JSONB,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Create leaderboard table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS leaderboard (
                id SERIAL PRIMARY KEY,
                student_id VARCHAR(100) UNIQUE NOT NULL,
                student_name VARCHAR(255) NOT NULL,
                total_score DECIMAL(10,2) DEFAULT 0,
                session_count INTEGER DEFAULT 0,
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Create indexes
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_sessions_student_id ON sessions(student_id)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_sessions_start_time ON sessions(start_time DESC)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_leaderboard_score ON leaderboard(total_score DESC)')
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.success('✅ Database tables initialized successfully')
        
    except Exception as e:
        logger.error(f'❌ Database initialization error: {e}')
        raise
