from transformers import pipeline
from PIL import Image
import cv2
import numpy as np
import torch
import time
from datetime import datetime

class EmotionDetector:
    def __init__(self):
        print("🔥 Initializing AI Emotion Detector...")
        device = "cpu"
        
        self.classifier = pipeline(
            "image-classification",
            model="dima806/facial_emotions_image_detection",
            device=device,
            framework="pt",
            torch_dtype=torch.float32
        )
        
        self.face_cascade = cv2.CascadeClassifier(
            cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        )
        
        self.emotion_map = {
            'happy': 0.95,
            'surprise': 0.85,
            'neutral': 0.60,
            'sad': 0.30,
            'fear': 0.20,
            'angry': 0.10,
            'disgust': 0.10
        }
        
        print("✅ AI Model loaded successfully!")
        self._benchmark_performance()
    
    def _benchmark_performance(self):
        dummy_image = Image.new('RGB', (224, 224), color='red')
        _ = self.classifier(dummy_image)
        
        start = time.time()
        for _ in range(5):
            _ = self.classifier(dummy_image)
        elapsed = (time.time() - start) / 5
        
        print(f"⚡ Average Inference Time: {elapsed*1000:.0f}ms")
        print(f"📊 Max Throughput: {1/elapsed:.1f} frames/second")
        
        if elapsed < 0.3:
            print("🚀 EXCELLENT: Can handle 30+ students")
        elif elapsed < 0.6:
            print("✅ GOOD: Can handle 15-20 students")
        else:
            print("⚠️ SLOW: Consider ONNX optimization or reduce students")
    
    def detect_emotion(self, frame):
        try:
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            faces = self.face_cascade.detectMultiScale(
                gray,
                scaleFactor=1.1,
                minNeighbors=5,
                minSize=(30, 30)
            )
            
            if len(faces) == 0:
                return {
                    'face_detected': False,
                    'emotion': 'No Face',
                    'confidence': 0.0,
                    'engagement_score': 0.0,
                    'timestamp': datetime.now().isoformat()
                }
            
            (x, y, w, h) = max(faces, key=lambda f: f[2] * f[3])
            padding = int(w * 0.1)
            x1 = max(0, x - padding)
            y1 = max(0, y - padding)
            x2 = min(frame.shape[1], x + w + padding)
            y2 = min(frame.shape[0], y + h + padding)
            
            face_roi = frame[y1:y2, x1:x2]
            face_roi = cv2.resize(face_roi, (224, 224))
            rgb_face = cv2.cvtColor(face_roi, cv2.COLOR_BGR2RGB)
            pil_image = Image.fromarray(rgb_face)
            
            result = self.classifier(pil_image)[0]
            emotion = result['label']
            confidence = result['score']
            engagement_score = self.emotion_map.get(emotion, 0.5)
            
            return {
                'face_detected': True,
                'emotion': emotion,
                'confidence': float(confidence),
                'engagement_score': float(engagement_score),
                'face_location': {'x': int(x), 'y': int(y), 'w': int(w), 'h': int(h)},
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"❌ Error in emotion detection: {e}")
            return {
                'face_detected': False,
                'emotion': 'Error',
                'confidence': 0.0,
                'engagement_score': 0.0,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def process_base64_image(self, base64_string):
        import base64
        
        try:
            img_bytes = base64.b64decode(base64_string)
            nparr = np.frombuffer(img_bytes, np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if frame is None:
                return {
                    'face_detected': False,
                    'emotion': 'Invalid Image',
                    'engagement_score': 0.0,
                    'error': 'Failed to decode image',
                    'timestamp': datetime.now().isoformat()
                }
            
            return self.detect_emotion(frame)
            
        except Exception as e:
            print(f"❌ Error processing base64 image: {e}")
            return {
                'face_detected': False,
                'emotion': 'Processing Error',
                'engagement_score': 0.0,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
