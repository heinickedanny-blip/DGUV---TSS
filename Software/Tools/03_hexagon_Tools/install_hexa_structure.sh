#!/bin/bash

################################################################################
# CachyOS - Hexagonal Architecture Complete Installer (NO PILLOW)
# All-in-One Installation für Benning Device Manager
# 
# Speziell für CachyOS ohne Pillow-Probleme!
#
# Verwendung: bash install_hexa_structure.sh [project_path]
# Beispiel:   bash install_hexa_structure.sh ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
################################################################################

set -e

# ═══════════════════════════════════════════════════════════════════════════
# KONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

PROJECT_PATH="${1:-.}"

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
    echo -e "\n${CYAN}▶ $1${NC}"
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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
# VORBEREITUNG
# ═══════════════════════════════════════════════════════════════════════════

print_header "🚀 CachyOS - Hexagonal Architecture Installer (NO PILLOW)"

if [ ! -d "$PROJECT_PATH" ]; then
    print_error "Verzeichnis $PROJECT_PATH existiert nicht!"
    exit 1
fi

cd "$PROJECT_PATH"

# Überprüfe Python
print_section "Überprüfe Umgebung"

PYTHON_CMD=""
for cmd in python3.14 python3.13 python3.12 python3.11 python3; do
    if command -v $cmd &> /dev/null; then
        PYTHON_VERSION=$($cmd --version 2>&1)
        print_success "Python: $PYTHON_VERSION"
        PYTHON_CMD=$cmd
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    print_error "Python 3 nicht gefunden!"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════
# BEREINIGUNG
# ═══════════════════════════════════════════════════════════════════════════

print_section "Bereinige alte Struktur"

if [ -d "venv" ]; then
    print_warning "Entferne alte venv..."
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate 2>/dev/null || true
    fi
    rm -rf venv
    print_success "Alte venv entfernt"
fi

# ═══════════════════════════════════════════════════════════════════════════
# VERZEICHNISSTRUKTUR
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Verzeichnisstruktur"

mkdir -p src/core/domain
mkdir -p src/core/usecases
mkdir -p src/core/ports
mkdir -p src/adapters/persistence
mkdir -p src/adapters/web/routes
mkdir -p src/adapters/web/dto
mkdir -p src/adapters/web/presenters
mkdir -p src/adapters/web/middleware
mkdir -p src/adapters/file_storage
mkdir -p src/adapters/qr_generation
mkdir -p src/config
mkdir -p tests/unit/domain
mkdir -p tests/unit/usecases
mkdir -p tests/unit/adapters
mkdir -p tests/integration/repositories
mkdir -p tests/integration/routes
mkdir -p tests/fixtures
mkdir -p static/uploads
mkdir -p database

print_success "Verzeichnisstruktur erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# DOMAIN MODELS
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Domain Models"

cat > src/core/domain/device.py << 'EOF'
"""Device Domain Model"""
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

cat > src/core/domain/inspection.py << 'EOF'
"""Inspection Domain Model"""
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

cat > src/core/domain/usbc_inspection.py << 'EOF'
"""USB-C Inspection Domain Model"""
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

touch src/core/domain/__init__.py
print_success "Domain Models erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# PORTS
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Ports (Abstraktion)"

cat > src/core/ports/device_repository.py << 'EOF'
"""Device Repository Port"""
from abc import ABC, abstractmethod
from typing import List, Optional
from src.core.domain.device import Device

class DeviceRepository(ABC):
    """Abstract Device Repository"""

    @abstractmethod
    def get_by_id(self, device_id: int) -> Optional[Device]:
        pass

    @abstractmethod
    def get_all(self) -> List[Device]:
        pass

    @abstractmethod
    def create(self, device: Device) -> Device:
        pass

    @abstractmethod
    def update(self, device: Device) -> Device:
        pass

    @abstractmethod
    def delete(self, device_id: int) -> bool:
        pass

    @abstractmethod
    def get_by_serial(self, serial_number: str) -> Optional[Device]:
        pass
EOF

cat > src/core/ports/file_storage.py << 'EOF'
"""File Storage Port"""
from abc import ABC, abstractmethod
from typing import Optional

