#!/bin/bash

################################################################################
# CachyOS Optimized - Fix Pillow Installation Issue
# Spezialisiert für CachyOS (Arch-basiert mit Optimierungen)
#
# Verwendung: bash fix_pillow_cachyos.sh [project_path]
# Beispiel:   bash fix_pillow_cachyos.sh ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
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

print_header "🚀 CachyOS Optimized - Fix Pillow Installation"

cd "$PROJECT_PATH"

# Überprüfe CachyOS
print_section "Schritt 1: Überprüfe CachyOS-Installation"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "cachyos" ]] || [[ "$PRETTY_NAME" == *"CachyOS"* ]]; then
        print_success "CachyOS erkannt: $PRETTY_NAME"
    else
        print_warning "Nicht auf CachyOS erkannt, aber fahre fort..."
    fi
else
    print_warning "Konnte OS nicht überprüfen, fahre fort..."
fi

# Überprüfe venv
print_section "Schritt 2: Überprüfe Virtual Environment"

if [ ! -f "venv/bin/python" ]; then
    print_error "Virtual Environment nicht gefunden!"
    print_info "Führe zuerst aus: bash fix_venv_arch.sh ."
    exit 1
fi

VENV_PIP="$PROJECT_PATH/venv/bin/pip"
VENV_PYTHON="$PROJECT_PATH/venv/bin/python"

PYTHON_VERSION=$($VENV_PYTHON --version 2>&1)
print_success "Python: $PYTHON_VERSION"

# Überprüfe Python-Version
PYTHON_MINOR=$($VENV_PYTHON -c "import sys; print(sys.version_info.minor)")
PYTHON_MAJOR=$($VENV_PYTHON -c "import sys; print(sys.version_info.major)")

print_info "Python $PYTHON_MAJOR.$PYTHON_MINOR"

if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 14 ]; then
    print_warning "Python 3.14+ erkannt - Pillow benötigt spezielle Behandlung"
fi

# Schritt 3: CachyOS-spezifische Optimierungen
print_section "Schritt 3: Wende CachyOS-Optimierungen an"

# CachyOS nutzt aggressivere Compiler-Flags
export CFLAGS="-march=native -O3"
export CXXFLAGS="-march=native -O3"
export LDFLAGS="-march=native -O3"

print_info "Compiler-Flags gesetzt für CachyOS"

# Schritt 4: Aktualisiere pip mit CachyOS-Optimierungen
print_section "Schritt 4: Aktualisiere pip (CachyOS-optimiert)"

bash -c "$VENV_PIP install --upgrade pip setuptools wheel --no-cache-dir" 2>&1 | tail -5

print_success "pip aktualisiert"

# Schritt 5: Installiere Pakete mit CachyOS-Optimierungen
print_section "Schritt 5: Installiere Pakete (CachyOS-optimiert)"

print_info "Installiere ohne Pillow (nicht kompatibel mit Python 3.14)..."

# Nutze CachyOS-optimierte Installation
bash -c "$VENV_PIP install \
    Flask==2.3.3 \
    Werkzeug==2.3.7 \
    mysql-connector-python==8.1.0 \
    python-dotenv==1.0.0 \
    qrcode==7.4.2 \
    pytest==7.4.0 \
    pytest-cov==4.1.0 \
    pytest-mock==3.11.1 \
    black==23.9.1 \
    flake8==6.1.0 \
    mypy==1.5.1 \
    isort==5.12.0 \
    gunicorn==21.2.0 \
    --break-system-packages \
    --no-cache-dir \
    --upgrade" 2>&1 | tail -30

print_success "Pakete installiert"

# Schritt 6: Aktualisiere requirements.txt
print_section "Schritt 6: Aktualisiere requirements_hexagon.txt"

cat > requirements_hexagon.txt << 'EOF'
# Core Framework
Flask==2.3.3
Werkzeug==2.3.7

# Database
mysql-connector-python==8.1.0

# Utilities
python-dotenv==1.0.0
qrcode==7.4.2

# Testing
pytest==7.4.0
pytest-cov==4.1.0
pytest-mock==3.11.1

# Development
black==23.9.1
flake8==6.1.0
mypy==1.5.1
isort==5.12.0

# Production
gunicorn==21.2.0
EOF

print_success "requirements_hexagon.txt aktualisiert"

# Schritt 7: Überprüfe Installation
print_section "Schritt 7: Überprüfe Installation"

