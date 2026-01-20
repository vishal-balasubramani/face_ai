import redis
import json
import os
from typing import Optional, Dict

class RedisCache:
    """
    Redis cache for real-time state management
    Optional - only used in production
    """
    
    def __init__(self):
        redis_host = os.getenv("REDIS_HOST", "localhost")
        redis_port = int(os.getenv("REDIS_PORT", 6379))
        
        try:
            self.client = redis.Redis(
                host=redis_host,
                port=redis_port,
                decode_responses=True
            )
            self.client.ping()
            self.enabled = True
            print("✅ Redis cache connected")
        except Exception as e:
            print(f"⚠️ Redis not available: {e}. Using in-memory cache.")
            self.enabled = False
            self.memory_cache = {}
    
    def set(self, key: str, value: Dict, expiry: int = 3600):
        """Set value with expiry (seconds)"""
        if self.enabled:
            self.client.setex(key, expiry, json.dumps(value))
        else:
            self.memory_cache[key] = value
    
    def get(self, key: str) -> Optional[Dict]:
        """Get value by key"""
        if self.enabled:
            data = self.client.get(key)
            return json.loads(data) if data else None
        else:
            return self.memory_cache.get(key)
    
    def delete(self, key: str):
        """Delete key"""
        if self.enabled:
            self.client.delete(key)
        else:
            self.memory_cache.pop(key, None)
    
    def exists(self, key: str) -> bool:
        """Check if key exists"""
        if self.enabled:
            return bool(self.client.exists(key))
        else:
            return key in self.memory_cache
