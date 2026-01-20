import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Config:
    """Application configuration"""
    
    # Server
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 8000))
    DEBUG = os.getenv("DEBUG", "True").lower() == "true"
    
    # AI Model
    MODEL_NAME = os.getenv("MODEL_NAME", "dima806/facial_emotions_image_detection")
    FRAME_PROCESSING_INTERVAL = int(os.getenv("FRAME_PROCESSING_INTERVAL", 2))
    
    # Database
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./classroom.db")
    
    # Redis
    REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
    REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
    
    # Gemini AI
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    
    # Security
    SECRET_KEY = os.getenv("SECRET_KEY", "change-this-secret-key")
    ALGORITHM = os.getenv("ALGORITHM", "HS256")
    
    @classmethod
    def validate(cls):
        """Validate required config"""
        if not cls.GEMINI_API_KEY:
            print("⚠️ WARNING: GEMINI_API_KEY not set. AI features limited.")
        
        print("✅ Configuration loaded")
