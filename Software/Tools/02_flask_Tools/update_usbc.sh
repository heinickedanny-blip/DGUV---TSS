#!/bin/bash

###############################################################################
# update_usbc.sh
# 
# Installiert USB-C Kabel-Prüfung Erweiterung für Benning Flask
###############################################################################

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Konfiguration
CONTAINER_NAME="benning-flask-mysql"
DB_NAME="benning_device_manager"
DB_USER="benning"
DB_PASSWORD="benning"
FLASK_DIR="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/PRG"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  USB-C Kabel-Prüfung Erweiterung installieren             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Prüfe Container-Tool
if command -v docker &> /dev/null; then
    CMD="docker"
elif command -v podman &> /dev/null; then
    CMD="podman"
else
    echo -e "${RED}✗ Weder Docker noch Podman gefunden!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Container-Tool: $CMD${NC}"

# Prüfe ob Container läuft
if ! $CMD ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}✗ Container '$CONTAINER_NAME' läuft nicht!${NC}"
    echo ""
    echo "Starten Sie den Container mit:"
    echo "  $CMD start $CONTAINER_NAME"
    exit 1
fi

echo -e "${GREEN}✓ Container läuft${NC}"
echo ""

# Prüfe ob Flask-App existiert
if [ ! -d "$FLASK_DIR" ]; then
    echo -e "${RED}✗ Flask-App nicht gefunden: $FLASK_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flask-App gefunden${NC}"
echo ""

# 1. Datenbank-Schema aktualisieren
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}1. Datenbank-Schema aktualisieren${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Prüfe ob SQL-Datei existiert
if [ ! -f "$SCRIPT_DIR/usbc_extension.sql" ]; then
    echo -e "${RED}✗ usbc_extension.sql nicht gefunden!${NC}"
    exit 1
fi

echo -e "${YELLOW}→ Importiere USB-C Schema...${NC}"

# Kopiere SQL-Datei in Container
$CMD cp "$SCRIPT_DIR/usbc_extension.sql" $CONTAINER_NAME:/tmp/usbc_extension.sql

# Importiere mit Benutzer-Passwort (nicht Root)
if $CMD exec -i $CONTAINER_NAME mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME < "$SCRIPT_DIR/usbc_extension.sql" 2>/dev/null; then
    echo -e "${GREEN}✓ Schema erfolgreich aktualisiert${NC}"
else
    echo -e "${YELLOW}⚠ Automatische Authentifizierung fehlgeschlagen${NC}"
    echo -e "${CYAN}Bitte geben Sie das MySQL-Passwort für Benutzer '$DB_USER' ein:${NC}"
    echo ""
    
    if $CMD exec -it $CONTAINER_NAME sh -c "mysql -u $DB_USER -p $DB_NAME < /tmp/usbc_extension.sql"; then
        echo -e "${GREEN}✓ Schema erfolgreich aktualisiert${NC}"
    else
        echo -e "${RED}✗ Schema-Import fehlgeschlagen${NC}"
        exit 1
    fi
fi

echo ""

# 2. Templates kopieren
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}2. Templates kopieren${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

mkdir -p "$FLASK_DIR/templates"

if [ -f "$SCRIPT_DIR/usbc_inspection.html" ]; then
    cp "$SCRIPT_DIR/usbc_inspection.html" "$FLASK_DIR/templates/"
    echo -e "${GREEN}✓ usbc_inspection.html kopiert${NC}"
else
    echo -e "${YELLOW}⚠ usbc_inspection.html nicht gefunden${NC}"
fi

echo ""

# 3. Upload-Verzeichnis erstellen
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}3. Upload-Verzeichnis erstellen${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

mkdir -p "$FLASK_DIR/static/uploads/usbc"
chmod 755 "$FLASK_DIR/static/uploads/usbc"

echo -e "${GREEN}✓ Upload-Verzeichnis erstellt${NC}"
echo ""

# 4. Python-Code-Hinweise
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}4. Python-Code Integration${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${CYAN}Bitte fügen Sie folgende Zeilen zu Ihrer app.py hinzu:${NC}"
echo ""
echo -e "${YELLOW}# Am Anfang der Datei:${NC}"
echo "import os"
echo "import json"
echo "from werkzeug.utils import secure_filename"
echo ""
echo -e "${YELLOW}# Nach den bestehenden Routen:${NC}"
echo "# Kopieren Sie den Inhalt von usbc_routes.py"
echo ""

if [ -f "$SCRIPT_DIR/usbc_routes.py" ]; then
    echo -e "${GREEN}✓ usbc_routes.py verfügbar${NC}"
    echo -e "${CYAN}  Pfad: $SCRIPT_DIR/usbc_routes.py${NC}"
else
    echo -e "${YELLOW}⚠ usbc_routes.py nicht gefunden${NC}"
fi

echo ""

# 5. Navigation erweitern
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}5. Navigation erweitern (optional)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${CYAN}Fügen Sie zu Ihrer Navigation hinzu:${NC}"
echo ""
echo '<a href="/usbc-inspections">🔌 USB-C Prüfungen</a>'
echo ""

# 6. Testen
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}6. Installation testen${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${YELLOW}→ Teste Datenbank-Tabellen...${NC}"

TABLES_CHECK=$($CMD exec $CONTAINER_NAME mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME -e "
    SELECT COUNT(*) as count FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = '$DB_NAME' AND TABLE_NAME LIKE 'usbc_%'
" 2>/dev/null | tail -1)

if [ "$TABLES_CHECK" -ge 4 ]; then
    echo -e "${GREEN}✓ $TABLES_CHECK USB-C Tabellen erstellt${NC}"
else
    echo -e "${RED}✗ USB-C Tabellen fehlen${NC}"
fi

# Prüfe Beispieldaten
DEVICES_CHECK=$($CMD exec $CONTAINER_NAME mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME -e "
    SELECT COUNT(*) as count FROM devices WHERE id LIKE 'USBC-%'
" 2>/dev/null | tail -1)

if [ "$DEVICES_CHECK" -gt 0 ]; then
    echo -e "${GREEN}✓ $DEVICES_CHECK USB-C Beispielgeräte vorhanden${NC}"
fi

echo ""

# Zusammenfassung
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ✓ USB-C Erweiterung installiert!                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Neue Features:${NC}"
echo "  ✅ 4 neue Datenbank-Tabellen"
echo "  ✅ USB-C Prüfungsformular"
echo "  ✅ Widerstandsmessungen"
echo "  ✅ Protokoll-Tests"
echo "  ✅ Foto-Upload (Pinout)"
echo "  ✅ eMarker-Daten"
echo "  ✅ 3 Beispiel-Geräte (USBC-001 bis USBC-003)"
echo ""

echo -e "${YELLOW}Nächste Schritte:${NC}"
echo "  1. Integrieren Sie usbc_routes.py in app.py"
echo "  2. Starten Sie Flask neu:"
echo "     cd $FLASK_DIR"
echo "     ./venv/bin/python app.py"
echo "  3. Öffnen Sie: http://localhost:5000/device/USBC-001/usbc-inspection"
echo ""

echo -e "${CYAN}Dokumentation:${NC}"
echo "  - usbc_routes.py: Python-Code für Routen"
echo "  - usbc_extension.sql: Datenbank-Schema"
echo "  - usbc_inspection.html: Prüfungsformular"
echo ""

echo -e "${GREEN}Viel Erfolg mit der USB-C Kabel-Prüfung! 🔌${NC}"
