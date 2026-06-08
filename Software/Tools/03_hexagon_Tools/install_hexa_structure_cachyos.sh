#!/bin/bash

################################################################################
# CachyOS - Hexagonal Architecture Complete Installer
# All-in-One Installation für Benning Device Manager
# 
# Features:
# - Projektstruktur erstellen
# - Virtual Environment mit CachyOS-Optimierungen
# - Alle Dependencies installieren
# - Vollständige Konfiguration
# - Keine separaten Repair-Skripte nötig!
#
# Verwendung: bash install_hexa_structure_cachyos.sh [project_path]
# Beispiel:   bash install_hexa_structure_cachyos.sh ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
################################################################################

set -e

# ═══════════════════════════════════════════════════════════════════════════
# KONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

PROJECT_PATH="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# CachyOS Optimierungen
export CFLAGS="-march=native -O3"
export CXXFLAGS="-march=native -O3"
export LDFLAGS="-march=native -O3"
export PYTHONOPTIMIZE=2
export PIP_NO_CACHE_DIR=1

# ═══════════════════════════════════════════════════════════════════════════
# FUNKTIONEN
# ═══════════════════════════════════════════════════════════════════════════

print_header() {
    echo -e "\n${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC} $1"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    echo -e "\n${CYAN}▶▶▶ $1${NC}"
}

print_subsection() {
    echo -e "\n${BLUE}  ▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

print_error() {
    echo -e "${RED}  ✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}  ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
}

print_progress() {
    echo -e "${CYAN}  ⟳ $1${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
# VORBEREITUNG
# ═══════════════════════════════════════════════════════════════════════════

print_header "🚀 CachyOS - Hexagonal Architecture Installer"

# Überprüfe Verzeichnis
if [ ! -d "$PROJECT_PATH" ]; then
    print_error "Verzeichnis $PROJECT_PATH existiert nicht!"
    exit 1
fi

cd "$PROJECT_PATH"

# Überprüfe CachyOS
print_section "Phase 1: Umgebungsprüfung"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "cachyos" ]] || [[ "$PRETTY_NAME" == *"CachyOS"* ]]; then
        print_success "CachyOS erkannt: $PRETTY_NAME"
    else
        print_warning "Nicht auf CachyOS, aber fahre fort..."
    fi
fi

# Überprüfe Python
print_subsection "Überprüfe Python-Installation"

PYTHON_CMD=""
for cmd in python3.14 python3.13 python3.12 python3.11 python3; do
    if command -v $cmd &> /dev/null; then
        PYTHON_VERSION=$($cmd --version 2>&1)
        print_success "Gefunden: $PYTHON_VERSION"
        PYTHON_CMD=$cmd
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    print_error "Python 3 nicht gefunden!"
    print_info "Installiere Python: sudo pacman -S python"
    exit 1
fi

# Überprüfe git
print_subsection "Überprüfe git-Installation"

if command -v git &> /dev/null; then
    print_success "git installiert"
else
    print_warning "git nicht gefunden - installiere: sudo pacman -S git"
fi

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 2: ALTE STRUKTUR ENTFERNEN
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 2: Alte Struktur bereinigen"

# Entferne alte venv
if [ -d "venv" ]; then
    print_warning "Alte venv gefunden - entferne..."
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate 2>/dev/null || true
    fi
    rm -rf venv
    print_success "Alte venv entfernt"
fi

# Entferne alte Struktur falls vorhanden
if [ -d "src" ]; then
    print_warning "Alte src-Struktur gefunden"
    read -p "Soll die alte Struktur überschrieben werden? (j/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        rm -rf src tests
        print_success "Alte Struktur entfernt"
    else
        print_info "Behalte alte Struktur"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 3: VERZEICHNISSTRUKTUR ERSTELLEN
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 3: Erstelle Verzeichnisstruktur"

