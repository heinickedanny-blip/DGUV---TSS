#!/bin/bash

################################################################################
# Apply Fixes - Wendet alle Fixes auf das Projektverzeichnis an
#
# Verwendung: bash apply_fixes.sh [project_path]
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

print_header "🔧 Apply Fixes"

PROJECT_PATH="${1:-.}"

if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Verzeichnis nicht gefunden: $PROJECT_PATH"
    exit 1
fi

cd "$PROJECT_PATH"

# Überprüfe ob wir im richtigen Verzeichnis sind
if [ ! -d "src" ]; then
    echo "❌ src-Verzeichnis nicht gefunden!"
    echo "Stelle sicher, dass du im Projektverzeichnis bist"
    exit 1
fi

print_success "Projektverzeichnis gefunden"

# Kopiere fixed main.py
print_info "Kopiere korrigiertes main.py..."
cp /home/ubuntu/main_fixed.py src/main.py
print_success "src/main.py aktualisiert"

# Kopiere run_app.sh
print_info "Kopiere run_app.sh..."
cp /home/ubuntu/run_app.sh run_app.sh
chmod +x run_app.sh
print_success "run_app.sh kopiert"

# Kopiere fish-Aktivierungsskript falls nicht vorhanden
if [ ! -f "activate_cachyos.fish" ]; then
    print_info "Kopiere activate_cachyos.fish..."
    cp /home/ubuntu/activate_cachyos.fish activate_cachyos.fish
    print_success "activate_cachyos.fish kopiert"
else
    print_info "activate_cachyos.fish existiert bereits"
fi

print_header "✨ Fixes angewendet!"

echo -e "${YELLOW}Nächste Schritte:${NC}\n"

echo "  1. Aktiviere venv (falls nicht aktiv):"
echo "     ${YELLOW}source activate_cachyos.fish${NC}"
echo ""

echo "  2. Starte Anwendung:"
echo "     ${YELLOW}bash run_app.sh${NC}"
echo ""

echo "  3. Öffne Browser:"
echo "     ${YELLOW}http://localhost:5000${NC}"
echo ""

echo -e "${YELLOW}Oder direkt:${NC}\n"

echo "     ${YELLOW}source activate_cachyos.fish && bash run_app.sh${NC}"
echo ""
