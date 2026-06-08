#!/bin/bash

###############################################################################
# diagnose_usbc.sh
# 
# Prüft USB-C Installation vollständig
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_FILE="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/PRG/app.py"
TEMPLATE_FILE="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/PRG/templates/usbc_inspection.html"
UPLOAD_DIR="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/PRG/static/uploads/usbc"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  USB-C Installation Diagnose                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Prüfe app.py
echo -e "${YELLOW}1. Prüfe app.py...${NC}"

if [ ! -f "$APP_FILE" ]; then
    echo -e "${RED}✗ app.py nicht gefunden${NC}"
    exit 1
fi

# Prüfe USB-C Routen
ROUTE_COUNT=$(grep -c "@app.route.*usbc-inspection" "$APP_FILE" || true)
echo -e "  Routen für usbc-inspection: ${ROUTE_COUNT}"

if [ "$ROUTE_COUNT" -eq 0 ]; then
    echo -e "${RED}  ✗ Keine USB-C Routen gefunden!${NC}"
    echo -e "${YELLOW}  → Führen Sie patch_app_usbc.sh aus${NC}"
else
    echo -e "${GREEN}  ✓ USB-C Routen vorhanden${NC}"
fi

# Prüfe Funktionen
FUNC_COUNT=$(grep -c "def usbc_inspection" "$APP_FILE" || true)
echo -e "  Funktionen 'usbc_inspection': ${FUNC_COUNT}"

if [ "$FUNC_COUNT" -eq 0 ]; then
    echo -e "${RED}  ✗ Keine USB-C Funktionen gefunden!${NC}"
elif [ "$FUNC_COUNT" -eq 1 ]; then
    echo -e "${GREEN}  ✓ USB-C Funktionen korrekt${NC}"
else
    echo -e "${YELLOW}  ⚠ Mehrfache Funktionen ($FUNC_COUNT)${NC}"
fi

# Prüfe Imports
if grep -q "import json" "$APP_FILE"; then
    echo -e "${GREEN}  ✓ import json vorhanden${NC}"
else
    echo -e "${RED}  ✗ import json fehlt${NC}"
fi

if grep -q "from werkzeug.utils import secure_filename" "$APP_FILE"; then
    echo -e "${GREEN}  ✓ secure_filename Import vorhanden${NC}"
else
    echo -e "${RED}  ✗ secure_filename Import fehlt${NC}"
fi

# Prüfe Flask-Config
if grep -q "UPLOAD_FOLDER" "$APP_FILE"; then
    echo -e "${GREEN}  ✓ UPLOAD_FOLDER konfiguriert${NC}"
else
    echo -e "${RED}  ✗ UPLOAD_FOLDER fehlt${NC}"
fi

echo ""

# 2. Prüfe Template
echo -e "${YELLOW}2. Prüfe Template...${NC}"

if [ -f "$TEMPLATE_FILE" ]; then
    SIZE=$(stat -f%z "$TEMPLATE_FILE" 2>/dev/null || stat -c%s "$TEMPLATE_FILE" 2>/dev/null)
    echo -e "${GREEN}  ✓ usbc_inspection.html vorhanden (${SIZE} Bytes)${NC}"
else
    echo -e "${RED}  ✗ usbc_inspection.html fehlt${NC}"
    echo -e "${YELLOW}  → Kopieren Sie das Template:${NC}"
    echo "     cp ~/Dokumente/vsCode/Benning-DGUV3/Software/usbc_inspection.html $TEMPLATE_FILE"
fi

echo ""

# 3. Prüfe Upload-Verzeichnis
echo -e "${YELLOW}3. Prüfe Upload-Verzeichnis...${NC}"

if [ -d "$UPLOAD_DIR" ]; then
    echo -e "${GREEN}  ✓ Upload-Verzeichnis vorhanden${NC}"
else
    echo -e "${RED}  ✗ Upload-Verzeichnis fehlt${NC}"
    echo -e "${YELLOW}  → Erstellen:${NC}"
    echo "     mkdir -p $UPLOAD_DIR"
fi

echo ""

# 4. Prüfe Datenbank
echo -e "${YELLOW}4. Prüfe Datenbank...${NC}"

# Prüfe ob MySQL Container läuft
if command -v docker &> /dev/null; then
    if docker ps | grep -q benning-flask-mysql; then
        echo -e "${GREEN}  ✓ MySQL Container läuft${NC}"
        
        # Prüfe USB-C Tabellen
        TABLES=$(docker exec benning-flask-mysql mysql -u benning -pbenning benning_device_manager -e "SHOW TABLES LIKE 'usbc%';" 2>/dev/null | wc -l)
        
        if [ "$TABLES" -gt 1 ]; then
            echo -e "${GREEN}  ✓ USB-C Tabellen vorhanden ($((TABLES-1)) Tabellen)${NC}"
        else
            echo -e "${RED}  ✗ USB-C Tabellen fehlen${NC}"
            echo -e "${YELLOW}  → Führen Sie update_usbc.sh aus${NC}"
        fi
    else
        echo -e "${RED}  ✗ MySQL Container läuft nicht${NC}"
        echo -e "${YELLOW}  → Starten Sie den Container:${NC}"
        echo "     docker start benning-flask-mysql"
    fi
else
    echo -e "${YELLOW}  ⚠ Docker nicht gefunden, kann Datenbank nicht prüfen${NC}"
fi

echo ""

# 5. Zusammenfassung
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Zusammenfassung                                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Zähle Probleme
PROBLEMS=0

if [ "$ROUTE_COUNT" -eq 0 ]; then ((PROBLEMS++)); fi
if [ "$FUNC_COUNT" -ne 1 ]; then ((PROBLEMS++)); fi
if ! grep -q "import json" "$APP_FILE"; then ((PROBLEMS++)); fi
if ! grep -q "secure_filename" "$APP_FILE"; then ((PROBLEMS++)); fi
if ! grep -q "UPLOAD_FOLDER" "$APP_FILE"; then ((PROBLEMS++)); fi
if [ ! -f "$TEMPLATE_FILE" ]; then ((PROBLEMS++)); fi
if [ ! -d "$UPLOAD_DIR" ]; then ((PROBLEMS++)); fi

if [ "$PROBLEMS" -eq 0 ]; then
    echo -e "${GREEN}✅ Alle Prüfungen bestanden!${NC}"
    echo ""
    echo "USB-C Prüfung sollte funktionieren:"
    echo "  http://localhost:5000/device/USBC-001/usbc-inspection"
else
    echo -e "${RED}⚠ $PROBLEMS Problem(e) gefunden${NC}"
    echo ""
    echo "Beheben Sie die Probleme und starten Sie Flask neu."
fi

echo ""
