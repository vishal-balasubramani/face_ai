import logging
import sys
from datetime import datetime

class CustomLogger:
    """
    Custom logger with colorized output
    """
    
    def __init__(self, name: str = "AI-Classroom"):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.DEBUG)
        
        # Console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.DEBUG)
        
        # Formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        console_handler.setFormatter(formatter)
        
        self.logger.addHandler(console_handler)
    
    def info(self, message: str):
        self.logger.info(f"ℹ️  {message}")
    
    def success(self, message: str):
        self.logger.info(f"✅ {message}")
    
    def warning(self, message: str):
        self.logger.warning(f"⚠️  {message}")
    
    def error(self, message: str):
        self.logger.error(f"❌ {message}")
    
    def debug(self, message: str):
        self.logger.debug(f"🔍 {message}")

# Global logger instance
logger = CustomLogger()
