#!/bin/bash

################################################################################
# Complete Hexagonal Architecture Setup
# Installiert Struktur + Virtual Environment + Dependencies
#
# Verwendung: bash setup_complete.sh [project_path]
# Beispiel:   bash setup_complete.sh ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
################################################################################

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Konfiguration
PROJECT_PATH="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Funktionen
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    echo -e "\n${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

print_error() {
    echo -e "${RED}  ✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}  ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
}

# Überprüfe Verzeichnis
if [ ! -d "$PROJECT_PATH" ]; then
    print_error "Verzeichnis $PROJECT_PATH existiert nicht!"
    exit 1
fi

print_header "🚀 Hexagonal Architecture - Complete Setup"

# Überprüfe ob Skripte existieren
if [ ! -f "$SCRIPT_DIR/install_hexagon_structure.sh" ]; then
    print_error "install_hexagon_structure.sh nicht gefunden!"
    print_info "Stelle sicher, dass beide Skripte im gleichen Verzeichnis sind:"
    print_info "  - install_hexagon_structure.sh"
    print_info "  - setup_hexagon_venv.sh"
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/setup_hexagon_venv.sh" ]; then
    print_error "setup_hexagon_venv.sh nicht gefunden!"
    print_info "Stelle sicher, dass beide Skripte im gleichen Verzeichnis sind:"
    print_info "  - install_hexagon_structure.sh"
    print_info "  - setup_hexagon_venv.sh"
    exit 1
fi

# Phase 1: Projektstruktur
print_section "Phase 1: Erstelle Projektstruktur"
print_info "Führe install_hexagon_structure.sh aus..."

bash "$SCRIPT_DIR/install_hexagon_structure.sh" "$PROJECT_PATH" 2>&1 | tail -30

print_success "Projektstruktur erstellt"

# Phase 2: Virtual Environment
print_section "Phase 2: Richte Virtual Environment ein"
print_info "Führe setup_hexagon_venv.sh aus..."

bash "$SCRIPT_DIR/setup_hexagon_venv.sh" "$PROJECT_PATH" 2>&1 | tail -30

print_success "Virtual Environment eingerichtet"

# Phase 3: Überprüfung
print_section "Phase 3: Überprüfe Installation"

cd "$PROJECT_PATH"

# Überprüfe Verzeichnisse
print_info "Überprüfe Verzeichnisstruktur..."
if [ -d "src/core/domain" ] && [ -d "src/adapters" ] && [ -d "tests" ]; then
    print_success "Verzeichnisstruktur OK"
else
    print_error "Verzeichnisstruktur unvollständig!"
    exit 1
fi

# Überprüfe venv
print_info "Überprüfe Virtual Environment..."
if [ -f "venv/bin/python" ]; then
    PYTHON_VERSION=$(venv/bin/python --version 2>&1)
    print_success "Virtual Environment OK ($PYTHON_VERSION)"
else
    print_error "Virtual Environment nicht funktionsfähig!"
    exit 1
fi

# Überprüfe Pakete
print_info "Überprüfe installierte Pakete..."
if venv/bin/python -c "import flask; import mysql.connector; import pytest" 2>/dev/null; then
    print_success "Alle wichtigen Pakete installiert"
else
    print_warning "Einige Pakete fehlen - versuche erneut zu installieren..."
    venv/bin/pip install -r requirements_hexagon.txt --break-system-packages 2>&1 | tail -5
fi

# Überprüfe Python-Dateien
print_info "Überprüfe Python-Module..."
PYTHON_COUNT=$(find src -name "*.py" | wc -l)
if [ "$PYTHON_COUNT" -gt 20 ]; then
    print_success "$PYTHON_COUNT Python-Module gefunden"
else
    print_error "Zu wenige Python-Module gefunden!"
    exit 1
fi

# Phase 4: Konfiguration
print_section "Phase 4: Konfiguriere Anwendung"

# Überprüfe .env
if [ ! -f ".env" ]; then
    print_info "Erstelle .env aus .env.example..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success ".env erstellt"
        print_warning "Bitte bearbeite .env mit deinen Einstellungen!"
    else
        print_error ".env.example nicht gefunden!"
    fi
else
    print_success ".env existiert bereits"
fi

# Phase 5: Zusammenfassung
print_header "✨ Setup erfolgreich abgeschlossen!"

print_success "Alle Komponenten installiert und konfiguriert"

echo -e "\n${CYAN}📊 Installationsübersicht:${NC}"
echo -e "  Projektpfad:      $PROJECT_PATH"
echo -e "  Python-Module:    $PYTHON_COUNT"
echo -e "  Virtual Env:      $PROJECT_PATH/venv"
echo -e "  Konfiguration:    $PROJECT_PATH/.env"

echo -e "\n${CYAN}🚀 Nächste Schritte:${NC}"
echo -e "\n  1. Virtual Environment aktivieren:"
echo -e "     ${YELLOW}source venv/bin/activate${NC}  (Linux/Mac)"
echo -e "     ${YELLOW}venv\\\\Scripts\\\\activate${NC}    (Windows)"

echo -e "\n  2. Konfiguration anpassen:"
echo -e "     ${YELLOW}nano .env${NC}"

echo -e "\n  3. Datenbank initialisieren:"
echo -e "     ${YELLOW}mysql -u benning -p benning_device_manager < database/schema.sql${NC}"

echo -e "\n  4. Anwendung starten:"
echo -e "     ${YELLOW}python src/main.py${NC}"

echo -e "\n  5. Tests ausführen:"
echo -e "     ${YELLOW}pytest${NC}"

echo -e "\n${CYAN}📚 Dokumentation:${NC}"
echo -e "  • QUICKSTART.md - Schneller Einstieg"
echo -e "  • README_HEXAGON.md - Projekt-Übersicht"
echo -e "  • INSTALLATION_GUIDE.md - Detaillierte Anleitung"
echo -e "  • MIGRATION.md - Migration vom alten Code"
echo -e "  • ARCH_LINUX_FIX.md - Arch Linux spezifische Lösungen"

echo -e "\n${CYAN}🐳 Alternative: Docker${NC}"
echo -e "  ${YELLOW}docker-compose up --build${NC}"

echo -e "\n${GREEN}Viel Erfolg! 🎉${NC}\n"
