#!/bin/bash

################################################################################
# Hexagonal Architecture - Virtual Environment Setup Script
# Behebt Probleme mit alter venv und erstellt neue Python-Umgebung
#
# Verwendung: bash setup_hexagon_venv.sh [project_path]
# Beispiel:   bash setup_hexagon_venv.sh ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
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

# Funktionen
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

print_header "Hexagonal Architecture - Virtual Environment Setup"

# Schritt 1: Alte venv entfernen
print_info "Schritt 1: Alte Virtual Environment entfernen..."

if [ -d "$PROJECT_PATH/venv" ]; then
    print_warning "Alte venv gefunden: $PROJECT_PATH/venv"
    print_info "Entferne alte Virtual Environment..."
    
    # Versuche zu deaktivieren, falls aktiv
    if [ -n "$VIRTUAL_ENV" ]; then
        print_info "Deaktiviere aktuelle Virtual Environment..."
        deactivate 2>/dev/null || true
    fi
    
    # Entferne venv
    rm -rf "$PROJECT_PATH/venv"
    print_success "Alte venv entfernt"
else
    print_success "Keine alte venv gefunden"
fi

# Schritt 2: Python-Version überprüfen
print_info "Schritt 2: Python-Version überprüfen..."

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
    exit 1
fi

# Schritt 3: Neue venv erstellen
print_info "Schritt 3: Neue Virtual Environment erstellen..."

cd "$PROJECT_PATH"

# Erstelle venv mit --system-site-packages für Arch Linux Kompatibilität
$PYTHON_CMD -m venv venv --system-site-packages

if [ -f "$PROJECT_PATH/venv/bin/activate" ]; then
    print_success "Virtual Environment erstellt"
else
    print_error "Virtual Environment konnte nicht erstellt werden!"
    exit 1
fi

# Schritt 4: venv aktivieren und aktualisieren
print_info "Schritt 4: Virtual Environment aktivieren und aktualisieren..."

# Nutze direkt die Python-Binärdatei statt source
VENV_PYTHON="$PROJECT_PATH/venv/bin/python"
VENV_PIP="$PROJECT_PATH/venv/bin/pip"

# Überprüfe, ob venv funktioniert
if ! $VENV_PYTHON --version &>/dev/null; then
    print_error "Virtual Environment funktioniert nicht!"
    exit 1
fi

print_success "Virtual Environment funktioniert"

# Schritt 5: pip und setuptools aktualisieren
print_info "Schritt 5: pip und setuptools aktualisieren..."

$VENV_PIP install --upgrade pip setuptools wheel 2>&1 | grep -E "(Successfully|Requirement)" || true

print_success "pip und setuptools aktualisiert"

# Schritt 6: Requirements installieren
print_info "Schritt 6: Requirements installieren..."

if [ ! -f "$PROJECT_PATH/requirements_hexagon.txt" ]; then
    print_error "requirements_hexagon.txt nicht gefunden!"
    print_info "Stelle sicher, dass das Installationsskript zuerst ausgeführt wurde:"
    print_info "  bash install_hexagon_structure.sh $PROJECT_PATH"
    exit 1
fi

# Installiere mit --break-system-packages für Arch Linux
print_info "Installiere Python-Pakete..."
$VENV_PIP install -r "$PROJECT_PATH/requirements_hexagon.txt" --break-system-packages 2>&1 | tail -20

print_success "Alle Pakete installiert"

# Schritt 7: Überprüfe Installation
print_info "Schritt 7: Überprüfe Installation..."

# Überprüfe wichtige Pakete
PACKAGES=("flask" "mysql" "pytest" "python-dotenv")

for package in "${PACKAGES[@]}"; do
    if $VENV_PYTHON -c "import ${package//-/_}" 2>/dev/null; then
        print_success "Paket '$package' installiert"
    else
        print_warning "Paket '$package' nicht gefunden"
    fi
done

# Schritt 8: Erstelle Aktivierungsskript
print_info "Schritt 8: Erstelle Aktivierungsskript..."

cat > "$PROJECT_PATH/activate_venv.sh" << 'ACTIVATE_SCRIPT'
#!/bin/bash
# Aktivierungsskript für Hexagonal Architecture venv

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Virtual Environment nicht gefunden: $VENV_DIR"
    echo "Bitte führe zuerst aus:"
    echo "  bash setup_hexagon_venv.sh"
    exit 1
fi

# Aktiviere venv
source "$VENV_DIR/bin/activate"

echo "✓ Virtual Environment aktiviert"
echo "  Python: $(which python)"
echo "  pip: $(which pip)"
echo ""
echo "Verfügbare Befehle:"
echo "  python src/main.py       - Starte Anwendung"
echo "  pytest                   - Führe Tests aus"
echo "  deactivate              - Deaktiviere venv"
ACTIVATE_SCRIPT

