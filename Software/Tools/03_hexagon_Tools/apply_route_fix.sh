#!/bin/bash

################################################################################
# Apply Route Fix - Behebt Dependency Injection Problem direkt
#
# Verwendung: bash apply_route_fix.sh
################################################################################

set -e

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} $1"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_header "🔧 Apply Route Fix - Dependency Injection"

# Überprüfe ob wir im richtigen Verzeichnis sind
if [ ! -d "src/adapters/web/routes" ]; then
    echo "❌ src/adapters/web/routes nicht gefunden!"
    echo "Stelle sicher, dass du im Projektverzeichnis bist:"
    echo "  cd ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG"
    exit 1
fi

print_success "Projektverzeichnis gefunden"

# Erstelle korrigierte device_routes.py direkt
print_info "Erstelle korrigierte device_routes.py..."

cat > src/adapters/web/routes/device_routes.py << 'EOF'
"""Device Routes Adapter - FIXED"""
from flask import Blueprint, request, jsonify
from src.core.domain.device import Device
from src.config.dependencies import container

device_bp = Blueprint('devices', __name__, url_prefix='/api/devices')

@device_bp.route('', methods=['GET'])
def list_devices():
    try:
        devices = container.list_devices_usecase.execute()
        return jsonify([{
            'id': d.id,
            'name': d.name,
            'serial_number': d.serial_number,
            'device_type': d.device_type
        } for d in devices])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('/<int:device_id>', methods=['GET'])
def get_device(device_id: int):
    try:
        device = container.get_device_usecase.execute(device_id)
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
def create_device():
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
        created = container.create_device_usecase.execute(device)
        return jsonify({'id': created.id, 'message': 'Device created'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('/<int:device_id>', methods=['PUT'])
def update_device(device_id: int):
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
        container.update_device_usecase.execute(device)
        return jsonify({'message': 'Device updated'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('/<int:device_id>', methods=['DELETE'])
def delete_device(device_id: int):
    try:
        container.delete_device_usecase.execute(device_id)
        return jsonify({'message': 'Device deleted'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
EOF

print_success "device_routes.py aktualisiert"

print_header "✨ Route Fix angewendet!"

echo -e "${YELLOW}Nächste Schritte:${NC}\n"

echo "  1. Beende alte Anwendung:"
echo "     ${YELLOW}Ctrl+C${NC} (im Terminal mit run_app.sh)"
echo ""

echo "  2. Starte Anwendung neu:"
echo "     ${YELLOW}bash run_app.sh${NC}"
echo ""

echo "  3. Teste API:"
echo "     ${YELLOW}curl http://localhost:5000/api/devices${NC}"
echo ""

echo "  4. Öffne Browser:"
echo "     ${YELLOW}http://localhost:5000${NC}"
echo ""