class FileStorage(ABC):
    """Abstract File Storage"""

    @abstractmethod
    def save(self, filename: str, content: bytes) -> str:
        pass

    @abstractmethod
    def load(self, filename: str) -> Optional[bytes]:
        pass

    @abstractmethod
    def delete(self, filename: str) -> bool:
        pass

    @abstractmethod
    def exists(self, filename: str) -> bool:
        pass
EOF

cat > src/core/ports/qr_generator.py << 'EOF'
"""QR Generator Port"""
from abc import ABC, abstractmethod
from typing import Optional

class QRGenerator(ABC):
    """Abstract QR Generator"""

    @abstractmethod
    def generate(self, data: str) -> Optional[bytes]:
        pass

    @abstractmethod
    def generate_to_file(self, data: str, filename: str) -> bool:
        pass
EOF

touch src/core/ports/__init__.py
print_success "Ports erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# USE CASES
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Use Cases"

cat > src/core/usecases/device_usecases.py << 'EOF'
"""Device Use Cases"""
from typing import List, Optional
from src.core.domain.device import Device
from src.core.ports.device_repository import DeviceRepository

class GetDeviceUseCase:
    def __init__(self, repository: DeviceRepository):
        self.repository = repository
    def execute(self, device_id: int) -> Optional[Device]:
        return self.repository.get_by_id(device_id)

class ListDevicesUseCase:
    def __init__(self, repository: DeviceRepository):
        self.repository = repository
    def execute(self) -> List[Device]:
        return self.repository.get_all()

class CreateDeviceUseCase:
    def __init__(self, repository: DeviceRepository):
        self.repository = repository
    def execute(self, device: Device) -> Device:
        return self.repository.create(device)

class UpdateDeviceUseCase:
    def __init__(self, repository: DeviceRepository):
        self.repository = repository
    def execute(self, device: Device) -> Device:
        return self.repository.update(device)

class DeleteDeviceUseCase:
    def __init__(self, repository: DeviceRepository):
        self.repository = repository
    def execute(self, device_id: int) -> bool:
        return self.repository.delete(device_id)
EOF

touch src/core/usecases/__init__.py
print_success "Use Cases erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# ADAPTER - PERSISTENCE
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Persistence Adapter"

cat > src/adapters/persistence/mysql_device_repository.py << 'EOF'
"""MySQL Device Repository Adapter"""
from typing import List, Optional
import mysql.connector
from src.core.domain.device import Device
from src.core.ports.device_repository import DeviceRepository

class MySQLDeviceRepository(DeviceRepository):
    """MySQL Implementation of Device Repository"""

    def __init__(self, connection_config: dict):
        self.config = connection_config

    def _get_connection(self):
        return mysql.connector.connect(**self.config)

    def get_by_id(self, device_id: int) -> Optional[Device]:
        conn = self._get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM devices WHERE id = %s", (device_id,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        return self._map_to_device(result) if result else None

    def get_all(self) -> List[Device]:
        conn = self._get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM devices")
        results = cursor.fetchall()
        cursor.close()
        conn.close()
        return [self._map_to_device(row) for row in results]

    def create(self, device: Device) -> Device:
        conn = self._get_connection()
        cursor = conn.cursor()
        query = "INSERT INTO devices (name, device_type, serial_number, manufacturer, model, description) VALUES (%s, %s, %s, %s, %s, %s)"
        cursor.execute(query, (device.name, device.device_type, device.serial_number, device.manufacturer, device.model, device.description))
        device.id = cursor.lastrowid
        conn.commit()
        cursor.close()
        conn.close()
        return device

    def update(self, device: Device) -> Device:
        conn = self._get_connection()
        cursor = conn.cursor()
        query = "UPDATE devices SET name=%s, device_type=%s, serial_number=%s, manufacturer=%s, model=%s, description=%s WHERE id=%s"
        cursor.execute(query, (device.name, device.device_type, device.serial_number, device.manufacturer, device.model, device.description, device.id))
        conn.commit()
        cursor.close()
        conn.close()
        return device

    def delete(self, device_id: int) -> bool:
        conn = self._get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM devices WHERE id = %s", (device_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return True

    def get_by_serial(self, serial_number: str) -> Optional[Device]:
        conn = self._get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM devices WHERE serial_number = %s", (serial_number,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()
        return self._map_to_device(result) if result else None

    def _map_to_device(self, row: dict) -> Device:
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