chmod +x "$PROJECT_PATH/activate_venv.sh"
print_success "Aktivierungsskript erstellt: activate_venv.sh"

# Schritt 9: Erstelle Windows Batch-Datei
print_info "Schritt 9: Erstelle Windows-Aktivierungsdatei..."

cat > "$PROJECT_PATH/activate_venv.bat" << 'ACTIVATE_BATCH'
@echo off
REM Aktivierungsskript für Windows

set VENV_DIR=%~dp0venv

if not exist "%VENV_DIR%" (
    echo ❌ Virtual Environment nicht gefunden: %VENV_DIR%
    echo Bitte führe zuerst aus:
    echo   python -m venv venv
    exit /b 1
)

call "%VENV_DIR%\Scripts\activate.bat"

echo ✓ Virtual Environment aktiviert
echo   Python: %PYTHON%
echo   pip: %PIP%
echo.
echo Verfügbare Befehle:
echo   python src/main.py       - Starte Anwendung
echo   pytest                   - Führe Tests aus
echo   deactivate              - Deaktiviere venv
ACTIVATE_BATCH

print_success "Windows-Aktivierungsdatei erstellt: activate_venv.bat"

# Schritt 10: Erstelle Quick-Start Anleitung
print_info "Schritt 10: Erstelle Quick-Start Anleitung..."

cat > "$PROJECT_PATH/QUICKSTART.md" << 'QUICKSTART'
# Quick Start Guide - Hexagonal Architecture

## 🚀 Schneller Einstieg

### 1. Virtual Environment aktivieren

**Linux/Mac:**
```bash
source venv/bin/activate
# oder
bash activate_venv.sh
```

**Windows:**
```cmd
venv\Scripts\activate
# oder
activate_venv.bat
```

### 2. Umgebungsvariablen konfigurieren

```bash
cp .env.example .env
# Bearbeite .env mit deinen Einstellungen
```

### 3. Datenbank initialisieren

```bash
# Stelle sicher, dass MySQL läuft
mysql -u benning -p benning_device_manager < database/schema.sql
```

### 4. Anwendung starten

```bash
python src/main.py
```

Die Anwendung läuft unter `http://localhost:5000`

## 📝 Häufige Befehle

```bash
# Tests ausführen
pytest

# Tests mit Coverage
pytest --cov=src

# Code formatieren
black src/

# Linting
flake8 src/

# Type Checking
mypy src/

# Imports sortieren
isort src/
```

## 🐳 Mit Docker

```bash
# Build und Start
docker-compose up --build

# Nur Start
docker-compose up

# Logs anschauen
docker-compose logs -f app
```

## 📚 Dokumentation

- `README_HEXAGON.md` - Projekt-Übersicht
- `MIGRATION.md` - Migration vom alten Code
- `INSTALLATION_GUIDE.md` - Detaillierte Installation

## ❓ Fehlerbehebung

### Problem: "ModuleNotFoundError"

```bash
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

### Problem: "Datenbank-Verbindung fehlgeschlagen"

1. Überprüfe MySQL: `mysql -u root -p`
2. Überprüfe `.env` Datei
3. Überprüfe Datenbank: `SHOW DATABASES;`

### Problem: "Port 5000 bereits in Verwendung"

```bash
# Finde Prozess
lsof -i :5000

# Beende Prozess
kill -9 <PID>
```

## 🆘 Support

Bei Problemen siehe:
- `INSTALLATION_GUIDE.md` - Detaillierte Anleitung
- `README_HEXAGON.md` - Projekt-Dokumentation
- `tests/` - Beispiel-Tests
QUICKSTART

print_success "Quick-Start Anleitung erstellt: QUICKSTART.md"

# Abschluss
print_header "✨ Setup abgeschlossen!"

print_success "Virtual Environment erfolgreich eingerichtet"
print_info "Nächste Schritte:"
echo ""
echo "  1. Virtual Environment aktivieren:"
echo "     source venv/bin/activate  (Linux/Mac)"
echo "     venv\\Scripts\\activate    (Windows)"
echo ""
echo "  2. Umgebungsvariablen konfigurieren:"
echo "     cp .env.example .env"
echo ""
echo "  3. Anwendung starten:"
echo "     python src/main.py"
echo ""
echo "  4. Tests ausführen:"
echo "     pytest"
echo ""
print_info "Weitere Informationen:"
echo "  - QUICKSTART.md - Schneller Einstieg"
echo "  - README_HEXAGON.md - Projekt-Übersicht"
echo "  - INSTALLATION_GUIDE.md - Detaillierte Anleitung"
echo ""
