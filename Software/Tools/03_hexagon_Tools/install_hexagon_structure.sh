#!/bin/bash

################################################################################
# Hexagonal Architecture Installation Script
# Benning Device Manager - Refactoring zu Hexagonaler Architektur
# 
# Dieses Skript erstellt automatisch die neue Projektstruktur mit:
# - Domain Models und Use Cases (Core)
# - Adapter für Datenbank, Web und Services
# - Konfiguration und Dependency Injection
# - Test-Struktur
# - Alle notwendigen Python-Module
#
# Verwendung: bash install_hexagon_structure.sh [project_path]
# Beispiel:   bash install_hexagon_structure.sh ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
################################################################################

set -e  # Beende bei Fehler

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Konfiguration
PROJECT_PATH="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Funktionen
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

create_directory_structure() {
    print_header "Erstelle Verzeichnisstruktur"
    
    local dirs=(
        "src/core/domain"
        "src/core/usecases"
        "src/core/ports"
        "src/adapters/persistence"
        "src/adapters/web/routes"
        "src/adapters/web/dto"
        "src/adapters/web/presenters"
        "src/adapters/web/middleware"
        "src/adapters/file_storage"
        "src/adapters/qr_generation"
        "src/config"
        "tests/unit/domain"
        "tests/unit/usecases"
        "tests/unit/adapters"
        "tests/integration/repositories"
        "tests/integration/routes"
        "tests/fixtures"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$PROJECT_PATH/$dir"
        touch "$PROJECT_PATH/$dir/__init__.py"
        print_success "Erstellt: $dir"
    done
}

create_core_domain_models() {
    print_header "Erstelle Domain Models"
    
    # Device Model
    cat > "$PROJECT_PATH/src/core/domain/device.py" << 'EOF'
"""
Device Domain Model
Repräsentiert ein Gerät im System
"""
from dataclasses import dataclass
from datetime import datetime, date, timedelta
from typing import Optional


@dataclass
class DeviceId:
    """Value Object für Device ID"""
    value: str
    
    def __post_init__(self):
        if not self.value.startswith('BENNING-'):
            raise ValueError("Device ID muss mit 'BENNING-' beginnen")
    
    def __str__(self):
        return self.value


@dataclass
class Device:
    """Device Entity"""
    id: DeviceId
    name: str
    type: str
    location: str
    manufacturer: str
    serial_number: str
    purchase_date: date
    last_inspection: Optional[date]
    next_inspection: date
    status: str  # 'active', 'inactive', 'retired'
    notes: str
    created_at: datetime
    
    def is_due_for_inspection(self) -> bool:
        """Prüfe, ob Inspektion fällig ist"""
        return datetime.now().date() >= self.next_inspection
    
    def schedule_next_inspection(self, interval_days: int = 365) -> date:
        """Plane nächste Inspektion"""
        return datetime.now().date() + timedelta(days=interval_days)
    
    def mark_as_inspected(self, inspection_date: date) -> None:
        """Markiere Gerät als inspiziert"""
        self.last_inspection = inspection_date
        self.next_inspection = self.schedule_next_inspection()
    
    def is_active(self) -> bool:
        """Prüfe, ob Gerät aktiv ist"""
        return self.status == 'active'
EOF
    print_success "Device Model erstellt"
    
    # Inspection Model
    cat > "$PROJECT_PATH/src/core/domain/inspection.py" << 'EOF'
"""
Inspection Domain Model
Repräsentiert eine Geräteinspektionen
"""
from dataclasses import dataclass
from datetime import datetime, date, timedelta
from typing import Optional


@dataclass
class Inspection:
    """Inspection Entity"""
    id: Optional[int]
    device_id: str
    inspection_date: date
    inspector_name: str
    result: str  # 'passed', 'failed', 'pending'
    notes: str
    next_inspection_date: date
    created_at: datetime
    
    def is_passed(self) -> bool:
        """Prüfe, ob Inspektion bestanden"""
        return self.result == 'passed'
    
    def is_failed(self) -> bool:
        """Prüfe, ob Inspektion nicht bestanden"""
        return self.result == 'failed'
    
    def schedule_next_inspection(self, interval_days: int = 365) -> date:
        """Plane nächste Inspektion"""
        return self.inspection_date + timedelta(days=interval_days)
EOF
    print_success "Inspection Model erstellt"
    
    # USB-C Inspection Model
    cat > "$PROJECT_PATH/src/core/domain/usbc_inspection.py" << 'EOF'
"""
USB-C Inspection Domain Model
Spezialisierte Inspektion für USB-C Kabel
"""
from dataclasses import dataclass, field
from typing import List, Optional, Dict
from .inspection import Inspection


@dataclass
class ResistanceTest:
    """Widerstandsmessung für USB-C Pins"""
    pin_name: str
    resistance_value: float
    expected_min: float
    expected_max: float
    
    def is_passed(self) -> bool:
        """Prüfe, ob Messung im erwarteten Bereich liegt"""
        return self.expected_min <= self.resistance_value <= self.expected_max


@dataclass
class ProtocolTest:
    """Protokoll-Test für USB-C"""
    protocol_name: str
    supported: bool
    speed_mbps: Optional[int] = None
    power_delivery: bool = False
    max_power_w: Optional[int] = None


@dataclass
class USBCInspection(Inspection):
    """USB-C spezifische Inspektion"""
    device_functional: bool = False
    battery_checked: bool = False
    cable_visual_ok: bool = False
    cable_id: str = ""
    cable_connected: bool = False
    basic_functions_ok: bool = False
    resistance_tests: List[ResistanceTest] = field(default_factory=list)
    protocol_tests: List[ProtocolTest] = field(default_factory=list)
    pinout_photo_path: Optional[str] = None
    emarker_data: Optional[Dict] = None
    
    def all_tests_passed(self) -> bool:
        """Prüfe, ob alle Tests bestanden"""
        basic_checks = (
            self.device_functional and
            self.battery_checked and
            self.cable_visual_ok and
            self.cable_connected and
            self.basic_functions_ok
        )
        
        resistance_ok = all(
            test.is_passed() for test in self.resistance_tests
        ) if self.resistance_tests else True
        
        return basic_checks and resistance_ok
    
    def get_failed_tests(self) -> List[str]:
        """Gebe Liste fehlgeschlagener Tests zurück"""
        failed = []
        if not self.device_functional:
            failed.append("Gerät funktioniert nicht")
        if not self.battery_checked:
            failed.append("Batterie nicht geprüft")
        if not self.cable_visual_ok:
            failed.append("Kabel visuell nicht OK")
        if not self.cable_connected:
            failed.append("Kabel nicht verbunden")
        if not self.basic_functions_ok:
            failed.append("Grundfunktionen nicht OK")
        
        failed.extend([
            f"{test.pin_name} außerhalb des Bereichs"
            for test in self.resistance_tests
            if not test.is_passed()
        ])
        
        return failed
EOF
    print_success "USB-C Inspection Model erstellt"
}

create_core_ports() {
    print_header "Erstelle Port-Interfaces"
    
    # Repository Port
    cat > "$PROJECT_PATH/src/core/ports/device_repository.py" << 'EOF'
"""
Device Repository Port
Definiert die Schnittstelle für Device-Persistierung
"""
from abc import ABC, abstractmethod
from typing import List, Optional
from ..domain.device import Device, DeviceId


class DeviceRepository(ABC):
    """Port für Device-Persistierung"""
    
    @abstractmethod
    def find_by_id(self, device_id: DeviceId) -> Optional[Device]:
        """Finde Gerät nach ID"""
        pass
    
    @abstractmethod
    def find_all(self) -> List[Device]:
        """Finde alle Geräte"""
        pass
    
    @abstractmethod
    def find_active(self) -> List[Device]:
        """Finde alle aktiven Geräte"""
        pass
    
    @abstractmethod
    def find_due_for_inspection(self) -> List[Device]:
        """Finde Geräte, deren Inspektion fällig ist"""
        pass
    
    @abstractmethod
    def save(self, device: Device) -> None:
        """Speichere Gerät"""
        pass
    
    @abstractmethod
    def delete(self, device_id: DeviceId) -> None:
        """Lösche Gerät"""
        pass
    
    @abstractmethod
    def get_next_id(self) -> DeviceId:
        """Gebe nächste verfügbare Device ID zurück"""
        pass
EOF
    print_success "Device Repository Port erstellt"
    
    # File Storage Port
    cat > "$PROJECT_PATH/src/core/ports/file_storage.py" << 'EOF'
"""
File Storage Port
Definiert die Schnittstelle für Dateispeicherung
"""
from abc import ABC, abstractmethod
from typing import Optional


class FileStorage(ABC):
    """Port für Dateispeicherung"""
    
    @abstractmethod
    def upload(self, file_content: bytes, filename: str, subfolder: str = "") -> str:
        """Speichere Datei und gebe Pfad zurück"""
        pass
    
    @abstractmethod
    def delete(self, filepath: str) -> None:
        """Lösche Datei"""
        pass
    
    @abstractmethod
    def exists(self, filepath: str) -> bool:
        """Prüfe, ob Datei existiert"""
        pass
    
    @abstractmethod
    def get_url(self, filepath: str) -> str:
        """Gebe öffentliche URL für Datei zurück"""
        pass
EOF
    print_success "File Storage Port erstellt"
    
    # QR Generator Port
    cat > "$PROJECT_PATH/src/core/ports/qr_generator.py" << 'EOF'
"""
QR Generator Port
Definiert die Schnittstelle für QR-Code Generierung
"""
from abc import ABC, abstractmethod


class QRGenerator(ABC):
    """Port für QR-Code Generierung"""
    
    @abstractmethod
    def generate(self, data: str) -> bytes:
        """Generiere QR-Code und gebe PNG-Bytes zurück"""
        pass
EOF
    print_success "QR Generator Port erstellt"
}

create_core_usecases() {
    print_header "Erstelle Use Cases"
    
    cat > "$PROJECT_PATH/src/core/usecases/device_usecases.py" << 'EOF'
"""
Device Use Cases
Geschäftslogik für Geräteverwaltung
"""
from typing import List, Optional
from ..domain.device import Device, DeviceId
from ..ports.device_repository import DeviceRepository


class GetDeviceUseCase:
    """Use Case: Gerät abrufen"""
    
    def __init__(self, device_repository: DeviceRepository):
        self.device_repository = device_repository
    
    def execute(self, device_id: str) -> Device:
        device = self.device_repository.find_by_id(DeviceId(device_id))
        if not device:
            raise ValueError(f"Gerät {device_id} nicht gefunden")
        return device


class ListDevicesUseCase:
    """Use Case: Alle Geräte auflisten"""
    
    def __init__(self, device_repository: DeviceRepository):
        self.device_repository = device_repository
    
    def execute(self) -> List[Device]:
        return self.device_repository.find_all()


class ListActiveDevicesUseCase:
    """Use Case: Aktive Geräte auflisten"""
    
    def __init__(self, device_repository: DeviceRepository):
        self.device_repository = device_repository
    
    def execute(self) -> List[Device]:
        return self.device_repository.find_active()


class CreateDeviceUseCase:
    """Use Case: Neues Gerät erstellen"""
    
    def __init__(self, device_repository: DeviceRepository):
        self.device_repository = device_repository
    
    def execute(self, device_data: dict) -> Device:
        # Generiere nächste ID
        next_id = self.device_repository.get_next_id()
        
        # Erstelle Device
        device = Device(
            id=next_id,
            name=device_data['name'],
            type=device_data['type'],
            location=device_data['location'],
            manufacturer=device_data.get('manufacturer', ''),
            serial_number=device_data.get('serial_number', ''),
            purchase_date=device_data.get('purchase_date'),
            last_inspection=None,
            next_inspection=device_data.get('next_inspection'),
            status='active',
            notes=device_data.get('notes', ''),
            created_at=device_data.get('created_at')
        )
        
        # Speichere
        self.device_repository.save(device)
        return device


class GetDevicesDueForInspectionUseCase:
    """Use Case: Geräte mit fälliger Inspektion abrufen"""
    
    def __init__(self, device_repository: DeviceRepository):
        self.device_repository = device_repository
    
    def execute(self) -> List[Device]:
        return self.device_repository.find_due_for_inspection()
EOF
    print_success "Device Use Cases erstellt"
}

create_adapters() {
    print_header "Erstelle Adapter-Grundgerüste"
    
    # MySQL Repository Adapter
    cat > "$PROJECT_PATH/src/adapters/persistence/mysql_device_repository.py" << 'EOF'
"""
MySQL Device Repository Adapter
Konkrete Implementierung des Device Repository Ports
"""
from typing import List, Optional
import mysql.connector
from ...core.domain.device import Device, DeviceId
from ...core.ports.device_repository import DeviceRepository
from datetime import datetime, date


class MySQLDeviceRepository(DeviceRepository):
    """MySQL-basierte Implementierung des Device Repository"""
    
    def __init__(self, db_config: dict):
        self.db_config = db_config
        self.connection = None
    
    def _get_connection(self):
        """Stelle Datenbankverbindung her"""
        if not self.connection or not self.connection.is_connected():
            self.connection = mysql.connector.connect(**self.db_config)
        return self.connection
    
    def find_by_id(self, device_id: DeviceId) -> Optional[Device]:
        """Finde Gerät nach ID"""
        conn = self._get_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            cursor.execute("SELECT * FROM devices WHERE id = %s", (str(device_id),))
            row = cursor.fetchone()
            
            if row:
                return self._map_to_device(row)
            return None
        finally:
            cursor.close()
    
    def find_all(self) -> List[Device]:
        """Finde alle Geräte"""
        conn = self._get_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            cursor.execute("SELECT * FROM devices ORDER BY id")
            rows = cursor.fetchall()
            return [self._map_to_device(row) for row in rows]
        finally:
            cursor.close()
    
    def find_active(self) -> List[Device]:
        """Finde alle aktiven Geräte"""
        conn = self._get_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            cursor.execute("SELECT * FROM devices WHERE status = 'active' ORDER BY id")
            rows = cursor.fetchall()
            return [self._map_to_device(row) for row in rows]
        finally:
            cursor.close()
    
    def find_due_for_inspection(self) -> List[Device]:
        """Finde Geräte, deren Inspektion fällig ist"""
        conn = self._get_connection()
        cursor = conn.cursor(dictionary=True)
        
        try:
            cursor.execute("""
                SELECT * FROM devices 
                WHERE status = 'active' AND next_inspection < CURDATE()
                ORDER BY next_inspection ASC
            """)
            rows = cursor.fetchall()
            return [self._map_to_device(row) for row in rows]
        finally:
            cursor.close()
    
    def save(self, device: Device) -> None:
        """Speichere Gerät"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        try:
            cursor.execute("""
                INSERT INTO devices 
                (id, name, type, location, manufacturer, serial_number, 
                 purchase_date, last_inspection, next_inspection, status, notes, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                name = VALUES(name), type = VALUES(type), location = VALUES(location),
                manufacturer = VALUES(manufacturer), serial_number = VALUES(serial_number),
                purchase_date = VALUES(purchase_date), last_inspection = VALUES(last_inspection),
                next_inspection = VALUES(next_inspection), status = VALUES(status), notes = VALUES(notes)
            """, (
                str(device.id), device.name, device.type, device.location,
                device.manufacturer, device.serial_number, device.purchase_date,
                device.last_inspection, device.next_inspection, device.status,
                device.notes, device.created_at
            ))
            conn.commit()
        finally:
            cursor.close()
    
    def delete(self, device_id: DeviceId) -> None:
        """Lösche Gerät"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        try:
            cursor.execute("DELETE FROM devices WHERE id = %s", (str(device_id),))
            conn.commit()
        finally:
            cursor.close()
    
    def get_next_id(self) -> DeviceId:
        """Gebe nächste verfügbare Device ID zurück"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        try:
            cursor.execute("""
                SELECT id FROM devices 
                WHERE id LIKE 'BENNING-%' 
                ORDER BY id DESC 
                LIMIT 1
            """)
            result = cursor.fetchone()
            
            if result:
                last_id = result[0]
                number = int(last_id.split('-')[1]) + 1
                return DeviceId(f"BENNING-{number:03d}")
            else:
                return DeviceId("BENNING-001")
        finally:
            cursor.close()
    
    def _map_to_device(self, row: dict) -> Device:
        """Konvertiere Datenbankzeile zu Device-Objekt"""
        return Device(
            id=DeviceId(row['id']),
            name=row['name'],
            type=row['type'],
            location=row['location'],
            manufacturer=row.get('manufacturer', ''),
            serial_number=row.get('serial_number', ''),
            purchase_date=row.get('purchase_date'),
            last_inspection=row.get('last_inspection'),
            next_inspection=row.get('next_inspection'),
            status=row.get('status', 'active'),
            notes=row.get('notes', ''),
            created_at=row.get('created_at', datetime.now())
        )
    
    def close(self):
        """Schließe Datenbankverbindung"""
        if self.connection and self.connection.is_connected():
            self.connection.close()
EOF
    print_success "MySQL Device Repository Adapter erstellt"
    
    # Flask Routes Adapter
    cat > "$PROJECT_PATH/src/adapters/web/routes/device_routes.py" << 'EOF'
"""
Device Routes - Flask Web Adapter
"""
from flask import Blueprint, request, jsonify, render_template
from datetime import datetime
from ...core.usecases.device_usecases import (
    GetDeviceUseCase,
    ListDevicesUseCase,
    CreateDeviceUseCase,
    GetDevicesDueForInspectionUseCase
)

device_bp = Blueprint('devices', __name__, url_prefix='/devices')


class DeviceRoutes:
    """Device Route Handler"""
    
    def __init__(self, 
                 get_device_uc: GetDeviceUseCase,
                 list_devices_uc: ListDevicesUseCase,
                 create_device_uc: CreateDeviceUseCase,
                 get_due_uc: GetDevicesDueForInspectionUseCase):
        self.get_device_uc = get_device_uc
        self.list_devices_uc = list_devices_uc
        self.create_device_uc = create_device_uc
        self.get_due_uc = get_due_uc
        self._register_routes()
    
    def _register_routes(self):
        """Registriere Routes"""
        device_bp.route('/', methods=['GET'])(self.list_devices)
        device_bp.route('/<device_id>', methods=['GET'])(self.get_device)
        device_bp.route('', methods=['POST'])(self.create_device)
    
    def list_devices(self):
        """GET /devices - Alle Geräte auflisten"""
        try:
            devices = self.list_devices_uc.execute()
            return jsonify([{
                'id': str(d.id),
                'name': d.name,
                'type': d.type,
                'location': d.location,
                'status': d.status,
                'next_inspection': d.next_inspection.isoformat() if d.next_inspection else None
            } for d in devices])
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    def get_device(self, device_id: str):
        """GET /devices/<device_id> - Gerät abrufen"""
        try:
            device = self.get_device_uc.execute(device_id)
            return jsonify({
                'id': str(device.id),
                'name': device.name,
                'type': device.type,
                'location': device.location,
                'manufacturer': device.manufacturer,
                'serial_number': device.serial_number,
                'purchase_date': device.purchase_date.isoformat() if device.purchase_date else None,
                'last_inspection': device.last_inspection.isoformat() if device.last_inspection else None,
                'next_inspection': device.next_inspection.isoformat() if device.next_inspection else None,
                'status': device.status,
                'notes': device.notes
            })
        except ValueError as e:
            return jsonify({'error': str(e)}), 404
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    def create_device(self):
        """POST /devices - Neues Gerät erstellen"""
        try:
            data = request.json
            device = self.create_device_uc.execute(data)
            return jsonify({
                'id': str(device.id),
                'message': 'Gerät erfolgreich erstellt'
            }), 201
        except Exception as e:
            return jsonify({'error': str(e)}), 400
EOF
    print_success "Flask Device Routes Adapter erstellt"
}

create_config() {
    print_header "Erstelle Konfigurationsdateien"
    
    # Settings
    cat > "$PROJECT_PATH/src/config/settings.py" << 'EOF'
"""
Application Settings
"""
import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    """Anwendungs-Einstellungen"""
    
    # Flask
    FLASK_ENV = os.getenv('FLASK_ENV', 'development')
    FLASK_DEBUG = os.getenv('FLASK_DEBUG', 'True') == 'True'
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    
    # Database
    DB_HOST = os.getenv('DB_HOST', 'localhost')
    DB_PORT = int(os.getenv('DB_PORT', '3307'))
    DB_USER = os.getenv('DB_USER', 'benning')
    DB_PASSWORD = os.getenv('DB_PASSWORD', 'benning')
    DB_NAME = os.getenv('DB_NAME', 'benning_device_manager')
    DB_CHARSET = 'utf8mb4'
    DB_COLLATION = 'utf8mb4_unicode_ci'
    
    # File Storage
    UPLOAD_FOLDER = os.getenv('UPLOAD_FOLDER', 'static/uploads')
    MAX_CONTENT_LENGTH = int(os.getenv('MAX_CONTENT_LENGTH', 10 * 1024 * 1024))
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
    
    # Application
    APP_NAME = 'Benning Device Manager'
    APP_VERSION = '2.0.0'
    
    @classmethod
    def get_db_config(cls) -> dict:
        """Gebe Datenbank-Konfiguration zurück"""
        return {
            'host': cls.DB_HOST,
            'port': cls.DB_PORT,
            'user': cls.DB_USER,
            'password': cls.DB_PASSWORD,
            'database': cls.DB_NAME,
            'charset': cls.DB_CHARSET,
            'collation': cls.DB_COLLATION
        }
EOF
    print_success "Settings erstellt"
    
    # Dependency Injection
    cat > "$PROJECT_PATH/src/config/dependencies.py" << 'EOF'
"""
Dependency Injection Container
"""
from ..core.ports.device_repository import DeviceRepository
from ..adapters.persistence.mysql_device_repository import MySQLDeviceRepository
from ..core.usecases.device_usecases import (
    GetDeviceUseCase,
    ListDevicesUseCase,
    CreateDeviceUseCase,
    GetDevicesDueForInspectionUseCase
)
from .settings import Settings


class DIContainer:
    """Dependency Injection Container"""
    
    def __init__(self, settings: Settings):
        self.settings = settings
        self._services = {}
    
    def get_device_repository(self) -> DeviceRepository:
        """Gebe Device Repository zurück"""
        if 'device_repository' not in self._services:
            db_config = self.settings.get_db_config()
            self._services['device_repository'] = MySQLDeviceRepository(db_config)
        return self._services['device_repository']
    
    def get_get_device_usecase(self) -> GetDeviceUseCase:
        """Gebe GetDevice Use Case zurück"""
        return GetDeviceUseCase(self.get_device_repository())
    
    def get_list_devices_usecase(self) -> ListDevicesUseCase:
        """Gebe ListDevices Use Case zurück"""
        return ListDevicesUseCase(self.get_device_repository())
    
    def get_create_device_usecase(self) -> CreateDeviceUseCase:
        """Gebe CreateDevice Use Case zurück"""
        return CreateDeviceUseCase(self.get_device_repository())
    
    def get_get_devices_due_usecase(self) -> GetDevicesDueForInspectionUseCase:
        """Gebe GetDevicesDueForInspection Use Case zurück"""
        return GetDevicesDueForInspectionUseCase(self.get_device_repository())
    
    def close(self):
        """Schließe alle Ressourcen"""
        if 'device_repository' in self._services:
            self._services['device_repository'].close()
EOF
    print_success "Dependency Injection Container erstellt"
}

create_main_app() {
    print_header "Erstelle Hauptanwendung"
    
    cat > "$PROJECT_PATH/src/main.py" << 'EOF'
"""
Benning Device Manager - Hexagonal Architecture
Main Application Entry Point
"""
from flask import Flask, render_template, jsonify
from config.settings import Settings
from config.dependencies import DIContainer
from adapters.web.routes.device_routes import DeviceRoutes, device_bp


def create_app(settings: Settings = None) -> Flask:
    """Factory für Flask-Anwendung"""
    
    if settings is None:
        settings = Settings()
    
    app = Flask(__name__)
    app.config['SECRET_KEY'] = settings.SECRET_KEY
    app.config['UPLOAD_FOLDER'] = settings.UPLOAD_FOLDER
    app.config['MAX_CONTENT_LENGTH'] = settings.MAX_CONTENT_LENGTH
    
    # Dependency Injection
    di_container = DIContainer(settings)
    app.di_container = di_container
    
    # Routes registrieren
    device_routes = DeviceRoutes(
        get_device_uc=di_container.get_get_device_usecase(),
        list_devices_uc=di_container.get_list_devices_usecase(),
        create_device_uc=di_container.get_create_device_usecase(),
        get_due_uc=di_container.get_get_devices_due_usecase()
    )
    app.register_blueprint(device_bp)
    
    # Error Handler
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Not found'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'Internal server error'}), 500
    
    # Health Check
    @app.route('/health')
    def health():
        return jsonify({'status': 'healthy', 'version': settings.APP_VERSION})
    
    return app


if __name__ == '__main__':
    app = create_app()
    print(f"\n{'='*60}")
    print(f"🚀 {Settings.APP_NAME} v{Settings.APP_VERSION}")
    print(f"   Hexagonal Architecture Edition")
    print(f"   Running on http://0.0.0.0:5000")
    print(f"{'='*60}\n")
    app.run(host='0.0.0.0', port=5000, debug=Settings.FLASK_DEBUG)
EOF
    print_success "Hauptanwendung erstellt"
}

create_tests() {
    print_header "Erstelle Test-Struktur"
    
    # Unit Test für Device Model
    cat > "$PROJECT_PATH/tests/unit/domain/test_device.py" << 'EOF'
"""
Unit Tests für Device Domain Model
"""
import unittest
from datetime import date, datetime, timedelta
from src.core.domain.device import Device, DeviceId


class TestDeviceId(unittest.TestCase):
    """Tests für DeviceId Value Object"""
    
    def test_valid_device_id(self):
        """Test: Gültige Device ID"""
        device_id = DeviceId("BENNING-001")
        self.assertEqual(str(device_id), "BENNING-001")
    
    def test_invalid_device_id(self):
        """Test: Ungültige Device ID"""
        with self.assertRaises(ValueError):
            DeviceId("INVALID-001")


class TestDevice(unittest.TestCase):
    """Tests für Device Entity"""
    
    def setUp(self):
        """Richte Test-Fixtures auf"""
        self.device = Device(
            id=DeviceId("BENNING-001"),
            name="Test Device",
            type="Power Supply",
            location="Lab 1",
            manufacturer="Benning",
            serial_number="SN123456",
            purchase_date=date(2023, 1, 1),
            last_inspection=date(2024, 1, 1),
            next_inspection=date(2025, 1, 1),
            status='active',
            notes="Test device",
            created_at=datetime.now()
        )
    
    def test_is_active(self):
        """Test: Gerät ist aktiv"""
        self.assertTrue(self.device.is_active())
    
    def test_is_due_for_inspection(self):
        """Test: Inspektion ist fällig"""
        self.device.next_inspection = date.today() - timedelta(days=1)
        self.assertTrue(self.device.is_due_for_inspection())
    
    def test_schedule_next_inspection(self):
        """Test: Nächste Inspektion planen"""
        next_date = self.device.schedule_next_inspection(365)
        expected = date.today() + timedelta(days=365)
        self.assertEqual(next_date, expected)


if __name__ == '__main__':
    unittest.main()
EOF
    print_success "Device Model Tests erstellt"
}

create_requirements() {
    print_header "Erstelle requirements.txt"
    
    cat > "$PROJECT_PATH/requirements_hexagon.txt" << 'EOF'
# Core Framework
Flask==2.3.3
Werkzeug==2.3.7

# Database
mysql-connector-python==8.1.0

# Utilities
python-dotenv==1.0.0
qrcode==7.4.2
Pillow==10.0.0

# Testing
pytest==7.4.0
pytest-cov==4.1.0
pytest-mock==3.11.1

# Development
black==23.9.1
flake8==6.1.0
mypy==1.5.1
isort==5.12.0

# Production
gunicorn==21.2.0
EOF
    print_success "requirements_hexagon.txt erstellt"
}

create_env_file() {
    print_header "Erstelle .env.example"
    
    cat > "$PROJECT_PATH/.env.example" << 'EOF'
# Flask Configuration
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-secret-key-change-in-production

# Database Configuration
DB_HOST=localhost
DB_PORT=3307
DB_USER=benning
DB_PASSWORD=benning
DB_NAME=benning_device_manager

# File Storage
UPLOAD_FOLDER=static/uploads
MAX_CONTENT_LENGTH=10485760

# Application
APP_NAME=Benning Device Manager
APP_VERSION=2.0.0
EOF
    print_success ".env.example erstellt"
}

create_readme() {
    print_header "Erstelle README.md"
    
    cat > "$PROJECT_PATH/README_HEXAGON.md" << 'EOF'
# Benning Device Manager - Hexagonal Architecture

## Überblick

Dies ist eine Refactored-Version der Benning Device Manager Anwendung mit einer **hexagonalen Softwarearchitektur** (auch bekannt als Ports & Adapters Pattern).

## Architektur

### Struktur

```
src/
├── core/                    # Geschäftslogik (Framework-unabhängig)
│   ├── domain/             # Domain Models (Entities, Value Objects)
│   ├── usecases/           # Anwendungs-spezifische Geschäftsregeln
│   └── ports/              # Schnittstellen (Abstraktion)
├── adapters/               # Konkrete Implementierungen
│   ├── persistence/        # Datenbank-Adapter
│   ├── web/                # Web-Framework Adapter (Flask)
│   ├── file_storage/       # Datei-Speicherung
│   └── qr_generation/      # QR-Code Generierung
└── config/                 # Konfiguration & DI
```

## Installation

### 1. Virtuelle Umgebung erstellen

```bash
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# oder
venv\Scripts\activate  # Windows
```

### 2. Dependencies installieren

```bash
pip install -r requirements_hexagon.txt
```

### 3. Umgebungsvariablen konfigurieren

```bash
cp .env.example .env
# Bearbeite .env mit deinen Einstellungen
```

### 4. Datenbank initialisieren

```bash
# Stelle sicher, dass MySQL läuft
mysql -u root -p < database/schema.sql
```

### 5. Anwendung starten

```bash
python src/main.py
```

Die Anwendung läuft unter `http://localhost:5000`

## Vorteile der Hexagonalen Architektur

- **Testbarkeit**: Geschäftslogik ist vom Framework unabhängig
- **Wartbarkeit**: Klare Trennung der Verantwortlichkeiten
- **Flexibilität**: Adapter können einfach ausgetauscht werden
- **Wiederverwendbarkeit**: Use Cases können in verschiedenen Kontexten genutzt werden

## Testing

### Unit Tests ausführen

```bash
pytest tests/unit/
```

### Integration Tests ausführen

```bash
pytest tests/integration/
```

### Mit Coverage

```bash
pytest --cov=src tests/
```

## API-Endpoints

### Geräte

- `GET /devices` - Alle Geräte auflisten
- `GET /devices/<device_id>` - Gerät abrufen
- `POST /devices` - Neues Gerät erstellen

### Health Check

- `GET /health` - Anwendungs-Status

## Migrationsanleitung

Siehe `MIGRATION.md` für Anweisungen zur Migration vom alten Code.

## Lizenz

MIT
EOF
    print_success "README_HEXAGON.md erstellt"
}

create_migration_guide() {
    print_header "Erstelle Migrationsanleitung"
    
    cat > "$PROJECT_PATH/MIGRATION.md" << 'EOF'
# Migrationsanleitung: Von Monolith zu Hexagonaler Architektur

## Übersicht

Diese Anleitung beschreibt die schrittweise Migration vom alten monolithischen Code zur neuen hexagonalen Architektur.

## Phase 1: Parallele Implementierung

1. Neue Struktur wurde bereits erstellt
2. Alte `app.py` bleibt unverändert
3. Neue Module unter `src/` werden parallel entwickelt

## Phase 2: Schrittweise Route-Migration

### Schritt 1: Device Routes migrieren

```python
# Alt (app.py)
@app.route('/devices')
def devices():
    conn = get_db_connection()
    # ... Logik ...

# Neu (src/adapters/web/routes/device_routes.py)
@device_bp.route('/')
def list_devices(self):
    devices = self.list_devices_uc.execute()
    # ... Response ...
```

### Schritt 2: Use Cases verwenden

```python
# Alt: Geschäftslogik in Route
# Neu: Geschäftslogik in Use Case
device = self.get_device_uc.execute(device_id)
```

## Phase 3: Datenbank-Adapter

Die MySQL-Implementierung befindet sich in:
- `src/adapters/persistence/mysql_device_repository.py`

Dies ermöglicht einfachen Wechsel zu anderen Datenbanken.

## Phase 4: Alte Struktur entfernen

Nach vollständiger Migration können gelöscht werden:
- Alte `app.py`
- Alte Hilfsfunktionen
- Alte Route-Implementierungen

## Rollback-Strategie

Falls Probleme auftreten:

1. Alte `app.py` ist noch vorhanden
2. Kann jederzeit als Fallback verwendet werden
3. Neue Struktur läuft parallel

## Testing während Migration

```bash
# Alte Tests
pytest tests/old/

# Neue Tests
pytest tests/unit/
pytest tests/integration/

# Beide
pytest
```

## Häufige Probleme

### Problem: Import-Fehler

```
ModuleNotFoundError: No module named 'src'
```

**Lösung**: Stelle sicher, dass `src/` im Python-Pfad ist:

```bash
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

### Problem: Datenbank-Verbindung

**Lösung**: Überprüfe `.env` Datei und Datenbank-Konfiguration

### Problem: Fehlende Dependencies

**Lösung**: Installiere alle Requirements:

```bash
pip install -r requirements_hexagon.txt
```

## Zeitplan

- **Woche 1**: Core & Use Cases implementieren
- **Woche 2**: Adapter implementieren
- **Woche 3**: Routes migrieren
- **Woche 4**: Testing & Dokumentation

## Support

Bei Fragen oder Problemen siehe:
- `README_HEXAGON.md` - Überblick
- `src/` - Quellcode mit Dokumentation
- `tests/` - Beispiel-Tests
EOF
    print_success "MIGRATION.md erstellt"
}

create_docker_files() {
    print_header "Erstelle Docker-Dateien"
    
    cat > "$PROJECT_PATH/Dockerfile" << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements_hexagon.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements_hexagon.txt

# Copy application
COPY src/ src/
COPY .env .

# Expose port
EXPOSE 5000

# Run application
CMD ["python", "src/main.py"]
EOF
    print_success "Dockerfile erstellt"
    
    cat > "$PROJECT_PATH/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: benning_device_manager
      MYSQL_USER: benning
      MYSQL_PASSWORD: benning
    ports:
      - "3307:3306"
    volumes:
      - mysql_data:/var/lib/mysql

  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      DB_HOST: mysql
      DB_PORT: 3306
      FLASK_ENV: development
    depends_on:
      - mysql
    volumes:
      - .:/app

volumes:
  mysql_data:
EOF
    print_success "docker-compose.yml erstellt"
}

# Hauptprogramm
main() {
    print_header "Benning Device Manager - Hexagonal Architecture Installer"
    
    print_info "Zielverzeichnis: $PROJECT_PATH"
    
    # Überprüfe, ob Verzeichnis existiert
    if [ ! -d "$PROJECT_PATH" ]; then
        print_error "Verzeichnis $PROJECT_PATH existiert nicht!"
        exit 1
    fi
    
    # Erstelle Struktur
    create_directory_structure
    create_core_domain_models
    create_core_ports
    create_core_usecases
    create_adapters
    create_config
    create_main_app
    create_tests
    create_requirements
    create_env_file
    create_readme
    create_migration_guide
    create_docker_files
    
    print_header "Installation abgeschlossen!"
    
    print_success "Hexagonale Architektur wurde erfolgreich erstellt!"
    print_info "Nächste Schritte:"
    echo "  1. cd $PROJECT_PATH"
    echo "  2. python3 -m venv venv"
    echo "  3. source venv/bin/activate"
    echo "  4. pip install -r requirements_hexagon.txt"
    echo "  5. cp .env.example .env"
    echo "  6. python src/main.py"
    echo ""
    print_info "Dokumentation:"
    echo "  - README_HEXAGON.md - Überblick"
    echo "  - MIGRATION.md - Migrationsanleitung"
    echo ""
}

# Starte Installation
main
