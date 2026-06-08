#!/bin/bash

###############################################################################
# show_services_and_ports_v2.sh
# 
# Optimierte Version mit:
# - Podman + Docker Support
# - Python/Flask-Prozesse
# - Port 3307 hervorgehoben
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

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Systemd Services und aktive Ports - Übersicht          ║${NC}"
echo -e "${BLUE}║                  (Optimierte Version)                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Systemd Services - nur die relevanten
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}1. SYSTEMD SERVICES (Datenbanken & Container)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SERVICES_FOUND=$(systemctl list-units --type=service --state=running | grep -E 'docker|containerd|podman|mysql|postgres|mongo|redis|mariadb')

if [ -z "$SERVICES_FOUND" ]; then
    echo -e "${RED}Keine relevanten Services gefunden${NC}"
else
    echo "$SERVICES_FOUND"
fi

echo ""

# 2. Node.js Prozesse
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}2. NODE.JS PROZESSE${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if pgrep -fa node > /dev/null 2>&1; then
    NODE_PROCS=$(pgrep -fa node)
    echo "$NODE_PROCS" | while IFS= read -r line; do
        PID=$(echo "$line" | awk '{print $1}')
        CMD=$(echo "$line" | cut -d' ' -f2-)
        
        # Hervorheben von Benning-Prozessen
        if echo "$CMD" | grep -qi "benning"; then
            echo -e "${CYAN}PID ${MAGENTA}$PID${CYAN}: ${YELLOW}$CMD${NC} ${RED}← BENNING${NC}"
        else
            echo -e "${CYAN}PID $PID: $CMD${NC}"
        fi
    done
else
    echo -e "${RED}Keine Node.js Prozesse laufen${NC}"
fi

echo ""

# 3. Python/Flask Prozesse (NEU!)
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}3. PYTHON/FLASK PROZESSE${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if pgrep -fa python > /dev/null 2>&1; then
    PYTHON_PROCS=$(pgrep -fa python | grep -E "flask|app.py|benning")
    
    if [ -z "$PYTHON_PROCS" ]; then
        echo -e "${YELLOW}Python läuft, aber keine Flask/Benning-Apps gefunden${NC}"
    else
        echo "$PYTHON_PROCS" | while IFS= read -r line; do
            PID=$(echo "$line" | awk '{print $1}')
            CMD=$(echo "$line" | cut -d' ' -f2-)
            echo -e "${CYAN}PID ${MAGENTA}$PID${CYAN}: ${YELLOW}$CMD${NC} ${RED}← FLASK${NC}"
        done
    fi
else
    echo -e "${RED}Keine Python-Prozesse laufen${NC}"
fi

echo ""

# 4. Docker Container
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}4. DOCKER CONTAINER${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v docker &> /dev/null; then
    DOCKER_CONTAINERS=$(docker ps 2>/dev/null)
    if [ -z "$DOCKER_CONTAINERS" ] || ! echo "$DOCKER_CONTAINERS" | grep -q "[0-9]"; then
        echo -e "${RED}Keine Docker Container laufen${NC}"
    else
        docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | while IFS= read -r line; do
            if echo "$line" | grep -qi "benning"; then
                echo -e "${YELLOW}$line${NC} ${RED}← BENNING${NC}"
            else
                echo "$line"
            fi
        done
    fi
else
    echo -e "${RED}Docker nicht installiert${NC}"
fi

echo ""

# 5. Podman Container (NEU!)
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}5. PODMAN CONTAINER${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v podman &> /dev/null; then
    PODMAN_CONTAINERS=$(podman ps 2>/dev/null)
    if [ -z "$PODMAN_CONTAINERS" ] || ! echo "$PODMAN_CONTAINERS" | grep -q "[0-9]"; then
        echo -e "${RED}Keine Podman Container laufen${NC}"
    else
        podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | while IFS= read -r line; do
            if echo "$line" | grep -qi "benning\|mysql"; then
                echo -e "${YELLOW}$line${NC} ${RED}← BENNING/MYSQL${NC}"
            else
                echo "$line"
            fi
        done
    fi
else
    echo -e "${RED}Podman nicht installiert${NC}"
fi

echo ""

# 6. Aktive Ports mit Prozessen
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}6. AKTIVE PORTS MIT PROZESSEN${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

PORTS_OUTPUT=$(sudo ss -tlnp 2>/dev/null | grep -v "systemd-resolve\|cupsd\|avahi\|State" | tail -n +2)

if [ -z "$PORTS_OUTPUT" ]; then
    echo -e "${RED}Keine relevanten Ports gefunden${NC}"
else
    echo -e "${CYAN}Port\t\tProzess${NC}"
    echo "$PORTS_OUTPUT" | while IFS= read -r line; do
        PORT=$(echo "$line" | awk '{print $4}' | grep -oP ':\K[0-9]+$')
        PROCESS=$(echo "$line" | awk '{print $NF}')
        
        # Wichtige Ports hervorheben
        if [ "$PORT" = "3000" ] || [ "$PORT" = "3001" ]; then
            echo -e "${MAGENTA}$PORT\t\t$PROCESS${NC} ${RED}← NODE.JS (React)${NC}"
        elif [ "$PORT" = "5000" ]; then
            echo -e "${MAGENTA}$PORT\t\t$PROCESS${NC} ${RED}← FLASK${NC}"
        elif [ "$PORT" = "3306" ]; then
            echo -e "${MAGENTA}$PORT\t\t$PROCESS${NC} ${RED}← MySQL (Standard)${NC}"
        elif [ "$PORT" = "3307" ]; then
            echo -e "${YELLOW}$PORT\t\t$PROCESS${NC} ${RED}← MySQL (Flask)${NC}"
        else
            echo -e "$PORT\t\t$PROCESS"
        fi
    done
fi

echo ""

# 7. Port-Zusammenfassung (NEU!)
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}7. PORT-ZUSAMMENFASSUNG (Wichtige Ports)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

check_port() {
    local port=$1
    local desc=$2
    if sudo ss -tlnp 2>/dev/null | grep -q ":${port} "; then
        echo -e "${GREEN}✓${NC} Port ${MAGENTA}$port${NC} - $desc ${RED}BELEGT${NC}"
    else
        echo -e "${CYAN}○${NC} Port ${CYAN}$port${NC} - $desc ${GREEN}FREI${NC}"
    fi
}

check_port "3000" "Node.js (React-App)"
check_port "3001" "Node.js (Alternative)"
check_port "5000" "Flask (Python-App)"
check_port "3306" "MySQL (Standard)"
check_port "3307" "MySQL (Flask-Container)"

echo ""
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Hinweis: Benning-relevante Prozesse sind ${RED}ROT${CYAN} markiert${NC}"
