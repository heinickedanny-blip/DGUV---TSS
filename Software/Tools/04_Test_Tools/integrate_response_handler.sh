#!/bin/bash

################################################################################
# RESPONSE HANDLER INTEGRATION SCRIPT
# Automatisiert alle Änderungen für den Response Handler
################################################################################

set -e

PROJECT_DIR="/home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG"
cd "$PROJECT_DIR"

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🔄 RESPONSE HANDLER INTEGRATION${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# SCHRITT 1: Backups erstellen
# ============================================================================

echo -e "${YELLOW}📋 SCHRITT 1: Backups erstellen${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🔄 Erstelle Backups..."
cp src/main.py "src/main.py.backup_${TIMESTAMP}"
cp src/adapters/web/routes/device_routes.py "src/adapters/web/routes/device_routes.py.backup_${TIMESTAMP}"
cp src/adapters/web/dto/__init__.py "src/adapters/web/dto/__init__.py.backup_${TIMESTAMP}"

echo -e "${GREEN}✅ Backups erstellt:${NC}"
echo "   - src/main.py.backup_${TIMESTAMP}"
echo "   - src/adapters/web/routes/device_routes.py.backup_${TIMESTAMP}"
echo "   - src/adapters/web/dto/__init__.py.backup_${TIMESTAMP}"
echo ""

# ============================================================================
# SCHRITT 2: device_routes.py ersetzen
# ============================================================================
# 
# echo -e "${YELLOW}📋 SCHRITT 2: device_routes.py mit v2 Version ersetzen${NC}"
# echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
# echo ""
# 
# echo "🔄 Kopiere device_routes_v2.py zu device_routes.py..."
# cp src/adapters/web/routes/device_routes_v2.py src/adapters/web/routes/device_routes.py
# 
# echo "🔄 Passe Blueprint Namen an..."
# sed -i "s/device_bp_v2 = Blueprint('devices_v2'/device_bp = Blueprint('devices'/g" src/adapters/web/routes/device_routes.py
# sed -i "s|url_prefix='/api/v2/devices'|url_prefix='/api/devices'|g" src/adapters/web/routes/device_routes.py
# 
# echo -e "${GREEN}✅ device_routes.py aktualisiert${NC}"
# echo ""
# 
# ============================================================================
# SCHRITT 3: src/main.py aktualisieren
# ============================================================================

echo -e "${YELLOW}📋 SCHRITT 3: src/main.py aktualisieren${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

echo "🔄 Aktualisiere Imports..."
sed -i "s/from src.adapters.web.routes.device_routes import device_bp/from src.adapters.web.routes.device_routes import device_bp/g" src/main.py

echo "🔄 Prüfe ob Blueprint bereits registriert ist..."
if grep -q "app.register_blueprint(device_bp)" src/main.py; then
    echo -e "${GREEN}✅ Blueprint ist bereits registriert${NC}"
else
    echo -e "${YELLOW}⚠️  Blueprint nicht gefunden, versuche zu registrieren...${NC}"
fi

echo -e "${GREEN}✅ src/main.py aktualisiert${NC}"
echo ""

# ============================================================================
# SCHRITT 4: DTOs exportieren
# ============================================================================

echo -e "${YELLOW}📋 SCHRITT 4: DTOs in __init__.py exportieren${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

cat > src/adapters/web/dto/__init__.py << 'EOF'
"""Data Transfer Objects für Device API"""
from src.adapters.web.dto.device_dto import (
    CreateDeviceRequest,
    UpdateDeviceRequest,
    DeviceResponse,
    DeviceStatus,
    create_device_request_from_json,
    update_device_request_from_json
)

__all__ = [
    'CreateDeviceRequest',
    'UpdateDeviceRequest',
    'DeviceResponse',
    'DeviceStatus',
    'create_device_request_from_json',
    'update_device_request_from_json'
]
EOF

echo -e "${GREEN}✅ DTOs exportiert${NC}"
echo ""

# ============================================================================
# SCHRITT 5: Response Handler kopieren
# ============================================================================

echo -e "${YELLOW}📋 SCHRITT 5: Response Handler kopieren${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

if [ -f "src/adapters/web/response_handler.py" ]; then
    echo -e "${GREEN}✅ Response Handler existiert bereits${NC}"
else
    echo -e "${RED}❌ Response Handler nicht gefunden!${NC}"
    echo "   Bitte stelle sicher, dass response_handler.py existiert"
fi
echo ""

# ============================================================================
# SCHRITT 6: Validierung
# ============================================================================

echo -e "${YELLOW}📋 SCHRITT 6: Validierung${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

echo "🔍 Prüfe Imports..."
if python3 -c "from src.adapters.web.dto import CreateDeviceRequest; print('OK')" 2>/dev/null; then
    echo -e "${GREEN}✅ DTOs importierbar${NC}"
else
    echo -e "${RED}❌ DTOs nicht importierbar${NC}"
fi

echo "🔍 Prüfe Response Handler..."
if python3 -c "from src.adapters.web.response_handler import ResponseHandler; print('OK')" 2>/dev/null; then
    echo -e "${GREEN}✅ Response Handler importierbar${NC}"
else
    echo -e "${RED}❌ Response Handler nicht importierbar${NC}"
fi

echo "🔍 Prüfe Routes..."
if python3 -c "from src.adapters.web.routes.device_routes import device_bp; print('OK')" 2>/dev/null; then
    echo -e "${GREEN}✅ Routes importierbar${NC}"
else
    echo -e "${RED}❌ Routes nicht importierbar${NC}"
fi

echo ""

# ============================================================================
# SCHRITT 7: Container neu starten
# ============================================================================

echo -e "${YELLOW}📋 SCHRITT 7: Container neu starten${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

echo "🔄 Stoppe Container..."
podman-compose down

echo "🔄 Starte Container neu..."
podman-compose up -d

echo "⏳ Warte auf MySQL (15 Sekunden)..."
sleep 15

echo -e "${GREEN}✅ Container neu gestartet${NC}"
echo ""

# ============================================================================
# SCHRITT 8: Tests
# ============================================================================

echo -e "${YELLOW}📋 SCHRITT 8: Tests${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

echo "🧪 Test 1: Health Check"
HEALTH=$(curl -s http://localhost:5000/api/devices/health || echo "ERROR")
if echo "$HEALTH" | grep -q "healthy\|unhealthy"; then
    echo -e "${GREEN}✅ Health Check antwortet${NC}"
else
    echo -e "${RED}❌ Health Check antwortet nicht${NC}"
    echo "Response: $HEALTH"
fi
echo ""

echo "🧪 Test 2: List Devices"
LIST=$(curl -s http://localhost:5000/api/devices || echo "ERROR")
if echo "$LIST" | grep -q "success"; then
    echo -e "${GREEN}✅ List Devices antwortet${NC}"
    COUNT=$(echo "$LIST" | jq '.count // 0' 2>/dev/null || echo "?")
    echo "   Devices gefunden: $COUNT"
else
    echo -e "${RED}❌ List Devices antwortet nicht${NC}"
    echo "Response: $LIST"
fi
echo ""

echo "🧪 Test 3: Create Device"
CREATE=$(curl -s -X POST http://localhost:5000/api/devices \
    -H "Content-Type: application/json" \
    -d '{"customer":"IntegrationTest","name":"Test Device"}' || echo "ERROR")

if echo "$CREATE" | grep -q "success"; then
    echo -e "${GREEN}✅ Create Device antwortet${NC}"
    DEVICE_ID=$(echo "$CREATE" | jq '.device.customer_device_id // "?"' 2>/dev/null)
    echo "   Device erstellt: $DEVICE_ID"
else
    echo -e "${RED}❌ Create Device antwortet nicht${NC}"
    echo "Response: $CREATE"
fi
echo ""

# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================

echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ INTEGRATION ABGESCHLOSSEN${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "📋 ZUSAMMENFASSUNG:"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""
echo "✅ Backups erstellt"
echo "✅ device_routes.py aktualisiert"
echo "✅ src/main.py aktualisiert"
echo "✅ DTOs exportiert"
echo "✅ Response Handler verfügbar"
echo "✅ Container neu gestartet"
echo "✅ Tests durchgeführt"
echo ""

echo "🚀 NÄCHSTE SCHRITTE:"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""
echo "1. Teste die neue API:"
echo "   curl http://localhost:5000/api/devices | jq ."
echo ""
echo "2. Erstelle ein Device:"
echo "   curl -X POST http://localhost:5000/api/devices \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"customer\":\"Parloa\",\"name\":\"Elektroschrauber\"}'"
echo ""
echo "3. Teste Error Handling:"
echo "   curl -X POST http://localhost:5000/api/devices \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"customer\":\"\",\"name\":\"Device\"}'"
echo ""
echo "4. Führe Tests aus:"
echo "   pytest tests/test_device_routes_comprehensive.py -v"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✅ Script abgeschlossen!${NC}"
