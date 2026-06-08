#!/bin/bash

# ============================================================================
# Benning Flask Container Restart Script
# Behebt Container-Dependency-Fehler und startet den Server neu
# ============================================================================

set -e  # Beende bei Fehler

echo "🔄 Starte Benning Flask Container Restart..."
echo ""

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# Schritt 1: Alle Container stoppen
# ============================================================================
echo -e "${YELLOW}[1/5]${NC} Stoppe alle Container..."
if podman ps -q > /dev/null 2>&1; then
    podman stop -a -t 5 2>/dev/null || true
    echo -e "${GREEN}✓ Container gestoppt${NC}"
else
    echo -e "${YELLOW}⚠ Keine laufenden Container${NC}"
fi
echo ""

# ============================================================================
# Schritt 2: Entferne den fehlerhaften abhängigen Container
# ============================================================================
echo -e "${YELLOW}[2/5]${NC} Entferne fehlerhaften abhängigen Container..."
DEPENDENCY_ID="73719f8355fe67a7b09c5e57676b767cde67731b0f646d50f75c03d53eded27b"
if podman ps -a --format "{{.ID}}" | grep -q "^$DEPENDENCY_ID"; then
    podman rm -f "$DEPENDENCY_ID" 2>/dev/null || true
    echo -e "${GREEN}✓ Abhängiger Container entfernt${NC}"
else
    echo -e "${YELLOW}⚠ Abhängiger Container nicht gefunden${NC}"
fi
echo ""

# ============================================================================
# Schritt 3: Entferne den Flask-Container
# ============================================================================
echo -e "${YELLOW}[3/5]${NC} Entferne Flask-Container..."
if podman ps -a --filter "name=benning-flask" --format "{{.ID}}" | grep -q .; then
    podman rm -f benning-flask 2>/dev/null || true
    echo -e "${GREEN}✓ Flask-Container entfernt${NC}"
else
    echo -e "${YELLOW}⚠ Flask-Container nicht gefunden${NC}"
fi
echo ""

# ============================================================================
# Schritt 4: Starte Container neu
# ============================================================================
echo -e "${YELLOW}[4/5]${NC} Starte Container neu..."

# Überprüfe ob docker-compose.yml existiert
if [ -f "docker-compose.yml" ]; then
    echo "Verwende docker-compose.yml..."
    docker-compose up -d
    echo -e "${GREEN}✓ Container mit docker-compose gestartet${NC}"
# Überprüfe ob podman-compose.yml existiert
elif [ -f "podman-compose.yml" ]; then
    echo "Verwende podman-compose.yml..."
    podman-compose up -d
    echo -e "${GREEN}✓ Container mit podman-compose gestartet${NC}"
else
    echo -e "${RED}✗ Keine docker-compose.yml oder podman-compose.yml gefunden!${NC}"
    echo "Bitte stelle sicher, dass du dich im richtigen Verzeichnis befindest."
    exit 1
fi
echo ""

# ============================================================================
# Schritt 5: Überprüfe Status
# ============================================================================
echo -e "${YELLOW}[5/5]${NC} Überprüfe Container-Status..."
sleep 3
echo ""
echo "Container-Status:"
podman ps -a --format "table {{.Names}}\t{{.Status}}"
echo ""

# ============================================================================
# Abschluss
# ============================================================================
echo -e "${GREEN}✓ Restart abgeschlossen!${NC}"
echo ""
echo "Nächste Schritte:"
echo "1. Überprüfe die Logs: podman logs benning-flask"
echo "2. Teste die Anwendung: http://localhost:5000"
echo ""
echo "Bei Problemen führe aus:"
echo "  podman logs benning-flask"
echo "  podman ps -a"
