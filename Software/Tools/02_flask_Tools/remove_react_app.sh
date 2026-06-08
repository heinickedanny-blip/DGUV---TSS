#!/bin/bash

###############################################################################
# remove_react_app.sh
# 
# Entfernt die React/Node.js Version des Benning Device Managers
# - Stoppt laufende Prozesse
# - Erstellt optional Backup
# - Entfernt Verzeichnisse
# - Bereinigt Container
###############################################################################

# Farben für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Pfade
REACT_APP_DIR="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/benning_device_manager_web"
BACKUP_DIR="$HOME/Dokumente/vsCode/Benning-DGUV3/archiv"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Hilfsfunktion für Bestätigungsabfrage
confirm() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$(echo -e ${CYAN}${prompt}${NC})" response
        case "$response" in
            [Jj][aA]|[Yy][eE][sS]|[Jj]|[Yy])
                return 0
                ;;
            [Nn][eE][iI][nN]|[Nn][oO]|[Nn])
                return 1
                ;;
            *)
                echo -e "${RED}Bitte antworte mit 'ja' oder 'nein'${NC}"
                ;;
        esac
    done
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     React-App entfernen (Benning Device Manager)          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Prüfe ob React-App existiert
if [ ! -d "$REACT_APP_DIR" ]; then
    echo -e "${RED}✗ React-App nicht gefunden:${NC}"
    echo "  $REACT_APP_DIR"
    echo ""
    echo -e "${YELLOW}Möglicherweise bereits gelöscht oder anderer Pfad?${NC}"
    exit 1
fi

# Zeige Informationen
echo -e "${CYAN}React-App gefunden:${NC}"
echo "  Pfad: $REACT_APP_DIR"
echo ""

# Zeige Größe
APP_SIZE=$(du -sh "$REACT_APP_DIR" 2>/dev/null | cut -f1)
echo -e "${CYAN}Größe: ${YELLOW}$APP_SIZE${NC}"
echo ""

# Zeige Statistik
if [ -d "$REACT_APP_DIR/node_modules" ]; then
    NODE_MODULES_SIZE=$(du -sh "$REACT_APP_DIR/node_modules" 2>/dev/null | cut -f1)
    echo -e "${CYAN}Davon node_modules: ${YELLOW}$NODE_MODULES_SIZE${NC}"
fi

FILE_COUNT=$(find "$REACT_APP_DIR" -type f 2>/dev/null | wc -l)
DIR_COUNT=$(find "$REACT_APP_DIR" -type d 2>/dev/null | wc -l)
echo -e "${CYAN}Dateien: ${YELLOW}$FILE_COUNT${NC}"
echo -e "${CYAN}Verzeichnisse: ${YELLOW}$DIR_COUNT${NC}"
echo ""

# Warnung
echo -e "${RED}⚠ WARNUNG:${NC}"
echo "  Diese Aktion löscht die gesamte React/Node.js Anwendung!"
echo "  Dies kann NICHT rückgängig gemacht werden (außer mit Backup)."
echo ""

