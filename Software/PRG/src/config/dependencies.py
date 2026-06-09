"""Dependency Injection Container - Hexagonal Architecture - KORRIGIERTE VERSION"""
import os
from threading import Lock
from src.adapters.persistence.mysql_device_repository import MySQLDeviceRepository
from src.core.usecases.device_usecases import (
    CreateDeviceUseCase,
    ListDevicesUseCase,
    GetDeviceUseCase,
    UpdateDeviceUseCase,
    DeleteDeviceUseCase
)
from src.adapters.services.logger_service import LoggerService


class Container:
    """Dependency Injection Container for all use cases and repositories"""
    
    _instance = None
    _lock = Lock()
    
    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super(Container, cls).__new__(cls)
                    cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        # Nur einmal initialisieren (Singleton Pattern)
        # FIX: Verwende hasattr() für sichere Überprüfung
        if hasattr(self, '_initialized') and self._initialized:
            return
        
        self.logger = LoggerService()
        self._init_repositories()
        self._init_usecases()
        self._initialized = True
    
    def _init_repositories(self):
        """Initialize all repositories with error handling"""
        try:
            # Get database configuration from environment variables
            db_host = os.getenv('DB_HOST', 'localhost')
            db_port = int(os.getenv('DB_PORT', '3306'))
            db_user = os.getenv('DB_USER', 'benning_user')
            db_password = os.getenv('DB_PASSWORD', 'benning_password')
            db_name = os.getenv('DB_NAME', 'benning_db')
            
            self.logger.info(
                "Initializing repositories",
                db_host=db_host,
                db_port=db_port,
                db_name=db_name
            )
            
            # Initialize MySQL Device Repository with database credentials
            self.device_repository = MySQLDeviceRepository(
                host=db_host,
                port=db_port,
                user=db_user,
                password=db_password,
                database=db_name
            )
            
            # FIX: Test database connection
            self.logger.info("Testing database connection...")
            try:
                test_devices = self.device_repository.get_all()
                self.logger.info(f"Database connection successful. Found {len(test_devices)} devices.")
            except Exception as e:
                self.logger.warning(f"Database connection test failed (this may be normal if DB is empty): {e}")
            
            self.logger.info("Device repository initialized successfully")
            
        except Exception as e:
            # FIX: Detailliertes Error-Handling
            self.logger.error(f"CRITICAL: Failed to initialize repositories: {e}", exception=e)
            print(f"\n{'='*70}")
            print(f"FEHLER: Datenbankverbindung konnte nicht hergestellt werden!")
            print(f"{'='*70}")
            print(f"Details: {e}")
            print(f"Überprüfen Sie folgende Umgebungsvariablen:")
            print(f"  - DB_HOST: {os.getenv('DB_HOST', 'localhost')}")
            print(f"  - DB_PORT: {os.getenv('DB_PORT', '3306')}")
            print(f"  - DB_USER: {os.getenv('DB_USER', 'benning_user')}")
            print(f"  - DB_NAME: {os.getenv('DB_NAME', 'benning_db')}")
            print(f"{'='*70}\n")
            raise
    
    def _init_usecases(self):
        """Initialize all use cases"""
        try:
            self.logger.info("Initializing use cases")
            
            # Device Use Cases
            self.create_device_usecase = CreateDeviceUseCase(self.device_repository)
            self.list_devices_usecase = ListDevicesUseCase(self.device_repository)
            self.get_device_usecase = GetDeviceUseCase(self.device_repository)
            self.update_device_usecase = UpdateDeviceUseCase(self.device_repository)
            self.delete_device_usecase = DeleteDeviceUseCase(self.device_repository)
            
            self.logger.info("All use cases initialized successfully")
            
        except Exception as e:
            # FIX: Error-Handling für Use Cases
            self.logger.error(f"Failed to initialize use cases: {e}", exception=e)
            raise


# Create singleton container instance (nur einmal!)
container = Container()
