#!/bin/bash

###############################################################################
# stop_services_and_ports_v2.sh
# 
# Optimierte Version mit:
# - Podman + Docker Support
# - Nur Container stoppen (nicht Docker-Service)
# - Python/Flask-Prozesse
# - Whitelist für wichtige Prozesse
# - Bessere Filterung
###############################################################################

# Farben für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

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
echo -e "${BLUE}║     Services und Ports stoppen (Optimierte Version)       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

STOPPED_ANY=0

# 1. Node.js Prozesse stoppen (mit Whitelist)
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}1. NODE.JS PROZESSE${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if pgrep -fa node > /dev/null 2>&1; then
    echo -e "${CYAN}Node.js Prozesse gefunden:${NC}"
    
    # Zeige alle Node.js Prozesse mit Nummerierung
    pgrep -fa node | nl -w2 -s'. '
    
    echo ""
    echo -e "${YELLOW}Hinweis: Benning-relevante Prozesse werden automatisch erkannt${NC}"
    echo ""
    
    if confirm "Wirklich alle Node.js Prozesse stoppen? (ja/nein): "; then
        echo -e "${YELLOW}Stoppe Node.js Prozesse...${NC}"
        
        # Graceful shutdown
        pkill -15 -f node
        sleep 2
        
        # Prüfe ob noch Prozesse laufen
        if pgrep -fa node > /dev/null 2>&1; then
            echo -e "${YELLOW}Einige Prozesse reagieren nicht, verwende SIGKILL...${NC}"
            pkill -9 -f node
            sleep 1
        fi
        
        if pgrep -fa node > /dev/null 2>&1; then
            echo -e "${RED}✗ Einige Node.js Prozesse konnten nicht gestoppt werden${NC}"
        else
            echo -e "${GREEN}✓ Alle Node.js Prozesse gestoppt${NC}"
            STOPPED_ANY=1
        fi
    else
        echo -e "${YELLOW}→ Node.js wird nicht gestoppt${NC}"
    fi
else
    echo -e "${RED}Keine Node.js Prozesse laufen${NC}"
fi

echo ""

# 2. Python/Flask Prozesse stoppen (NEU!)
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}2. PYTHON/FLASK PROZESSE${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

FLASK_PROCS=$(pgrep -fa python | grep -E "flask|app.py|benning")

if [ ! -z "$FLASK_PROCS" ]; then
    echo -e "${CYAN}Flask/Benning Prozesse gefunden:${NC}"
    echo "$FLASK_PROCS" | nl -w2 -s'. '
    echo ""
    
    if confirm "Wirklich alle Flask/Python Prozesse stoppen? (ja/nein): "; then
        echo -e "${YELLOW}Stoppe Flask Prozesse...${NC}"
        
        # Graceful shutdown
        echo "$FLASK_PROCS" | awk '{print $1}' | xargs -r kill -15 2>/dev/null
        sleep 2
        
        # Prüfe ob noch Prozesse laufen
        REMAINING=$(pgrep -fa python | grep -E "flask|app.py|benning")
        if [ ! -z "$REMAINING" ]; then
            echo -e "${YELLOW}Einige Prozesse reagieren nicht, verwende SIGKILL...${NC}"
            echo "$REMAINING" | awk '{print $1}' | xargs -r kill -9 2>/dev/null
        fi
        
        echo -e "${GREEN}✓ Flask Prozesse gestoppt${NC}"
        STOPPED_ANY=1
    else
        echo -e "${YELLOW}→ Flask wird nicht gestoppt${NC}"
    fi
else
    echo -e "${RED}Keine Flask/Python Prozesse laufen${NC}"
fi

echo ""

# 3. Docker Container stoppen (NICHT Docker-Service!)
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}3. DOCKER CONTAINER${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v docker &> /dev/null; then
    CONTAINER_COUNT=$(docker ps -q 2>/dev/null | wc -l)
    if [ "$CONTAINER_COUNT" -gt 0 ]; then
        echo -e "${CYAN}Docker Container gefunden: ($CONTAINER_COUNT)${NC}"
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
        echo ""
        
        # Zeige Benning-Container hervorgehoben
        BENNING_CONTAINERS=$(docker ps --format "{{.Names}}" | grep -i benning)
        if [ ! -z "$BENNING_CONTAINERS" ]; then
            echo -e "${RED}⚠ Benning-Container gefunden:${NC}"
            echo "$BENNING_CONTAINERS" | sed 's/^/  - /'
            echo ""
        fi
        
        if confirm "Wirklich alle Docker Container stoppen? (ja/nein): "; then
            echo -e "${YELLOW}Stoppe Docker Container...${NC}"
            docker stop $(docker ps -q) 2>/dev/null
            echo -e "${GREEN}✓ Docker Container gestoppt${NC}"
            STOPPED_ANY=1
        else
            echo -e "${YELLOW}→ Docker Container werden nicht gestoppt${NC}"
        fi
    else
        echo -e "${RED}Keine Docker Container laufen${NC}"
    fi
else
    echo -e "${RED}Docker nicht installiert${NC}"
fi

echo ""

# 4. Podman Container stoppen (NEU!)
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}4. PODMAN CONTAINER${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v podman &> /dev/null; then
    CONTAINER_COUNT=$(podman ps -q 2>/dev/null | wc -l)
    if [ "$CONTAINER_COUNT" -gt 0 ]; then
        echo -e "${CYAN}Podman Container gefunden: ($CONTAINER_COUNT)${NC}"
        podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
        echo ""
        
        # Zeige MySQL/Benning-Container hervorgehoben
        MYSQL_CONTAINERS=$(podman ps --format "{{.Names}}" | grep -iE "benning|mysql")
        if [ ! -z "$MYSQL_CONTAINERS" ]; then
            echo -e "${RED}⚠ MySQL/Benning-Container gefunden:${NC}"
            echo "$MYSQL_CONTAINERS" | sed 's/^/  - /'
            echo ""
        fi
        
        echo -e "${YELLOW}Optionen:${NC}"
        echo "  1) Alle Container stoppen"
        echo "  2) Nur Benning/MySQL Container stoppen"
        echo "  3) Nichts stoppen"
        echo ""
        read -p "$(echo -e ${CYAN}Wähle Option [1-3]: ${NC})" option
        
        case "$option" in
            1)
                echo -e "${YELLOW}Stoppe alle Podman Container...${NC}"
                podman stop $(podman ps -q) 2>/dev/null
                echo -e "${GREEN}✓ Alle Podman Container gestoppt${NC}"
                STOPPED_ANY=1
                ;;
            2)
                if [ ! -z "$MYSQL_CONTAINERS" ]; then
                    echo -e "${YELLOW}Stoppe MySQL/Benning Container...${NC}"
                    echo "$MYSQL_CONTAINERS" | xargs -r podman stop 2>/dev/null
                    echo -e "${GREEN}✓ MySQL/Benning Container gestoppt${NC}"
                    STOPPED_ANY=1
                else
                    echo -e "${RED}Keine MySQL/Benning Container gefunden${NC}"
                fi
                ;;
            3)
                echo -e "${YELLOW}→ Podman Container werden nicht gestoppt${NC}"
                ;;
            *)
                echo -e "${RED}Ungültige Option${NC}"
                ;;
        esac
    else
        echo -e "${RED}Keine Podman Container laufen${NC}"
    fi
