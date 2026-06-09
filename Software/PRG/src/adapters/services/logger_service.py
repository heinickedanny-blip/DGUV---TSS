"""Logger Service - Strukturiertes Logging ohne Verzeichnis-Erstellung"""
import json
import sys
from datetime import datetime
from typing import Optional, Any


class LoggerService:
    """Singleton Logger Service - Loggt zu stdout/stderr"""
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(LoggerService, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if not self._initialized:
            self._initialized = True
            print("✓ LoggerService initialized (stdout/stderr mode)")
    
    def _format_log(self, level: str, message: str, **kwargs) -> str:
        """Format log message as JSON"""
        log_data = {
            "timestamp": datetime.now().isoformat(),
            "level": level,
            "message": message,
            **kwargs
        }
        return json.dumps(log_data, ensure_ascii=False)
    
    def debug(self, message: str, **kwargs):
        """Log debug message"""
        log_msg = self._format_log("DEBUG", message, **kwargs)
        print(log_msg, file=sys.stdout)
    
    def info(self, message: str, **kwargs):
        """Log info message"""
        log_msg = self._format_log("INFO", message, **kwargs)
        print(log_msg, file=sys.stdout)
    
    def warning(self, message: str, **kwargs):
        """Log warning message"""
        log_msg = self._format_log("WARNING", message, **kwargs)
        print(log_msg, file=sys.stdout)
    
    def error(self, message: str, exception: Optional[Exception] = None, **kwargs):
        """Log error message"""
        error_info = {
            "exception": str(exception) if exception else None,
            "exception_type": type(exception).__name__ if exception else None,
            **kwargs
        }
        log_msg = self._format_log("ERROR", message, **error_info)
        print(log_msg, file=sys.stderr)
    
    def critical(self, message: str, exception: Optional[Exception] = None, **kwargs):
        """Log critical message"""
        error_info = {
            "exception": str(exception) if exception else None,
            "exception_type": type(exception).__name__ if exception else None,
            **kwargs
        }
        log_msg = self._format_log("CRITICAL", message, **error_info)
        print(log_msg, file=sys.stderr)
    
    def log_db_operation(self, operation: str, table: str, result: str, 
                        duration_ms: float, **kwargs):
        """Log database operation"""
        log_data = {
            "timestamp": datetime.now().isoformat(),
            "level": "DB_OPERATION",
            "operation": operation,
            "table": table,
            "result": result,
            "duration_ms": round(duration_ms, 2),
            **kwargs
        }
        log_msg = json.dumps(log_data, ensure_ascii=False)
        print(log_msg, file=sys.stdout)
    
    def log_api_request(self, method: str, path: str, status_code: int,
                       duration_ms: float, **kwargs):
        """Log API request"""
        log_data = {
            "timestamp": datetime.now().isoformat(),
            "level": "API_REQUEST",
            "method": method,
            "path": path,
            "status_code": status_code,
            "duration_ms": round(duration_ms, 2),
            **kwargs
        }
        log_msg = json.dumps(log_data, ensure_ascii=False)
        print(log_msg, file=sys.stdout)
    
    def log_health_check(self, status: str, **kwargs):
        """Log health check"""
        log_data = {
            "timestamp": datetime.now().isoformat(),
            "level": "HEALTH_CHECK",
            "status": status,
            **kwargs
        }
        log_msg = json.dumps(log_data, ensure_ascii=False)
        print(log_msg, file=sys.stdout)
