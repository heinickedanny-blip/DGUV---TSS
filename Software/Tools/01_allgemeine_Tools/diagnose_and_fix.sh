#!/bin/bash

################################################################################
# Diagnose & Fix - venv und Pakete
# Überprüft und repariert venv-Probleme
#
# Verwendung: bash diagnose_and_fix.sh
################################################################################

set -e

# Farben
RED='\033[0;31m'
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

print_section() {
    echo -e "\n${BLUE}▶ $1${NC}"
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

print_header "🔍 Diagnose & Fix - venv und Pakete"

# ═══════════════════════════════════════════════════════════════════════════
# DIAGNOSE
# ═══════════════════════════════════════════════════════════════════════════

print_section "Diagnose durchführen"

# Überprüfe aktuelles Verzeichnis
print_info "Aktuelles Verzeichnis: $(pwd)"

if [ ! -d "venv" ]; then
    print_error "venv-Verzeichnis nicht gefunden!"
    exit 1
fi

print_success "venv-Verzeichnis gefunden"

# Überprüfe Python
if [ ! -f "venv/bin/python" ]; then
    print_error "venv/bin/python nicht gefunden!"
    exit 1
fi

VENV_PYTHON="venv/bin/python"
VENV_PIP="venv/bin/pip"

print_success "Python in venv: $($VENV_PYTHON --version 2>&1)"

# Überprüfe pip
if [ ! -f "$VENV_PIP" ]; then
    print_error "pip nicht gefunden!"
    exit 1
fi

print_success "pip in venv: $($VENV_PIP --version 2>&1)"

# Überprüfe installierte Pakete
print_section "Überprüfe installierte Pakete"

PACKAGES=("flask" "mysql" "pytest" "dotenv" "qrcode")
MISSING=()

for package in "${PACKAGES[@]}"; do
    if $VENV_PYTHON -c "import ${package//-/_}" 2>/dev/null; then
        print_success "Paket '$package' installiert"
    else
        print_error "Paket '$package' FEHLT!"
        MISSING+=("$package")
    fi
done

# ═══════════════════════════════════════════════════════════════════════════
# REPARATUR
# ═══════════════════════════════════════════════════════════════════════════

if [ ${#MISSING[@]} -eq 0 ]; then
    print_header "✨ Alles OK!"
    echo "Alle Pakete sind installiert."
    echo ""
    echo "Starte Anwendung mit:"
    echo "  ${YELLOW}python src/main.py${NC}"
    echo ""
    exit 0
fi

print_section "Repariere fehlende Pakete"

print_info "Fehlende Pakete: ${MISSING[*]}"

# Aktualisiere pip
print_info "Aktualisiere pip..."
$VENV_PIP install --upgrade pip setuptools wheel --no-cache-dir --quiet 2>&1 | tail -3
print_success "pip aktualisiert"

# Installiere fehlende Pakete
print_info "Installiere fehlende Pakete..."

PACKAGES_TO_INSTALL=(
    "Flask==2.3.3"
    "Werkzeug==2.3.7"
    "mysql-connector-python==8.1.0"
    "python-dotenv==1.0.0"
    "qrcode==7.4.2"
    "pytest==7.4.0"
    "pytest-cov==4.1.0"
    "pytest-mock==3.11.1"
    "black==23.9.1"
    "flake8==6.1.0"
    "mypy==1.5.1"
    "isort==5.12.0"
    "gunicorn==21.2.0"
)

for package in "${PACKAGES_TO_INSTALL[@]}"; do
    print_info "Installiere $package..."
    $VENV_PIP install "$package" \
        --break-system-packages \
        --no-cache-dir \
        --upgrade \
        --quiet 2>&1 | tail -1 || true
done

print_success "Pakete installiert"

# ═══════════════════════════════════════════════════════════════════════════
# ÜBERPRÜFUNG
# ═══════════════════════════════════════════════════════════════════════════

print_section "Überprüfe Installation erneut"

FAILED=0

for package in "${PACKAGES[@]}"; do
    if $VENV_PYTHON -c "import ${package//-/_}" 2>/dev/null; then
        print_success "Paket '$package' OK"
    else
        print_error "Paket '$package' FEHLT!"
        FAILED=$((FAILED + 1))
    fi
done

# ═══════════════════════════════════════════════════════════════════════════
# ABSCHLUSS
# ═══════════════════════════════════════════════════════════════════════════

if [ $FAILED -eq 0 ]; then
    print_header "✨ Reparatur erfolgreich!"
    
    echo -e "${YELLOW}Nächste Schritte:${NC}\n"
    echo "  1. Aktiviere venv erneut:"
    echo "     ${YELLOW}source activate_cachyos.sh${NC}"
    echo ""
    echo "  2. Starte Anwendung:"
    echo "     ${YELLOW}python src/main.py${NC}"
    echo ""
    echo "  3. Öffne Browser:"
    echo "     ${YELLOW}http://localhost:5000${NC}"
    echo ""
else
    print_error "$FAILED Pakete konnten nicht installiert werden!"
    print_info "Versuche manuelle Installation..."
    
    $VENV_PIP install \
        Flask \
        mysql-connector-python \
        python-dotenv \
        qrcode \
        pytest \
        --break-system-packages \
        --no-cache-dir \
        --upgrade \
        2>&1 | tail -20
fi

echo ""
