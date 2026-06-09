"""Health Check Service - Überwacht die Systemgesundheit"""
import mysql.connector
import time
from datetime import datetime
from typing import Dict, Any, Optional
import os

class HealthCheckService:
    """Überprüft die Gesundheit aller Services"""
    
    def __init__(self):
        self.db_config = {
            'host': os.getenv('DB_HOST', 'benning-mysql'),
            'port': int(os.getenv('DB_PORT', 3306)),
            'user': os.getenv('DB_USER', 'benning'),
            'password': os.getenv('DB_PASSWORD', 'benning'),
            'database': os.getenv('DB_NAME', 'benning_device_manager')
        }
    
    def check_database(self) -> Dict[str, Any]:
        """Überprüfe Datenbank-Verbindung"""
        try:
            start_time = time.time()
            conn = mysql.connector.connect(**self.db_config)
            cursor = conn.cursor()
            
            cursor.execute("SELECT 1")
            cursor.fetchone()
            
            cursor.execute("""
                SELECT COUNT(*) FROM information_schema.tables 
                WHERE table_schema = %s
            """, (self.db_config['database'],))
            table_count = cursor.fetchone()[0]
            
            cursor.execute("SELECT COUNT(*) FROM devices")
            device_count = cursor.fetchone()[0]
            
            duration_ms = (time.time() - start_time) * 1000
            
            cursor.close()
            conn.close()
            
            return {
                'status': 'healthy',
                'response_time_ms': round(duration_ms, 2),
                'tables': table_count,
                'devices': device_count,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {
                'status': 'unhealthy',
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def check_application(self) -> Dict[str, Any]:
        """Überprüfe Anwendungs-Status"""
        try:
            required_dirs = [
                'src/core/domain',
                'src/core/usecases',
                'src/adapters/web',
                'src/adapters/persistence',
                'templates',
                'logs'
            ]
            
            missing_dirs = []
            for dir_path in required_dirs:
                if not os.path.exists(dir_path):
                    missing_dirs.append(dir_path)
            
            status = 'degraded' if missing_dirs else 'healthy'
            
            return {
                'status': status,
                'missing_dirs': missing_dirs if missing_dirs else None,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {
                'status': 'error',
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def check_filesystem(self) -> Dict[str, Any]:
        """Überprüfe Dateisystem"""
        try:
            log_dir = 'logs'
            if not os.path.exists(log_dir):
                os.makedirs(log_dir)
            
            test_file = os.path.join(log_dir, '.health_check_test')
            with open(test_file, 'w') as f:
                f.write('test')
            os.remove(test_file)
            
            return {
                'status': 'healthy',
                'writable': True,
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {
                'status': 'unhealthy',
                'writable': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def full_health_check(self) -> Dict[str, Any]:
        """Führe vollständigen Health Check durch"""
        checks = {
            'database': self.check_database(),
            'application': self.check_application(),
            'filesystem': self.check_filesystem()
        }
        
        statuses = [check.get('status') for check in checks.values()]
        if 'error' in statuses:
            overall_status = 'error'
        elif 'unhealthy' in statuses:
            overall_status = 'unhealthy'
        elif 'degraded' in statuses:
            overall_status = 'degraded'
        else:
            overall_status = 'healthy'
        
        return {
            'overall_status': overall_status,
            'checks': checks,
            'timestamp': datetime.now().isoformat()
        }
    
    def get_status_summary(self) -> str:
        """Gebe eine Text-Zusammenfassung des Status"""
        health = self.full_health_check()
        
        summary = f"""
╔════════════════════════════════════════════════════════════╗
║           BENNING DEVICE MANAGER - HEALTH CHECK            ║
╚════════════════════════════════════════════════════════════╝

Overall Status: {health['overall_status'].upper()}
Timestamp: {health['timestamp']}

DATABASE:
  Status: {health['checks']['database'].get('status', 'unknown')}
  Response Time: {health['checks']['database'].get('response_time_ms', 'N/A')} ms
  Tables: {health['checks']['database'].get('tables', 'N/A')}
  Devices: {health['checks']['database'].get('devices', 'N/A')}
  Error: {health['checks']['database'].get('error', 'None')}

APPLICATION:
  Status: {health['checks']['application'].get('status', 'unknown')}
  Missing Dirs: {health['checks']['application'].get('missing_dirs', 'None')}

FILESYSTEM:
  Status: {health['checks']['filesystem'].get('status', 'unknown')}
  Writable: {health['checks']['filesystem'].get('writable', 'unknown')}

════════════════════════════════════════════════════════════
"""
        return summary
