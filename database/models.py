from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from database.db import Base
from datetime import datetime

class Session(Base):
    """Classroom session model"""
    __tablename__ = "sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, unique=True, index=True)
    teacher_id = Column(String)
    subject = Column(String)
    start_time = Column(DateTime, default=datetime.utcnow)
    end_time = Column(DateTime, nullable=True)
    average_engagement = Column(Float, default=0.0)
    total_frames = Column(Integer, default=0)
    
    # Relationships
    students = relationship("Student", back_populates="session")
    frames = relationship("FrameData", back_populates="session")

class Student(Base):
    """Student model"""
    __tablename__ = "students"
    
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(String, index=True)
    session_id = Column(String, ForeignKey("sessions.session_id"))
    joined_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    session = relationship("Session", back_populates="students")
    frames = relationship("FrameData", back_populates="student")

class FrameData(Base):
    """Individual frame processing results"""
    __tablename__ = "frame_data"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, ForeignKey("sessions.session_id"))
    student_id = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Emotion data
    emotion = Column(String)
    confidence = Column(Float)
    engagement_score = Column(Float)
    
    # Prediction data
    prediction_status = Column(String)  # normal/warning/critical
    trend = Column(String)  # improving/stable/declining
    
    # Attention data
    attention_score = Column(Float)
    attention_level = Column(String)
    
    # Relationships
    session = relationship("Session", back_populates="frames")
    student = relationship("Student", back_populates="frames")
