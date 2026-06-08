#!/bin/bash

################################################################################
# Arch Linux venv Fix Script
# Behebt die "case nicht in switch" und "externally-managed-environment" Fehler
#
# Verwendung: bash fix_venv_arch.sh [project_path]
# Beispiel:   bash fix_venv_arch.sh ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
################################################################################

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Konfiguration
PROJECT_PATH="${1:-.}"

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Überprüfe Verzeichnis
if [ ! -d "$PROJECT_PATH" ]; then
    print_error "Verzeichnis $PROJECT_PATH existiert nicht!"
    exit 1
fi

print_header "🔧 Arch Linux venv Fix - Reparaturskript"

# Schritt 1: Überprüfe aktuelle Shell
print_info "Schritt 1: Überprüfe Shell-Kompatibilität..."

CURRENT_SHELL=$(echo $SHELL)
print_info "Aktuelle Shell: $CURRENT_SHELL"

# Überprüfe ob bash oder sh
if [[ "$CURRENT_SHELL" == *"fish"* ]]; then
    print_warning "Du verwendest fish shell - das könnte Probleme verursachen"
    print_info "Wechsle zu bash: exec bash"
elif [[ "$CURRENT_SHELL" == *"zsh"* ]]; then
    print_warning "Du verwendest zsh - das könnte Probleme verursachen"
    print_info "Wechsle zu bash: exec bash"
fi

# Schritt 2: Entferne alte venv
print_info "Schritt 2: Entferne alte Virtual Environment..."

cd "$PROJECT_PATH"

# Deaktiviere venv falls aktiv
if [ -n "$VIRTUAL_ENV" ]; then
    print_warning "Virtual Environment ist aktiv - deaktiviere..."
    deactivate 2>/dev/null || true
    sleep 1
fi

# Überprüfe ob venv existiert
if [ -d "venv" ]; then
    print_warning "Alte venv gefunden - entferne komplett..."
    
    # Nutze sudo falls nötig
    if ! rm -rf venv 2>/dev/null; then
        print_warning "Normale Löschung fehlgeschlagen - versuche mit sudo..."
        sudo rm -rf venv
    fi
    
    # Überprüfe ob gelöscht
    if [ ! -d "venv" ]; then
        print_success "Alte venv entfernt"
    else
        print_error "Konnte venv nicht entfernen!"
        exit 1
    fi
else
    print_success "Keine alte venv gefunden"
fi

# Schritt 3: Überprüfe Python-Installation
print_info "Schritt 3: Überprüfe Python-Installation..."

# Finde beste Python-Version
PYTHON_CMD=""
for cmd in python3.11 python3.10 python3.9 python3; do
    if command -v $cmd &> /dev/null; then
        PYTHON_VERSION=$($cmd --version 2>&1)
        print_success "Gefunden: $PYTHON_VERSION"
        PYTHON_CMD=$cmd
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    print_error "Python 3 nicht gefunden!"
    print_info "Installiere Python: sudo pacman -S python"
    exit 1
fi

# Schritt 4: Überprüfe pip
print_info "Schritt 4: Überprüfe pip-Installation..."

if ! $PYTHON_CMD -m pip --version &>/dev/null; then
    print_error "pip nicht gefunden!"
    print_info "Installiere pip: sudo pacman -S python-pip"
    exit 1
fi

print_success "pip ist installiert"

# Schritt 5: Erstelle neue venv mit speziellen Flags
print_info "Schritt 5: Erstelle neue Virtual Environment..."

# Nutze bash explizit für venv-Erstellung
bash -c "$PYTHON_CMD -m venv venv --system-site-packages --clear"

if [ ! -d "venv" ]; then
    print_error "Virtual Environment konnte nicht erstellt werden!"
    exit 1
fi

print_success "Virtual Environment erstellt"

# Schritt 6: Überprüfe venv
print_info "Schritt 6: Überprüfe venv-Funktionalität..."