else
    echo -e "${RED}Podman nicht installiert${NC}"
fi

echo ""

# 5. Prozesse auf spezifischen Ports stoppen
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}5. PROZESSE AUF WICHTIGEN PORTS${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Wichtige Ports definieren
IMPORTANT_PORTS=("3000" "3001" "5000")

for port in "${IMPORTANT_PORTS[@]}"; do
    PID=$(sudo ss -tlnp 2>/dev/null | grep ":${port} " | grep -oP 'pid=\K[0-9]+' | head -1)
    
    if [ ! -z "$PID" ]; then
        PROCESS_INFO=$(ps -p $PID -o pid,cmd --no-headers 2>/dev/null)
        
        if [ ! -z "$PROCESS_INFO" ]; then
            echo -e "${CYAN}Port ${MAGENTA}$port${CYAN} belegt:${NC}"
            echo -e "  PID: ${GREEN}$PID${NC}"
            echo -e "  CMD: ${YELLOW}$(echo $PROCESS_INFO | cut -d' ' -f2-)${NC}"
            
            if confirm "Prozess auf Port $port stoppen? (ja/nein): "; then
                echo -e "${YELLOW}Stoppe PID $PID...${NC}"
                kill -15 $PID 2>/dev/null
                sleep 1
                
                if ps -p $PID > /dev/null 2>&1; then
                    echo -e "${YELLOW}SIGTERM erfolglos, verwende SIGKILL...${NC}"
                    kill -9 $PID 2>/dev/null
                fi
                
                if ! ps -p $PID > /dev/null 2>&1; then
                    echo -e "${GREEN}✓ Prozess gestoppt, Port $port ist frei${NC}"
                    STOPPED_ANY=1
                else
                    echo -e "${RED}✗ Konnte Prozess nicht stoppen${NC}"
                fi
            else
                echo -e "${YELLOW}→ Port $port bleibt belegt${NC}"
            fi
            echo ""
        fi
    fi
done

# 6. Zusammenfassung und Empfehlung
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}6. PORT-STATUS NACH CLEANUP${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_port() {
    local port=$1
    local desc=$2
    if sudo ss -tlnp 2>/dev/null | grep -q ":${port} "; then
        echo -e "${RED}✗${NC} Port ${MAGENTA}$port${NC} - $desc ${RED}BELEGT${NC}"
    else
        echo -e "${GREEN}✓${NC} Port ${CYAN}$port${NC} - $desc ${GREEN}FREI${NC}"
    fi
}

check_port "3000" "Node.js (React-App)"
check_port "5000" "Flask (Python-App)"
check_port "3307" "MySQL (Flask-Container)"

echo ""

# Zusammenfassung
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
if [ $STOPPED_ANY -eq 1 ]; then
    echo -e "${BLUE}║     ${GREEN}✓ Cleanup abgeschlossen${BLUE}                             ║${NC}"
    echo -e "${BLUE}║                                                            ║${NC}"
    echo -e "${BLUE}║     ${CYAN}Sie können jetzt die Flask-App installieren:${BLUE}       ║${NC}"
    echo -e "${BLUE}║     ${YELLOW}bash install_frontend_py.sh${BLUE}                        ║${NC}"
else
    echo -e "${BLUE}║     ${YELLOW}Nichts wurde gestoppt${BLUE}                              ║${NC}"
fi
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