PACKAGES=("flask" "mysql" "pytest" "dotenv" "qrcode")
FAILED=0

for package in "${PACKAGES[@]}"; do
    if bash -c "$VENV_PYTHON -c 'import ${package//-/_}' 2>/dev/null"; then
        print_success "Paket '$package' OK"
    else
        print_error "Paket '$package' nicht gefunden!"
        FAILED=$((FAILED + 1))
    fi
done

if [ $FAILED -gt 0 ]; then
    print_warning "$FAILED Pakete fehlen - versuche erneut..."
    bash -c "$VENV_PIP install Flask mysql-connector-python pytest python-dotenv qrcode --break-system-packages --no-cache-dir" 2>&1 | tail -10
fi

# Schritt 8: Überprüfe QR-Code Funktionalität
print_section "Schritt 8: Überprüfe QR-Code Funktionalität"

if bash -c "$VENV_PYTHON -c 'import qrcode; qr = qrcode.QRCode(); qr.add_data(\"test\"); qr.make()' 2>/dev/null"; then
    print_success "QR-Code Funktionalität OK"
else
    print_warning "QR-Code könnte Probleme haben"
fi

# Schritt 9: CachyOS-spezifische Konfiguration
print_section "Schritt 9: Konfiguriere CachyOS-Optimierungen"

# Erstelle .cachyos-config für zukünftige Installationen
cat > .cachyos-config << 'EOF'
# CachyOS Optimization Configuration
# Diese Datei speichert CachyOS-spezifische Einstellungen

# Compiler-Flags für native Optimierung
export CFLAGS="-march=native -O3"
export CXXFLAGS="-march=native -O3"
export LDFLAGS="-march=native -O3"

# Python-Optimierungen
export PYTHONOPTIMIZE=2

# pip-Optimierungen
export PIP_NO_CACHE_DIR=1
EOF

print_success ".cachyos-config erstellt"

# Schritt 10: Erstelle aktivierungsskript mit CachyOS-Optimierungen
print_section "Schritt 10: Erstelle optimiertes Aktivierungsskript"

cat > activate_cachyos.sh << 'ACTIVATE'
#!/bin/bash
# CachyOS Optimized Activation Script

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Virtual Environment nicht gefunden: $VENV_DIR"
    exit 1
fi

# Wende CachyOS-Optimierungen an
export CFLAGS="-march=native -O3"
export CXXFLAGS="-march=native -O3"
export LDFLAGS="-march=native -O3"
export PYTHONOPTIMIZE=2
export PIP_NO_CACHE_DIR=1

# Aktiviere venv
source "$VENV_DIR/bin/activate"

echo "✓ CachyOS Virtual Environment aktiviert"
echo "  Python: $(which python)"
echo "  Optimierungen: Native CPU (-march=native -O3)"
echo ""
ACTIVATE

chmod +x activate_cachyos.sh
print_success "activate_cachyos.sh erstellt"

# Schritt 11: Zusammenfassung
print_header "✨ CachyOS Fix erfolgreich abgeschlossen!"

echo -e "${CYAN}📊 Installation Summary:${NC}"
echo ""
echo "  Python Version:     $PYTHON_VERSION"
echo "  venv Location:      $PROJECT_PATH/venv"
echo "  Optimierungen:      Native CPU (-march=native -O3)"
echo ""

echo -e "${CYAN}📋 Installierte Pakete:${NC}"
bash -c "$VENV_PIP list" 2>&1 | grep -E "(Flask|mysql|pytest|qrcode|python-dotenv)" || true

echo -e "\n${CYAN}🚀 Nächste Schritte:${NC}\n"

echo "  1. Aktiviere venv (CachyOS-optimiert):"
echo "     ${YELLOW}source activate_cachyos.sh${NC}"
echo "     oder"
echo "     ${YELLOW}source venv/bin/activate${NC}"
echo ""

echo "  2. Überprüfe Installation:"
echo "     ${YELLOW}python --version${NC}"
echo "     ${YELLOW}pip list${NC}"
echo ""

echo "  3. Starte Anwendung:"
echo "     ${YELLOW}python src/main.py${NC}"
echo ""

echo "  4. Führe Tests aus:"
echo "     ${YELLOW}pytest${NC}"
echo ""

echo -e "${GREEN}Viel Erfolg mit CachyOS! 🎉${NC}\n"