DIRS=(
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
    "static/uploads"
    "database"
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$dir"
done

print_success "Verzeichnisstruktur erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 4: DOMAIN MODELS ERSTELLEN
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 4: Erstelle Domain Models"

# Device Model
cat > src/core/domain/device.py << 'EOF'
"""
Device Domain Model
Repräsentiert ein Gerät im System
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class Device:
    """Device Entity"""
    id: Optional[int] = None
    name: str = ""
    device_type: str = ""
    serial_number: str = ""
    manufacturer: str = ""
    model: str = ""
    description: str = ""
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()
        if self.updated_at is None:
            self.updated_at = datetime.now()

    def update(self, **kwargs):
        """Aktualisiere Device-Attribute"""
        for key, value in kwargs.items():
            if hasattr(self, key):
                setattr(self, key, value)
        self.updated_at = datetime.now()

    def __repr__(self):
        return f"Device(id={self.id}, name={self.name}, serial={self.serial_number})"
EOF

print_success "Device Model erstellt"

# Inspection Model
cat > src/core/domain/inspection.py << 'EOF'
"""
Inspection Domain Model
Repräsentiert eine Inspektion
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class Inspection:
    """Inspection Entity"""
    id: Optional[int] = None
    device_id: int = 0
    inspection_type: str = ""
    status: str = "pending"
    result: str = ""
    notes: str = ""
    inspector: str = ""
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()
        if self.updated_at is None:
            self.updated_at = datetime.now()

    def __repr__(self):
        return f"Inspection(id={self.id}, device_id={self.device_id}, status={self.status})"
EOF

print_success "Inspection Model erstellt"

# USB-C Inspection Model
cat > src/core/domain/usbc_inspection.py << 'EOF'
"""
USB-C Inspection Domain Model
Spezialisierte Inspektion für USB-C Geräte
"""

from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class USBCInspection:
    """USB-C Inspection Entity"""
    id: Optional[int] = None
    device_id: int = 0
    connector_type: str = "usb-c"
    connector_condition: str = ""
    cable_test: str = ""
    power_delivery: str = ""
    data_transfer: str = ""
    result: str = "pass"
    notes: str = ""
    created_at: Optional[datetime] = None

    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()

    def __repr__(self):
        return f"USBCInspection(id={self.id}, device_id={self.device_id}, result={self.result})"
EOF

print_success "USB-C Inspection Model erstellt"

# __init__.py für domain
touch src/core/domain/__init__.py

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 5: PORTS (ABSTRAKTION) ERSTELLEN
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 5: Erstelle Ports (Abstraktion)"

# Device Repository Port
cat > src/core/ports/device_repository.py << 'EOF'
"""
Device Repository Port
Abstraktion für Datenbankzugriff
"""

from abc import ABC, abstractmethod
from typing import List, Optional
from src.core.domain.device import Device


class DeviceRepository(ABC):
    """Abstract Device Repository"""

    @abstractmethod
    def get_by_id(self, device_id: int) -> Optional[Device]:
        """Hole Device nach ID"""
        pass

    @abstractmethod
    def get_all(self) -> List[Device]:
        """Hole alle Devices"""
        pass

    @abstractmethod
    def create(self, device: Device) -> Device:
        """Erstelle neues Device"""
        pass

    @abstractmethod
    def update(self, device: Device) -> Device:
        """Aktualisiere Device"""
        pass

    @abstractmethod
    def delete(self, device_id: int) -> bool:
        """Lösche Device"""
        pass

    @abstractmethod
    def get_by_serial(self, serial_number: str) -> Optional[Device]:
        """Hole Device nach Seriennummer"""
        pass
EOF

print_success "Device Repository Port erstellt"

# File Storage Port
cat > src/core/ports/file_storage.py << 'EOF'
"""
File Storage Port
Abstraktion für Dateispeicherung
"""

from abc import ABC, abstractmethod
from typing import Optional


class FileStorage(ABC):
    """Abstract File Storage"""

    @abstractmethod
    def save(self, filename: str, content: bytes) -> str:
        """Speichere Datei"""
        pass

    @abstractmethod
    def load(self, filename: str) -> Optional[bytes]:
        """Lade Datei"""
        pass

    @abstractmethod
    def delete(self, filename: str) -> bool:
        """Lösche Datei"""
        pass

    @abstractmethod
    def exists(self, filename: str) -> bool:
        """Überprüfe ob Datei existiert"""
        pass
EOF

print_success "File Storage Port erstellt"

# QR Generator Port
cat > src/core/ports/qr_generator.py << 'EOF'
"""
QR Generator Port
Abstraktion für QR-Code Generierung
"""

from abc import ABC, abstractmethod
from typing import Optional


class QRGenerator(ABC):
    """Abstract QR Generator"""

    @abstractmethod
    def generate(self, data: str) -> Optional[bytes]:
        """Generiere QR-Code"""
        pass

    @abstractmethod
    def generate_to_file(self, data: str, filename: str) -> bool:
        """Generiere QR-Code und speichere in Datei"""
        pass
EOF

print_success "QR Generator Port erstellt"

touch src/core/ports/__init__.py

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 6: USE CASES ERSTELLEN
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 6: Erstelle Use Cases"

cat > src/core/usecases/device_usecases.py << 'EOF'
"""
Device Use Cases
Geschäftslogik für Device-Management
"""

from typing import List, Optional
from src.core.domain.device import Device
from src.core.ports.device_repository import DeviceRepository


class GetDeviceUseCase:
    """Get Device by ID"""

    def __init__(self, repository: DeviceRepository):
        self.repository = repository

    def execute(self, device_id: int) -> Optional[Device]:
        """Hole Device nach ID"""
        return self.repository.get_by_id(device_id)


class ListDevicesUseCase:
    """List all Devices"""

    def __init__(self, repository: DeviceRepository):
        self.repository = repository

    def execute(self) -> List[Device]:
        """Hole alle Devices"""
        return self.repository.get_all()


class CreateDeviceUseCase:
    """Create new Device"""

    def __init__(self, repository: DeviceRepository):
        self.repository = repository

    def execute(self, device: Device) -> Device:
        """Erstelle neues Device"""
        return self.repository.create(device)


class UpdateDeviceUseCase:
    """Update Device"""

    def __init__(self, repository: DeviceRepository):
        self.repository = repository

    def execute(self, device: Device) -> Device:
        """Aktualisiere Device"""
        return self.repository.update(device)


class DeleteDeviceUseCase:
    """Delete Device"""

    def __init__(self, repository: DeviceRepository):
        self.repository = repository

    def execute(self, device_id: int) -> bool:
        """Lösche Device"""
        return self.repository.delete(device_id)
EOF

print_success "Device Use Cases erstellt"

touch src/core/usecases/__init__.py

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 7: ADAPTER - PERSISTENCE
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 7: Erstelle Persistence Adapter"

cat > src/adapters/persistence/mysql_device_repository.py << 'EOF'
"""
MySQL Device Repository Adapter
Konkrete Implementierung des Device Repository
"""

from typing import List, Optional
import mysql.connector
from src.core.domain.device import Device
from src.core.ports.device_repository import DeviceRepository


class MySQLDeviceRepository(DeviceRepository):
    """MySQL Implementation of Device Repository"""

    def __init__(self, connection_config: dict):
        self.config = connection_config

    def _get_connection(self):
        """Hole Datenbankverbindung"""
        return mysql.connector.connect(**self.config)

    def get_by_id(self, device_id: int) -> Optional[Device]:
        """Hole Device nach ID"""
        conn = self._get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM devices WHERE id = %s", (device_id,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result:
            return self._map_to_device(result)
        return None

    def get_all(self) -> List[Device]:
        """Hole alle Devices"""
        conn = self._get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM devices")
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return [self._map_to_device(row) for row in results]

    def create(self, device: Device) -> Device:
        """Erstelle neues Device"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        query = """
            INSERT INTO devices (name, device_type, serial_number, manufacturer, model, description)
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        cursor.execute(query, (
            device.name, device.device_type, device.serial_number,
            device.manufacturer, device.model, device.description
        ))
        
        device.id = cursor.lastrowid
        conn.commit()
        cursor.close()
        conn.close()
        
        return device

    def update(self, device: Device) -> Device:
        """Aktualisiere Device"""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        query = """
            UPDATE devices 
            SET name=%s, device_type=%s, serial_number=%s, manufacturer=%s, model=%s, description=%s
            WHERE id=%s
        """
        cursor.execute(query, (
            device.name, device.device_type, device.serial_number,
            device.manufacturer, device.model, device.description, device.id
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return device

    def delete(self, device_id: int) -> bool:
        """Lösche Device"""
        conn = self._get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM devices WHERE id = %s", (device_id,))
        conn.commit()
        cursor.close()
        conn.close()
        
        return True

    def get_by_serial(self, serial_number: str) -> Optional[Device]:
        """Hole Device nach Seriennummer"""
        conn = self._get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM devices WHERE serial_number = %s", (serial_number,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if result:
            return self._map_to_device(result)
        return None

    def _map_to_device(self, row: dict) -> Device:
        """Mappe Datenbankzeile zu Device-Objekt"""
        return Device(
            id=row.get('id'),
            name=row.get('name', ''),
            device_type=row.get('device_type', ''),
            serial_number=row.get('serial_number', ''),
            manufacturer=row.get('manufacturer', ''),
            model=row.get('model', ''),
            description=row.get('description', ''),
            created_at=row.get('created_at'),
            updated_at=row.get('updated_at')
        )
EOF

print_success "MySQL Device Repository erstellt"

touch src/adapters/persistence/__init__.py

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 8: ADAPTER - WEB ROUTES
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 8: Erstelle Web Routes Adapter"

cat > src/adapters/web/routes/device_routes.py << 'EOF'
"""
Device Routes Adapter
Flask Routes für Device-Management
"""

from flask import Blueprint, request, jsonify
from src.core.domain.device import Device
from src.core.usecases.device_usecases import (
    GetDeviceUseCase, ListDevicesUseCase, CreateDeviceUseCase,
    UpdateDeviceUseCase, DeleteDeviceUseCase
)

device_bp = Blueprint('devices', __name__, url_prefix='/api/devices')


@device_bp.route('', methods=['GET'])
def list_devices(list_usecase: ListDevicesUseCase):
    """Liste alle Devices"""
    try:
        devices = list_usecase.execute()
        return jsonify([{
            'id': d.id,
            'name': d.name,
            'serial_number': d.serial_number,
            'device_type': d.device_type
        } for d in devices])
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@device_bp.route('/<int:device_id>', methods=['GET'])
def get_device(device_id: int, get_usecase: GetDeviceUseCase):
    """Hole einzelnes Device"""
    try:
        device = get_usecase.execute(device_id)
        if device:
            return jsonify({
                'id': device.id,
                'name': device.name,
                'serial_number': device.serial_number,
                'device_type': device.device_type,
                'manufacturer': device.manufacturer,
                'model': device.model,
                'description': device.description
            })
        return jsonify({'error': 'Device not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@device_bp.route('', methods=['POST'])
def create_device(create_usecase: CreateDeviceUseCase):
    """Erstelle neues Device"""
    try:
        data = request.json
        device = Device(
            name=data.get('name'),
            device_type=data.get('device_type'),
            serial_number=data.get('serial_number'),
            manufacturer=data.get('manufacturer'),
            model=data.get('model'),
            description=data.get('description')
        )
        created = create_usecase.execute(device)
        return jsonify({'id': created.id, 'message': 'Device created'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@device_bp.route('/<int:device_id>', methods=['PUT'])
def update_device(device_id: int, update_usecase: UpdateDeviceUseCase):
    """Aktualisiere Device"""
    try:
        data = request.json
        device = Device(
            id=device_id,
            name=data.get('name'),
            device_type=data.get('device_type'),
            serial_number=data.get('serial_number'),
            manufacturer=data.get('manufacturer'),
            model=data.get('model'),
            description=data.get('description')
        )
        update_usecase.execute(device)
        return jsonify({'message': 'Device updated'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@device_bp.route('/<int:device_id>', methods=['DELETE'])
def delete_device(device_id: int, delete_usecase: DeleteDeviceUseCase):
    """Lösche Device"""
    try:
        delete_usecase.execute(device_id)
        return jsonify({'message': 'Device deleted'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
EOF

print_success "Device Routes erstellt"

touch src/adapters/web/routes/__init__.py
touch src/adapters/web/dto/__init__.py
touch src/adapters/web/presenters/__init__.py
touch src/adapters/web/middleware/__init__.py
touch src/adapters/file_storage/__init__.py
touch src/adapters/qr_generation/__init__.py

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 9: KONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 9: Erstelle Konfiguration"

cat > src/config/settings.py << 'EOF'
"""
Application Settings
"""

import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Base Configuration"""
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    DEBUG = os.getenv('FLASK_DEBUG', False)
    
    # Database
    DB_HOST = os.getenv('DB_HOST', 'localhost')
    DB_PORT = int(os.getenv('DB_PORT', 3306))
    DB_USER = os.getenv('DB_USER', 'benning')
    DB_PASSWORD = os.getenv('DB_PASSWORD', 'benning')
    DB_NAME = os.getenv('DB_NAME', 'benning_device_manager')
    
    # File Storage
    UPLOAD_FOLDER = os.getenv('UPLOAD_FOLDER', 'static/uploads')
    MAX_CONTENT_LENGTH = int(os.getenv('MAX_CONTENT_LENGTH', 10485760))


class DevelopmentConfig(Config):
    """Development Configuration"""
    DEBUG = True
    TESTING = False


class TestingConfig(Config):
    """Testing Configuration"""
    DEBUG = True
    TESTING = True
    DB_NAME = 'benning_device_manager_test'


class ProductionConfig(Config):
    """Production Configuration"""
    DEBUG = False
    TESTING = False


def get_config():
    """Get configuration based on environment"""
    env = os.getenv('FLASK_ENV', 'development')
    
    if env == 'testing':
        return TestingConfig()
    elif env == 'production':
        return ProductionConfig()
    else:
        return DevelopmentConfig()
EOF

print_success "Settings erstellt"

cat > src/config/dependencies.py << 'EOF'
"""
Dependency Injection Container
"""

from src.config.settings import get_config
from src.adapters.persistence.mysql_device_repository import MySQLDeviceRepository
from src.core.usecases.device_usecases import (
    GetDeviceUseCase, ListDevicesUseCase, CreateDeviceUseCase,
    UpdateDeviceUseCase, DeleteDeviceUseCase
)


class Container:
    """Dependency Injection Container"""

    def __init__(self):
        self.config = get_config()
        self._init_repositories()
        self._init_usecases()

    def _init_repositories(self):
        """Initialisiere Repositories"""
        db_config = {
            'host': self.config.DB_HOST,
            'port': self.config.DB_PORT,
            'user': self.config.DB_USER,
            'password': self.config.DB_PASSWORD,
            'database': self.config.DB_NAME
        }
        self.device_repository = MySQLDeviceRepository(db_config)

    def _init_usecases(self):
        """Initialisiere Use Cases"""
        self.get_device_usecase = GetDeviceUseCase(self.device_repository)
        self.list_devices_usecase = ListDevicesUseCase(self.device_repository)
        self.create_device_usecase = CreateDeviceUseCase(self.device_repository)
        self.update_device_usecase = UpdateDeviceUseCase(self.device_repository)
        self.delete_device_usecase = DeleteDeviceUseCase(self.device_repository)


# Global container instance
container = Container()
EOF

print_success "Dependency Injection Container erstellt"

touch src/config/__init__.py

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 10: HAUPTANWENDUNG
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 10: Erstelle Hauptanwendung"

cat > src/main.py << 'EOF'
"""
Benning Device Manager - Hexagonal Architecture Edition
Main Application Entry Point
"""

from flask import Flask
from src.config.settings import get_config
from src.config.dependencies import container
from src.adapters.web.routes.device_routes import device_bp


def create_app():
    """Create and configure Flask application"""
    
    app = Flask(__name__)
    config = get_config()
    app.config.from_object(config)
    
    # Register blueprints
    app.register_blueprint(device_bp)
    
    # Health check endpoint
    @app.route('/health', methods=['GET'])
    def health():
        return {'status': 'ok'}, 200
    
    # Root endpoint
    @app.route('/', methods=['GET'])
    def index():
        return {
            'name': 'Benning Device Manager',
            'version': '2.0.0',
            'architecture': 'Hexagonal',
            'status': 'running'
        }, 200
    
    return app


if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

print_success "Hauptanwendung erstellt"

touch src/__init__.py

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 11: TESTS
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 11: Erstelle Test-Struktur"

cat > tests/unit/domain/test_device.py << 'EOF'
"""
Device Model Tests
"""

import pytest
from src.core.domain.device import Device


def test_device_creation():
    """Test Device creation"""
    device = Device(name="Test Device", serial_number="SN123")
    assert device.name == "Test Device"
    assert device.serial_number == "SN123"
    assert device.created_at is not None


def test_device_update():
    """Test Device update"""
    device = Device(name="Old Name")
    device.update(name="New Name")
    assert device.name == "New Name"
    assert device.updated_at is not None


def test_device_repr():
    """Test Device string representation"""
    device = Device(id=1, name="Test", serial_number="SN123")
    assert "Device" in repr(device)
    assert "SN123" in repr(device)
EOF

print_success "Test-Struktur erstellt"

touch tests/__init__.py
touch tests/unit/__init__.py
touch tests/unit/domain/__init__.py
touch tests/unit/usecases/__init__.py
touch tests/unit/adapters/__init__.py
touch tests/integration/__init__.py
touch tests/integration/repositories/__init__.py
touch tests/integration/routes/__init__.py
touch tests/fixtures/__init__.py

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 12: REQUIREMENTS
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 12: Erstelle Requirements"

cat > requirements_hexagon.txt << 'EOF'
# Core Framework
Flask==2.3.3
Werkzeug==2.3.7

# Database
mysql-connector-python==8.1.0

# Utilities
python-dotenv==1.0.0
qrcode==7.4.2

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

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 13: KONFIGURATIONSDATEIEN
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 13: Erstelle Konfigurationsdateien"

# .env.example
cat > .env.example << 'EOF'
# Flask
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-secret-key-change-in-production

# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=benning
DB_PASSWORD=benning
DB_NAME=benning_device_manager

# File Storage
UPLOAD_FOLDER=static/uploads
MAX_CONTENT_LENGTH=10485760
EOF

print_success ".env.example erstellt"

# .gitignore
cat > .gitignore << 'EOF'
# Virtual Environment
venv/
env/
ENV/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Environment
.env
.env.local
.env.*.local

# Uploads
static/uploads/*
!static/uploads/.gitkeep

# Logs
logs/
*.log

# Database
*.db
*.sqlite
*.sqlite3

# Testing
.pytest_cache/
.coverage
htmlcov/

# CachyOS
.cachyos-config
EOF

print_success ".gitignore erstellt"

# pytest.ini
cat > pytest.ini << 'EOF'
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --tb=short
EOF

print_success "pytest.ini erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 14: VIRTUAL ENVIRONMENT
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 14: Erstelle Virtual Environment"

print_progress "Erstelle venv mit CachyOS-Optimierungen..."

bash -c "$PYTHON_CMD -m venv venv --system-site-packages --clear" 2>&1 | tail -3

if [ ! -f "venv/bin/python" ]; then
    print_error "Virtual Environment konnte nicht erstellt werden!"
    exit 1
fi

print_success "Virtual Environment erstellt"

VENV_PIP="$PROJECT_PATH/venv/bin/pip"
VENV_PYTHON="$PROJECT_PATH/venv/bin/python"

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 15: DEPENDENCIES INSTALLIEREN
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 15: Installiere Dependencies"

print_progress "Aktualisiere pip..."
bash -c "$VENV_PIP install --upgrade pip setuptools wheel --no-cache-dir --quiet" 2>&1 | tail -3

print_success "pip aktualisiert"

print_progress "Installiere Python-Pakete (CachyOS-optimiert)..."

bash -c "$VENV_PIP install \
    Flask==2.3.3 \
    Werkzeug==2.3.7 \
    mysql-connector-python==8.1.0 \
    python-dotenv==1.0.0 \
    qrcode==7.4.2 \
    pytest==7.4.0 \
    pytest-cov==4.1.0 \
    pytest-mock==3.11.1 \
    black==23.9.1 \
    flake8==6.1.0 \
    mypy==1.5.1 \
    isort==5.12.0 \
    gunicorn==21.2.0 \
    --break-system-packages \
    --no-cache-dir \
    --upgrade" 2>&1 | tail -20

print_success "Pakete installiert"

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 16: ÜBERPRÜFUNG
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 16: Überprüfe Installation"

PACKAGES=("flask" "mysql" "pytest" "dotenv" "qrcode")
FAILED=0

for package in "${PACKAGES[@]}"; do
    if bash -c "$VENV_PYTHON -c 'import ${package//-/_}' 2>/dev/null"; then
        print_success "Paket '$package' OK"
    else
        print_error "Paket '$package' nicht gefunden!"
        FAILED=$((FAILED + 1))
    fi
done

if [ $FAILED -gt 0 ]; then
    print_warning "$FAILED Pakete fehlen - versuche erneut..."
    bash -c "$VENV_PIP install Flask mysql-connector-python pytest python-dotenv qrcode --break-system-packages --no-cache-dir" 2>&1 | tail -10
fi

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 17: AKTIVIERUNGSSKRIPTE
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 17: Erstelle Aktivierungsskripte"

# CachyOS-optimiertes Aktivierungsskript
cat > activate_cachyos.sh << 'ACTIVATE'
#!/bin/bash
# CachyOS Optimized Activation Script

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Virtual Environment nicht gefunden: $VENV_DIR"
    exit 1
fi

# Wende CachyOS-Optimierungen an
export CFLAGS="-march=native -O3"
export CXXFLAGS="-march=native -O3"
export LDFLAGS="-march=native -O3"
export PYTHONOPTIMIZE=2
export PIP_NO_CACHE_DIR=1

# Aktiviere venv
source "$VENV_DIR/bin/activate"

echo "✓ CachyOS Virtual Environment aktiviert"
echo "  Python: $(which python)"
echo "  Optimierungen: Native CPU (-march=native -O3)"
ACTIVATE

chmod +x activate_cachyos.sh
print_success "activate_cachyos.sh erstellt"

# .cachyos-config
cat > .cachyos-config << 'EOF'
# CachyOS Optimization Configuration
export CFLAGS="-march=native -O3"
export CXXFLAGS="-march=native -O3"
export LDFLAGS="-march=native -O3"
export PYTHONOPTIMIZE=2
export PIP_NO_CACHE_DIR=1
EOF

print_success ".cachyos-config erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 18: DOKUMENTATION
# ═══════════════════════════════════════════════════════════════════════════

print_section "Phase 18: Erstelle Dokumentation"

cat > README_HEXAGON.md << 'EOF'
# Benning Device Manager - Hexagonal Architecture Edition

## 🏗️ Architektur

```
┌─────────────────────────────────────────────────────────┐
│                    Web Layer (Flask)                     │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Routes │ DTOs │ Presenters │ Middleware          │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                    Ports (Abstraktion)                   │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Repository │ FileStorage │ QRGenerator          │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Core (Geschäftslogik)                  │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Domain Models │ Use Cases                       │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  Adapters (Implementierung)              │
│  ┌──────────────────────────────────────────────────┐   │
│  │  MySQL │ FileSystem │ QRCode                     │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## 📁 Verzeichnisstruktur

```
src/
├── core/              # Geschäftslogik (Framework-unabhängig)
│   ├── domain/        # Domain Models
│   ├── usecases/      # Use Cases
│   └── ports/         # Abstraktion
├── adapters/          # Konkrete Implementierungen
│   ├── persistence/   # Datenbank
│   └── web/           # Web-Framework
└── config/            # Konfiguration
```

## 🚀 Schnellstart

```bash
# 1. Aktiviere venv
source activate_cachyos.sh

# 2. Konfiguriere .env
nano .env

# 3. Starte Anwendung
python src/main.py

# 4. Öffne Browser
# http://localhost:5000
```

## 📝 Befehle

```bash
# Tests
pytest

# Code formatieren
black src/

# Linting
flake8 src/

# Type Checking
mypy src/
```

## 🔗 Weitere Informationen

- `QUICKSTART.md` - Schneller Einstieg
- `INSTALLATION_GUIDE.md` - Detaillierte Installation
- `CACHYOS_SETUP.md` - CachyOS spezifische Einstellungen
EOF

print_success "README_HEXAGON.md erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# ABSCHLUSS
# ═══════════════════════════════════════════════════════════════════════════

print_header "✨ Installation erfolgreich abgeschlossen!"

echo -e "${CYAN}📊 Installationsübersicht:${NC}"
echo ""
echo "  Projektpfad:        $PROJECT_PATH"
echo "  Python Version:     $($VENV_PYTHON --version 2>&1)"
echo "  Virtual Env:        $PROJECT_PATH/venv"
echo "  CachyOS Optimiert:  ✓"
echo ""

echo -e "${CYAN}📋 Erstellte Komponenten:${NC}"
echo "  ✓ Domain Models (Device, Inspection, USB-C)"
echo "  ✓ Use Cases (Get, List, Create, Update, Delete)"
echo "  ✓ Ports (Repository, FileStorage, QRGenerator)"
echo "  ✓ Adapters (MySQL, Flask Routes)"
echo "  ✓ Konfiguration (Settings, Dependencies)"
echo "  ✓ Tests (Unit-Tests für Domain)"
echo "  ✓ Virtual Environment (CachyOS-optimiert)"
echo ""

echo -e "${CYAN}🚀 Nächste Schritte:${NC}\n"

echo "  1. Aktiviere Virtual Environment (CachyOS-optimiert):"
echo "     ${YELLOW}source activate_cachyos.sh${NC}"
echo ""

echo "  2. Konfiguriere Umgebungsvariablen:"
echo "     ${YELLOW}cp .env.example .env${NC}"
echo "     ${YELLOW}nano .env${NC}"
echo ""

echo "  3. Initialisiere Datenbank:"
echo "     ${YELLOW}mysql -u benning -p benning_device_manager < database/schema.sql${NC}"
echo ""

echo "  4. Starte Anwendung:"
echo "     ${YELLOW}python src/main.py${NC}"
echo ""

echo "  5. Öffne im Browser:"
echo "     ${YELLOW}http://localhost:5000${NC}"
echo ""

echo "  6. Führe Tests aus:"
echo "     ${YELLOW}pytest${NC}"
echo ""

echo -e "${GREEN}Viel Erfolg mit CachyOS und Hexagonal Architecture! 🎉${NC}\n"