# Backup-Option
if confirm "Möchten Sie ein Backup erstellen? (empfohlen) (ja/nein): "; then
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}BACKUP ERSTELLEN${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Erstelle Backup-Verzeichnis
    mkdir -p "$BACKUP_DIR"
    
    BACKUP_NAME="benning_react_backup_${TIMESTAMP}.tar.gz"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    
    echo -e "${CYAN}Erstelle Backup...${NC}"
    echo "  Ziel: $BACKUP_PATH"
    echo ""
    
    # Erstelle Backup (ohne node_modules für schnelleres Backup)
    if confirm "node_modules ausschließen? (empfohlen, spart Zeit) (ja/nein): "; then
        echo -e "${YELLOW}Erstelle Backup ohne node_modules...${NC}"
        tar -czf "$BACKUP_PATH" \
            --exclude="node_modules" \
            --exclude=".next" \
            --exclude="dist" \
            --exclude="build" \
            -C "$(dirname "$REACT_APP_DIR")" \
            "$(basename "$REACT_APP_DIR")" 2>/dev/null
    else
        echo -e "${YELLOW}Erstelle vollständiges Backup (kann dauern)...${NC}"
        tar -czf "$BACKUP_PATH" \
            -C "$(dirname "$REACT_APP_DIR")" \
            "$(basename "$REACT_APP_DIR")" 2>/dev/null
    fi
    
    if [ -f "$BACKUP_PATH" ]; then
        BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
        echo -e "${GREEN}✓ Backup erstellt: $BACKUP_SIZE${NC}"
        echo "  $BACKUP_PATH"
    else
        echo -e "${RED}✗ Backup fehlgeschlagen!${NC}"
        echo ""
        if ! confirm "Trotzdem fortfahren? (ja/nein): "; then
            echo -e "${YELLOW}Abgebrochen.${NC}"
            exit 1
        fi
    fi
    echo ""
fi

# Finale Bestätigung
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}LETZTE WARNUNG${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Folgendes wird gelöscht:"
echo "  - $REACT_APP_DIR"
echo "  - Alle Dateien und Verzeichnisse darin"
echo "  - Laufende Node.js Prozesse werden gestoppt"
echo ""

if ! confirm "Wirklich JETZT löschen? (ja/nein): "; then
    echo -e "${YELLOW}Abgebrochen. Nichts wurde gelöscht.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}ENTFERNUNG STARTEN${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. Stoppe Node.js Prozesse
echo -e "${CYAN}1. Stoppe Node.js Prozesse...${NC}"

BENNING_NODE_PROCS=$(pgrep -fa node | grep -i benning)
if [ ! -z "$BENNING_NODE_PROCS" ]; then
    echo "$BENNING_NODE_PROCS" | awk '{print $1}' | xargs -r kill -15 2>/dev/null
    sleep 2
    
    # Force-kill falls nötig
    REMAINING=$(pgrep -fa node | grep -i benning)
    if [ ! -z "$REMAINING" ]; then
        echo "$REMAINING" | awk '{print $1}' | xargs -r kill -9 2>/dev/null
    fi
    
    echo -e "${GREEN}✓ Node.js Prozesse gestoppt${NC}"
else
    echo -e "${YELLOW}○ Keine Benning Node.js Prozesse laufen${NC}"
fi
echo ""

# 2. Stoppe Prozesse auf Port 3000/3001
echo -e "${CYAN}2. Prüfe Ports 3000/3001...${NC}"

for port in 3000 3001; do
    PID=$(sudo ss -tlnp 2>/dev/null | grep ":${port} " | grep -oP 'pid=\K[0-9]+' | head -1)
    if [ ! -z "$PID" ]; then
        echo -e "${YELLOW}Port $port belegt (PID $PID), stoppe...${NC}"
        kill -15 $PID 2>/dev/null
        sleep 1
        kill -9 $PID 2>/dev/null || true
        echo -e "${GREEN}✓ Port $port freigegeben${NC}"
    else
        echo -e "${GREEN}✓ Port $port ist frei${NC}"
    fi
done
echo ""

# 3. Entferne Verzeichnis
echo -e "${CYAN}3. Entferne React-App Verzeichnis...${NC}"
echo "  $REACT_APP_DIR"
echo ""

rm -rf "$REACT_APP_DIR"

if [ ! -d "$REACT_APP_DIR" ]; then
    echo -e "${GREEN}✓ React-App erfolgreich entfernt${NC}"
else
    echo -e "${RED}✗ Fehler beim Entfernen${NC}"
    exit 1
fi
echo ""

# 4. Optional: Container bereinigen
echo -e "${CYAN}4. Container-Bereinigung (optional)...${NC}"

# Prüfe auf benning-mysql Container (alter Container)
if command -v docker &> /dev/null; then
    OLD_CONTAINER=$(docker ps -a --format "{{.Names}}" 2>/dev/null | grep -i "benning-mysql" | grep -v "flask")
    if [ ! -z "$OLD_CONTAINER" ]; then
        echo -e "${YELLOW}Alter MySQL-Container gefunden: $OLD_CONTAINER${NC}"
        if confirm "Möchten Sie den alten MySQL-Container entfernen? (ja/nein): "; then
            docker stop $OLD_CONTAINER 2>/dev/null
            docker rm $OLD_CONTAINER 2>/dev/null
            echo -e "${GREEN}✓ Container entfernt${NC}"
        fi
    fi
fi

if command -v podman &> /dev/null; then
    OLD_CONTAINER=$(podman ps -a --format "{{.Names}}" 2>/dev/null | grep -i "benning-mysql" | grep -v "flask")
    if [ ! -z "$OLD_CONTAINER" ]; then
        echo -e "${YELLOW}Alter MySQL-Container gefunden: $OLD_CONTAINER${NC}"
        if confirm "Möchten Sie den alten MySQL-Container entfernen? (ja/nein): "; then
            podman stop $OLD_CONTAINER 2>/dev/null
            podman rm $OLD_CONTAINER 2>/dev/null
            echo -e "${GREEN}✓ Container entfernt${NC}"
        fi
    fi
fi
echo ""

# Zusammenfassung
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     ${GREEN}✓ React-App erfolgreich entfernt${BLUE}                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "$BACKUP_PATH" ]; then
    echo -e "${GREEN}Backup verfügbar:${NC}"
    echo "  $BACKUP_PATH"
    echo ""
    echo -e "${CYAN}Wiederherstellen mit:${NC}"
    echo "  tar -xzf $BACKUP_PATH -C $(dirname "$REACT_APP_DIR")"
    echo ""
fi

echo -e "${CYAN}Freigegebener Speicherplatz: ${GREEN}~$APP_SIZE${NC}"
echo ""
echo -e "${YELLOW}Sie können jetzt die Flask-App verwenden:${NC}"
echo "  cd ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG"
echo "  ./venv/bin/python app.py"
echo ""