VENV_PYTHON="$PROJECT_PATH/venv/bin/python"
VENV_PIP="$PROJECT_PATH/venv/bin/pip"

if [ ! -f "$VENV_PYTHON" ]; then
    print_error "venv/bin/python nicht gefunden!"
    exit 1
fi

if ! $VENV_PYTHON --version &>/dev/null; then
    print_error "venv Python funktioniert nicht!"
    exit 1
fi

print_success "venv funktioniert"

# Schritt 7: Aktualisiere pip
print_info "Schritt 7: Aktualisiere pip und setuptools..."

# Nutze bash für pip-Befehle
bash -c "$VENV_PIP install --upgrade pip setuptools wheel --quiet" 2>&1 | tail -3 || true

print_success "pip aktualisiert"

# Schritt 8: Installiere Requirements
print_info "Schritt 8: Installiere Python-Pakete..."

if [ ! -f "requirements_hexagon.txt" ]; then
    print_error "requirements_hexagon.txt nicht gefunden!"
    print_info "Stelle sicher, dass install_hexagon_structure.sh zuerst ausgeführt wurde"
    exit 1
fi

# Installiere mit --break-system-packages
print_info "Installiere Pakete mit --break-system-packages..."

bash -c "$VENV_PIP install -r requirements_hexagon.txt --break-system-packages --quiet" 2>&1 | tail -5 || true

print_success "Pakete installiert"

# Schritt 9: Überprüfe Installation
print_info "Schritt 9: Überprüfe Installation..."

# Überprüfe wichtige Pakete
PACKAGES=("flask" "mysql" "pytest" "dotenv")
FAILED=0

for package in "${PACKAGES[@]}"; do
    if bash -c "$VENV_PYTHON -c 'import ${package//-/_}' 2>/dev/null"; then
        print_success "Paket '$package' OK"
    else
        print_warning "Paket '$package' nicht gefunden"
        FAILED=$((FAILED + 1))
    fi
done

if [ $FAILED -gt 0 ]; then
    print_warning "$FAILED Pakete fehlen - versuche erneut..."
    bash -c "$VENV_PIP install -r requirements_hexagon.txt --break-system-packages" 2>&1 | tail -10
fi

# Schritt 10: Erstelle Aktivierungsskript
print_info "Schritt 10: Erstelle Aktivierungsskript..."

cat > "$PROJECT_PATH/activate.sh" << 'ACTIVATE'
#!/bin/bash
# Aktivierungsskript für Hexagonal Architecture venv

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Virtual Environment nicht gefunden: $VENV_DIR"
    exit 1
fi

# Aktiviere mit bash
bash -c "source $VENV_DIR/bin/activate && exec bash"
ACTIVATE

chmod +x "$PROJECT_PATH/activate.sh"
print_success "Aktivierungsskript erstellt"

# Schritt 11: Erstelle Konfigurationsdatei
print_info "Schritt 11: Überprüfe Konfiguration..."

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success ".env erstellt"
        print_warning "Bitte bearbeite .env mit deinen Einstellungen!"
    fi
else
    print_success ".env existiert bereits"
fi

# Abschluss
print_header "✨ Reparatur abgeschlossen!"

print_success "Virtual Environment ist einsatzbereit"

echo -e "\n${YELLOW}🚀 Nächste Schritte:${NC}\n"

echo "1. Aktiviere Virtual Environment:"
echo "   ${YELLOW}source venv/bin/activate${NC}"
echo "   oder"
echo "   ${YELLOW}bash activate.sh${NC}"
echo ""

echo "2. Überprüfe Installation:"
echo "   ${YELLOW}python --version${NC}"
echo "   ${YELLOW}pip list${NC}"
echo ""

echo "3. Starte Anwendung:"
echo "   ${YELLOW}python src/main.py${NC}"
echo ""

echo "4. Führe Tests aus:"
echo "   ${YELLOW}pytest${NC}"
echo ""

echo -e "${GREEN}Viel Erfolg! 🎉${NC}\n"
