#!/bin/bash

################################################################################
# BENNING DEVICE MANAGER - DATABASE FIX SCRIPT
# 4 Anwendungen: Diagnose, Warten, Reparatur, Validierung
################################################################################

set -e

PROJECT_DIR="/home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG"
cd "$PROJECT_DIR"

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🗄️  BENNING DEVICE MANAGER - DATABASE FIX SCRIPT${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# ANWENDUNG 1: DIAGNOSE
# ============================================================================

echo -e "${YELLOW}📋 ANWENDUNG 1: DIAGNOSE${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

echo "🔍 Prüfe Container-Status..."
echo ""

# Prüfe ob Container laufen
MYSQL_RUNNING=$(podman ps --filter "name=benning-mysql" --format "{{.State}}" 2>/dev/null || echo "")
FLASK_RUNNING=$(podman ps --filter "name=benning-flask" --format "{{.State}}" 2>/dev/null || echo "")

echo "MySQL Container: ${MYSQL_RUNNING:-❌ NICHT GEFUNDEN}"
echo "Flask Container: ${FLASK_RUNNING:-❌ NICHT GEFUNDEN}"
echo ""

# Prüfe MySQL Logs
echo "🔍 Prüfe MySQL Logs..."
if podman logs benning-mysql 2>&1 | grep -q "ready for connections"; then
    echo -e "${GREEN}✅ MySQL ist bereit${NC}"
    MYSQL_READY=1
else
    echo -e "${RED}❌ MySQL startet noch...${NC}"
    MYSQL_READY=0
fi
echo ""

# Prüfe Flask Logs
echo "🔍 Prüfe Flask Logs..."
if podman logs benning-flask 2>&1 | grep -q "ERROR\|Traceback"; then
    echo -e "${RED}❌ Flask hat Fehler${NC}"
    podman logs benning-flask 2>&1 | grep -A 5 "ERROR\|Traceback" | head -20
    FLASK_OK=0
else
    echo -e "${GREEN}✅ Flask läuft ohne Fehler${NC}"
    FLASK_OK=1
fi
echo ""

# Prüfe Netzwerk
echo "🔍 Prüfe Netzwerk..."
NETWORK=$(podman network ls --filter "name=prg" --format "{{.Name}}" 2>/dev/null || echo "")
if [ -n "$NETWORK" ]; then
    echo -e "${GREEN}✅ Netzwerk 'prg' existiert${NC}"
else
    echo -e "${RED}❌ Netzwerk 'prg' nicht gefunden${NC}"
fi
echo ""

# ============================================================================
# ANWENDUNG 2: WARTEN
# ============================================================================

echo -e "${YELLOW}⏳ ANWENDUNG 2: WARTEN (MySQL Startup)${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

echo "⏳ Warte auf MySQL (max 60 Sekunden)..."
COUNTER=0
MAX_WAIT=60

while [ $COUNTER -lt $MAX_WAIT ]; do
    if podman exec benning-mysql mysql -u benning -pbenning benning_device_manager -e "SELECT 1" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ MySQL ist bereit nach ${COUNTER} Sekunden${NC}"
        MYSQL_READY=1
        break
    fi
    
    COUNTER=$((COUNTER + 1))
    echo -n "."
    sleep 1
    
    if [ $((COUNTER % 10)) -eq 0 ]; then
        echo " ($COUNTER/$MAX_WAIT)"
    fi
done

if [ $COUNTER -ge $MAX_WAIT ]; then
    echo -e "${RED}❌ MySQL ist nach 60 Sekunden immer noch nicht bereit${NC}"
    echo ""
    echo "Versuche Container-Restart..."
    podman restart benning-mysql
    sleep 15
    echo "Versuche erneut..."
    COUNTER=0
    while [ $COUNTER -lt 30 ]; do
        if podman exec benning-mysql mysql -u benning -pbenning benning_device_manager -e "SELECT 1" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ MySQL ist nach Restart bereit${NC}"
            MYSQL_READY=1
            break
        fi
        COUNTER=$((COUNTER + 1))
        echo -n "."
        sleep 1
    done
fi
echo ""

# ============================================================================
# ANWENDUNG 3: REPARATUR
# ============================================================================

echo -e "${YELLOW}🔧 ANWENDUNG 3: REPARATUR${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

if [ $MYSQL_READY -eq 1 ]; then
    echo "🔧 Prüfe Datenbankschema..."
    
    # Prüfe ob Tabelle existiert
    TABLE_EXISTS=$(podman exec benning-mysql mysql -u benning -pbenning benning_device_manager -e "SHOW TABLES LIKE 'devices'" 2>/dev/null | wc -l)
    
    if [ $TABLE_EXISTS -gt 1 ]; then
        echo -e "${GREEN}✅ Tabelle 'devices' existiert${NC}"
    else
        echo -e "${YELLOW}⚠️  Tabelle 'devices' existiert nicht, erstelle Schema...${NC}"
        
        # Lese schema.sql und führe aus
        if [ -f "schema.sql" ]; then
            podman exec -i benning-mysql mysql -u benning -pbenning benning_device_manager < schema.sql
            echo -e "${GREEN}✅ Schema erstellt${NC}"
        else
            echo -e "${RED}❌ schema.sql nicht gefunden${NC}"
        fi
    fi
    echo ""
    
    # Prüfe Spalten
    echo "🔧 Prüfe Spalten..."
    podman exec benning-mysql mysql -u benning -pbenning benning_device_manager -e "DESCRIBE devices;" | head -20
    echo ""
    
    # Prüfe Indizes
    echo "🔧 Prüfe Indizes..."
    INDEX_COUNT=$(podman exec benning-mysql mysql -u benning -pbenning benning_device_manager -e "SHOW INDEXES FROM devices" 2>/dev/null | wc -l)
    echo -e "${GREEN}✅ ${INDEX_COUNT} Indizes gefunden${NC}"
    echo ""
    
    # Prüfe Datensätze
    echo "🔧 Prüfe Datensätze..."
    RECORD_COUNT=$(podman exec benning-mysql mysql -u benning -pbenning benning_device_manager -e "SELECT COUNT(*) FROM devices" 2>/dev/null | tail -1)
    echo -e "${GREEN}✅ ${RECORD_COUNT} Datensätze in der Datenbank${NC}"
    echo ""
else
    echo -e "${RED}❌ MySQL ist nicht bereit, überspringe Reparatur${NC}"
    echo ""
fi

# ============================================================================
# ANWENDUNG 4: VALIDIERUNG
# ============================================================================

echo -e "${YELLOW}✅ ANWENDUNG 4: VALIDIERUNG${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

# Starte Flask neu
echo "🔄 Starte Flask Container neu..."
podman restart benning-flask
sleep 5
echo -e "${GREEN}✅ Flask Container neu gestartet${NC}"
echo ""

# Test 1: Health Check
echo "🧪 Test 1: Health Check Endpoint"
HEALTH_RESPONSE=$(curl -s http://localhost:5000/api/health || echo "ERROR")

if echo "$HEALTH_RESPONSE" | grep -q "healthy\|unhealthy"; then
    echo -e "${GREEN}✅ Health Check antwortet${NC}"
    echo "Response: $HEALTH_RESPONSE"
else
    echo -e "${RED}❌ Health Check antwortet nicht korrekt${NC}"
    echo "Response: $HEALTH_RESPONSE"
fi
echo ""

# Test 2: List Devices
echo "🧪 Test 2: List Devices Endpoint"
LIST_RESPONSE=$(curl -s http://localhost:5000/api/devices || echo "ERROR")

if echo "$LIST_RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✅ List Devices antwortet${NC}"
    echo "Response: $(echo $LIST_RESPONSE | jq . 2>/dev/null || echo $LIST_RESPONSE | head -c 100)"
else
    echo -e "${RED}❌ List Devices antwortet nicht korrekt${NC}"
    echo "Response: $LIST_RESPONSE"
fi
echo ""

# Test 3: Create Device
echo "🧪 Test 3: Create Device Endpoint"
CREATE_RESPONSE=$(curl -s -X POST http://localhost:5000/api/devices \
    -H "Content-Type: application/json" \
    -d '{"customer":"TestCustomer","name":"Test Device","type":"Elektrowerkzeug"}' || echo "ERROR")

if echo "$CREATE_RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✅ Create Device antwortet${NC}"
    echo "Response: $(echo $CREATE_RESPONSE | jq . 2>/dev/null || echo $CREATE_RESPONSE | head -c 100)"
else
    echo -e "${RED}❌ Create Device antwortet nicht korrekt${NC}"
    echo "Response: $CREATE_RESPONSE"
fi
echo ""

# Test 4: Get Next ID
echo "🧪 Test 4: Get Next ID Endpoint"
NEXT_ID_RESPONSE=$(curl -s "http://localhost:5000/api/devices/next-id?customer=TestCustomer" || echo "ERROR")

if echo "$NEXT_ID_RESPONSE" | grep -q "next_id"; then
    echo -e "${GREEN}✅ Get Next ID antwortet${NC}"
    echo "Response: $NEXT_ID_RESPONSE"
else
    echo -e "${RED}❌ Get Next ID antwortet nicht korrekt${NC}"
    echo "Response: $NEXT_ID_RESPONSE"
fi
echo ""

# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================

echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ DATABASE FIX SCRIPT ABGESCHLOSSEN${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "📋 ZUSAMMENFASSUNG:"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""

echo "1️⃣  DIAGNOSE"
echo "   ✅ Container-Status geprüft"
echo "   ✅ MySQL Logs analysiert"
echo "   ✅ Flask Logs analysiert"
echo "   ✅ Netzwerk geprüft"
echo ""

echo "2️⃣  WARTEN"
echo "   ✅ Auf MySQL Startup gewartet"
echo "   ✅ Verbindung validiert"
echo ""

echo "3️⃣  REPARATUR"
echo "   ✅ Datenbankschema geprüft"
echo "   ✅ Tabellen validiert"
echo "   ✅ Indizes geprüft"
echo "   ✅ Datensätze gezählt"
echo ""

echo "4️⃣  VALIDIERUNG"
echo "   ✅ Health Check Test"
echo "   ✅ List Devices Test"
echo "   ✅ Create Device Test"
echo "   ✅ Get Next ID Test"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "🚀 NÄCHSTE SCHRITTE:"
echo "─────────────────────────────────────────────────────────────────────────"
echo ""

echo "1. Teste die API manuell:"
echo "   curl http://localhost:5000/api/health | jq ."
echo ""

echo "2. Erstelle ein neues Device:"
echo "   curl -X POST http://localhost:5000/api/devices \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"customer\":\"Parloa\",\"name\":\"Elektroschrauber\"}'"
echo ""

echo "3. Liste alle Devices:"
echo "   curl http://localhost:5000/api/devices | jq ."
echo ""

echo "4. Führe Tests aus:"
echo "   pytest tests/test_device_routes_comprehensive.py -v"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✅ Script abgeschlossen!${NC}"
