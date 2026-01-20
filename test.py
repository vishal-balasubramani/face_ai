"""
Test all backend imports
"""
import sys
import os

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

print("=" * 60)
print("TESTING ALL BACKEND IMPORTS")
print("=" * 60)

tests = []

# Test models
try:
    from models.emotion_detector import EmotionDetector
    tests.append(("EmotionDetector", True, None))
except Exception as e:
    tests.append(("EmotionDetector", False, str(e)))

try:
    from models.lstm_predictor import LSTMPredictor
    tests.append(("LSTMPredictor", True, None))
except Exception as e:
    tests.append(("LSTMPredictor", False, str(e)))

try:
    from models.attention_analyzer import AttentionAnalyzer
    tests.append(("AttentionAnalyzer", True, None))
except Exception as e:
    tests.append(("AttentionAnalyzer", False, str(e)))

# Test services
try:
    from services.session_manager import SessionManager
    tests.append(("SessionManager", True, None))
except Exception as e:
    tests.append(("SessionManager", False, str(e)))

try:
    from services.analytics_engine import AnalyticsEngine
    tests.append(("AnalyticsEngine", True, None))
except Exception as e:
    tests.append(("AnalyticsEngine", False, str(e)))

try:
    from services.report_generator import ReportGenerator
    tests.append(("ReportGenerator", True, None))
except Exception as e:
    tests.append(("ReportGenerator", False, str(e)))

try:
    from services.gemini_advisor import GeminiAdvisor
    tests.append(("GeminiAdvisor", True, None))
except Exception as e:
    tests.append(("GeminiAdvisor", False, str(e)))

try:
    from services.alert_manager import AlertManager
    tests.append(("AlertManager", True, None))
except Exception as e:
    tests.append(("AlertManager", False, str(e)))

# Test database
try:
    from database.db import init_db, get_db
    tests.append(("Database", True, None))
except Exception as e:
    tests.append(("Database", False, str(e)))

# Test utils
try:
    from utils.config import Config
    tests.append(("Config", True, None))
except Exception as e:
    tests.append(("Config", False, str(e)))

try:
    from utils.websocket_manager import ConnectionManager
    tests.append(("ConnectionManager", True, None))
except Exception as e:
    tests.append(("ConnectionManager", False, str(e)))

try:
    from utils.logger import logger
    tests.append(("Logger", True, None))
except Exception as e:
    tests.append(("Logger", False, str(e)))

# Print results
print("\nRESULTS:")
print("-" * 60)

passed = 0
failed = 0

for name, success, error in tests:
    if success:
        print(f"✅ {name:<25} PASSED")
        passed += 1
    else:
        print(f"❌ {name:<25} FAILED: {error}")
        failed += 1

print("-" * 60)
print(f"\nTotal: {passed + failed} | Passed: {passed} | Failed: {failed}")

if failed == 0:
    print("\n🎉 ALL IMPORTS SUCCESSFUL! Backend is ready!")
    print("\nNext step: Run 'python main.py' to start the server")
else:
    print(f"\n⚠️ {failed} imports failed. Fix them before starting server.")

print("=" * 60)
