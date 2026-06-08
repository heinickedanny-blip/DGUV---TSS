#!/bin/bash

################################################################################
# Fix Routes - Behebt Dependency Injection Problem in Routes
#
# Verwendung: bash fix_routes.sh [project_path]
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

print_header "🔧 Fix Routes - Dependency Injection"

PROJECT_PATH="${1:-.}"

if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Verzeichnis nicht gefunden: $PROJECT_PATH"
    exit 1
fi

cd "$PROJECT_PATH"

# Überprüfe ob wir im richtigen Verzeichnis sind
if [ ! -d "src/adapters/web/routes" ]; then
    echo "❌ src/adapters/web/routes nicht gefunden!"
    exit 1
fi

print_success "Projektverzeichnis gefunden"

# Kopiere korrigierte Routes
print_info "Kopiere korrigierte device_routes.py..."
cp /home/ubuntu/device_routes_fixed.py src/adapters/web/routes/device_routes.py
print_success "device_routes.py aktualisiert"

print_header "✨ Routes repariert!"

echo -e "${YELLOW}Nächste Schritte:${NC}\n"

echo "  1. Starte Anwendung neu:"
echo "     ${YELLOW}bash run_app.sh${NC}"
echo ""

echo "  2. Teste API:"
echo "     ${YELLOW}curl http://localhost:5000/api/devices${NC}"
echo ""

echo "  3. Öffne Browser:"
echo "     ${YELLOW}http://localhost:5000${NC}"
echo ""