touch src/adapters/persistence/__init__.py
print_success "Persistence Adapter erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# ADAPTER - WEB ROUTES
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Web Routes Adapter"

cat > src/adapters/web/routes/device_routes.py << 'EOF'
"""Device Routes Adapter"""
from flask import Blueprint, request, jsonify
from src.core.domain.device import Device
from src.core.usecases.device_usecases import (
    GetDeviceUseCase, ListDevicesUseCase, CreateDeviceUseCase,
    UpdateDeviceUseCase, DeleteDeviceUseCase
)

device_bp = Blueprint('devices', __name__, url_prefix='/api/devices')

@device_bp.route('', methods=['GET'])
def list_devices(list_usecase: ListDevicesUseCase):
    try:
        devices = list_usecase.execute()
        return jsonify([{'id': d.id, 'name': d.name, 'serial_number': d.serial_number, 'device_type': d.device_type} for d in devices])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('/<int:device_id>', methods=['GET'])
def get_device(device_id: int, get_usecase: GetDeviceUseCase):
    try:
        device = get_usecase.execute(device_id)
        if device:
            return jsonify({'id': device.id, 'name': device.name, 'serial_number': device.serial_number, 'device_type': device.device_type, 'manufacturer': device.manufacturer, 'model': device.model, 'description': device.description})
        return jsonify({'error': 'Device not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('', methods=['POST'])
def create_device(create_usecase: CreateDeviceUseCase):
    try:
        data = request.json
        device = Device(name=data.get('name'), device_type=data.get('device_type'), serial_number=data.get('serial_number'), manufacturer=data.get('manufacturer'), model=data.get('model'), description=data.get('description'))
        created = create_usecase.execute(device)
        return jsonify({'id': created.id, 'message': 'Device created'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('/<int:device_id>', methods=['PUT'])
def update_device(device_id: int, update_usecase: UpdateDeviceUseCase):
    try:
        data = request.json
        device = Device(id=device_id, name=data.get('name'), device_type=data.get('device_type'), serial_number=data.get('serial_number'), manufacturer=data.get('manufacturer'), model=data.get('model'), description=data.get('description'))
        update_usecase.execute(device)
        return jsonify({'message': 'Device updated'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('/<int:device_id>', methods=['DELETE'])
def delete_device(device_id: int, delete_usecase: DeleteDeviceUseCase):
    try:
        delete_usecase.execute(device_id)
        return jsonify({'message': 'Device deleted'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
EOF

touch src/adapters/web/routes/__init__.py
touch src/adapters/web/dto/__init__.py
touch src/adapters/web/presenters/__init__.py
touch src/adapters/web/middleware/__init__.py
touch src/adapters/file_storage/__init__.py
touch src/adapters/qr_generation/__init__.py
print_success "Web Routes erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# KONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Konfiguration"

cat > src/config/settings.py << 'EOF'
"""Application Settings"""
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    DEBUG = os.getenv('FLASK_DEBUG', False)
    DB_HOST = os.getenv('DB_HOST', 'localhost')
    DB_PORT = int(os.getenv('DB_PORT', 3306))
    DB_USER = os.getenv('DB_USER', 'benning')
    DB_PASSWORD = os.getenv('DB_PASSWORD', 'benning')
    DB_NAME = os.getenv('DB_NAME', 'benning_device_manager')
    UPLOAD_FOLDER = os.getenv('UPLOAD_FOLDER', 'static/uploads')
    MAX_CONTENT_LENGTH = int(os.getenv('MAX_CONTENT_LENGTH', 10485760))

class DevelopmentConfig(Config):
    DEBUG = True
    TESTING = False

class TestingConfig(Config):
    DEBUG = True
    TESTING = True
    DB_NAME = 'benning_device_manager_test'

class ProductionConfig(Config):
    DEBUG = False
    TESTING = False

def get_config():
    env = os.getenv('FLASK_ENV', 'development')
    if env == 'testing':
        return TestingConfig()
    elif env == 'production':
        return ProductionConfig()
    else:
        return DevelopmentConfig()
EOF

cat > src/config/dependencies.py << 'EOF'
"""Dependency Injection Container"""
from src.config.settings import get_config
from src.adapters.persistence.mysql_device_repository import MySQLDeviceRepository
from src.core.usecases.device_usecases import (
    GetDeviceUseCase, ListDevicesUseCase, CreateDeviceUseCase,
    UpdateDeviceUseCase, DeleteDeviceUseCase
)

class Container:
    def __init__(self):
        self.config = get_config()
        self._init_repositories()
        self._init_usecases()

    def _init_repositories(self):
        db_config = {
            'host': self.config.DB_HOST,
            'port': self.config.DB_PORT,
            'user': self.config.DB_USER,
            'password': self.config.DB_PASSWORD,
            'database': self.config.DB_NAME
        }
        self.device_repository = MySQLDeviceRepository(db_config)

    def _init_usecases(self):
        self.get_device_usecase = GetDeviceUseCase(self.device_repository)
        self.list_devices_usecase = ListDevicesUseCase(self.device_repository)
        self.create_device_usecase = CreateDeviceUseCase(self.device_repository)
        self.update_device_usecase = UpdateDeviceUseCase(self.device_repository)
        self.delete_device_usecase = DeleteDeviceUseCase(self.device_repository)

container = Container()
EOF

touch src/config/__init__.py
print_success "Konfiguration erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# HAUPTANWENDUNG
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Hauptanwendung"

cat > src/main.py << 'EOF'
"""Benning Device Manager - Hexagonal Architecture Edition"""
from flask import Flask
from src.config.settings import get_config
from src.config.dependencies import container
from src.adapters.web.routes.device_routes import device_bp

def create_app():
    app = Flask(__name__)
    config = get_config()
    app.config.from_object(config)
    app.register_blueprint(device_bp)

    @app.route('/health', methods=['GET'])
    def health():
        return {'status': 'ok'}, 200

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

touch src/__init__.py
print_success "Hauptanwendung erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# TESTS
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Tests"

cat > tests/unit/domain/test_device.py << 'EOF'
"""Device Model Tests"""
import pytest
from src.core.domain.device import Device

def test_device_creation():
    device = Device(name="Test Device", serial_number="SN123")
    assert device.name == "Test Device"
    assert device.serial_number == "SN123"
    assert device.created_at is not None

def test_device_update():
    device = Device(name="Old Name")
    device.update(name="New Name")
    assert device.name == "New Name"
    assert device.updated_at is not None

def test_device_repr():
    device = Device(id=1, name="Test", serial_number="SN123")
    assert "Device" in repr(device)
    assert "SN123" in repr(device)
EOF

touch tests/__init__.py
touch tests/unit/__init__.py
touch tests/unit/domain/__init__.py
touch tests/unit/usecases/__init__.py
touch tests/unit/adapters/__init__.py
touch tests/integration/__init__.py
touch tests/integration/repositories/__init__.py
touch tests/integration/routes/__init__.py
touch tests/fixtures/__init__.py
print_success "Tests erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# REQUIREMENTS (OHNE PILLOW!)
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Requirements (OHNE PILLOW)"

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

print_success "requirements_hexagon.txt erstellt (OHNE PILLOW)"

# ═══════════════════════════════════════════════════════════════════════════
# KONFIGURATIONSDATEIEN
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Konfigurationsdateien"

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

cat > pytest.ini << 'EOF'
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = -v --tb=short
EOF

print_success "Konfigurationsdateien erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# VIRTUAL ENVIRONMENT
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Virtual Environment"

bash -c "$PYTHON_CMD -m venv venv --system-site-packages --clear" 2>&1 | tail -3

if [ ! -f "venv/bin/python" ]; then
    print_error "Virtual Environment konnte nicht erstellt werden!"
    exit 1
fi

print_success "Virtual Environment erstellt"

VENV_PIP="$PROJECT_PATH/venv/bin/pip"
VENV_PYTHON="$PROJECT_PATH/venv/bin/python"

# ═══════════════════════════════════════════════════════════════════════════
# DEPENDENCIES INSTALLIEREN
# ═══════════════════════════════════════════════════════════════════════════

print_section "Installiere Dependencies"

bash -c "$VENV_PIP install --upgrade pip setuptools wheel --no-cache-dir --quiet" 2>&1 | tail -3
print_success "pip aktualisiert"

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
# ÜBERPRÜFUNG
# ═══════════════════════════════════════════════════════════════════════════

print_section "Überprüfe Installation"

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

# ═══════════════════════════════════════════════════════════════════════════
# AKTIVIERUNGSSKRIPTE
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Aktivierungsskripte"

cat > activate_cachyos.sh << 'ACTIVATE'
#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Virtual Environment nicht gefunden: $VENV_DIR"
    exit 1
fi

export CFLAGS="-march=native -O3"
export CXXFLAGS="-march=native -O3"
export LDFLAGS="-march=native -O3"
export PYTHONOPTIMIZE=2
export PIP_NO_CACHE_DIR=1

source "$VENV_DIR/bin/activate"

echo "✓ CachyOS Virtual Environment aktiviert"
echo "  Python: $(which python)"
echo "  Optimierungen: Native CPU (-march=native -O3)"
ACTIVATE

chmod +x activate_cachyos.sh
print_success "activate_cachyos.sh erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# DOKUMENTATION
# ═══════════════════════════════════════════════════════════════════════════

print_section "Erstelle Dokumentation"

cat > README_HEXAGON.md << 'EOF'
# Benning Device Manager - Hexagonal Architecture Edition

## 🏗️ Architektur

```
Web Layer (Flask)
       ↓
Ports (Abstraktion)
       ↓
Core (Geschäftslogik)
       ↓
Adapters (Implementierung)
```

## 📁 Verzeichnisstruktur

```
src/
├── core/              # Geschäftslogik
│   ├── domain/        # Domain Models
│   ├── usecases/      # Use Cases
│   └── ports/         # Abstraktion
├── adapters/          # Implementierungen
│   ├── persistence/   # Datenbank
│   └── web/           # Web-Framework
└── config/            # Konfiguration
```

## 🚀 Schnellstart

```bash
# 1. Aktiviere venv
source activate_cachyos.sh

# 2. Konfiguriere .env
cp .env.example .env
nano .env

# 3. Starte Anwendung
python src/main.py

# 4. Öffne Browser
# http://localhost:5000
```

## 📝 Befehle

```bash
pytest                  # Tests
black src/             # Formatieren
flake8 src/            # Linting
```
EOF

print_success "README_HEXAGON.md erstellt"

# ═══════════════════════════════════════════════════════════════════════════
# ABSCHLUSS
# ═══════════════════════════════════════════════════════════════════════════

print_header "✨ Installation erfolgreich abgeschlossen!"

echo -e "${CYAN}📊 Übersicht:${NC}"
echo "  Projektpfad:     $PROJECT_PATH"
echo "  Python:          $($VENV_PYTHON --version 2>&1)"
echo "  venv:            $PROJECT_PATH/venv"
echo "  CachyOS:         ✓ Optimiert"
echo "  Pillow:          ✗ Nicht installiert (nicht nötig)"
echo ""

echo -e "${CYAN}🚀 Nächste Schritte:${NC}\n"

echo "  1. Aktiviere venv:"
echo "     ${YELLOW}source activate_cachyos.sh${NC}"
echo ""

echo "  2. Konfiguriere .env:"
echo "     ${YELLOW}cp .env.example .env${NC}"
echo "     ${YELLOW}nano .env${NC}"
echo ""

echo "  3. Starte Anwendung:"
echo "     ${YELLOW}python src/main.py${NC}"
echo ""

echo "  4. Öffne Browser:"
echo "     ${YELLOW}http://localhost:5000${NC}"
echo ""

echo -e "${GREEN}Viel Erfolg! 🎉${NC}\n"
