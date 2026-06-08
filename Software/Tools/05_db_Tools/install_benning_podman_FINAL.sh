#!/bin/bash

# ============================================================================
# Benning Device Manager - Installation Script für Podman/CachyOS
# Mit optionalem Projekt-Pfad Parameter
# ============================================================================

set -e

echo ""
echo "🚀 Benning Device Manager - Podman Installation"
echo "================================================"
echo ""

# ANCHOR: Get project path from parameter or use current directory
PROJECT_PATH="${1:-.}"

# ANCHOR: Check if path exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Pfad nicht gefunden: $PROJECT_PATH"
    exit 1
fi

# ANCHOR: Change to project directory
cd "$PROJECT_PATH"

echo "📁 Projekt-Pfad: $(pwd)"
echo ""

# ANCHOR: Check if Podman is installed
if ! command -v podman &> /dev/null; then
    echo "❌ Podman nicht gefunden!"
    echo "   Bitte erst ausführen: bash install_podman_cachyos.sh"
    exit 1
fi

# ANCHOR: Check if podman-compose is installed
if ! command -v podman-compose &> /dev/null; then
    echo "❌ podman-compose nicht gefunden!"
    echo "   Bitte erst ausführen: bash install_podman_cachyos.sh"
    exit 1
fi

echo "✅ Podman ist installiert"
echo "   Version: $(podman --version)"
echo ""

# ANCHOR: Check if required files exist
if [ ! -f "Dockerfile.benning" ]; then
    echo "❌ Dockerfile.benning nicht gefunden!"
    echo "   Stelle sicher, dass du im korrekten Verzeichnis bist"
    exit 1
fi

if [ ! -f "podman-compose.yml" ]; then
    echo "❌ podman-compose.yml nicht gefunden!"
    exit 1
fi

echo "✅ Erforderliche Dateien gefunden"
echo ""

# ANCHOR: Create .env file if not exists
if [ ! -f .env ]; then
    echo "📝 Erstelle .env Datei..."
    cat > .env << 'EOF'
# Database Configuration
DB_HOST=mysql
DB_PORT=3306
DB_USER=benning
DB_PASSWORD=benning
DB_NAME=benning_device_manager
DB_ROOT_PASSWORD=root

# Flask Configuration
FLASK_ENV=production
FLASK_PORT=5000

# Application Configuration
APP_DEBUG=False
APP_WORKERS=4
EOF
    echo "✅ .env Datei erstellt"
else
    echo "✅ .env Datei existiert bereits"
fi

echo ""

# ANCHOR: Check if source files exist
if [ ! -d "src" ]; then
    echo "⚠️  Warnung: src/ Verzeichnis nicht gefunden"
    echo "   Stelle sicher, dass der Source-Code vorhanden ist"
    echo ""
fi

# ANCHOR: Build images
echo "🔨 Baue Docker Images..."
podman-compose build

echo ""

# ANCHOR: Stop existing containers if running
if podman ps -a | grep -q benning-flask; then
    echo "⏹️  Stoppe existierende Container..."
    podman-compose down
    sleep 2
fi

echo ""

# ANCHOR: Start services
echo "🚀 Starte Services..."
podman-compose up -d

echo ""

# ANCHOR: Wait for services to be ready
echo "⏳ Warte auf Services..."
sleep 5

# ANCHOR: Check service health
echo "🏥 Überprüfe Service-Status..."
echo ""

# Check MySQL
if podman ps | grep -q benning-mysql; then
    echo "✅ MySQL läuft"
else
    echo "❌ MySQL läuft nicht"
    podman-compose logs mysql
    exit 1
fi

# Check Flask
if podman ps | grep -q benning-flask; then
    echo "✅ Flask läuft"
else
    echo "❌ Flask läuft nicht"
    podman-compose logs flask
    exit 1
fi

echo ""

# ANCHOR: Show logs
echo "📋 Aktuelle Logs (letzte 20 Zeilen):"
echo ""
podman-compose logs --tail=20

echo ""
echo "================================================"
echo "✅ Installation abgeschlossen!"
echo "================================================"
echo ""
echo "🌐 Zugriff auf die Anwendung:"
echo "   URL: http://localhost:5000"
echo ""
echo "📊 Datenbank:"
echo "   Host: localhost"
echo "   Port: 3307"
echo "   User: benning"
echo "   Password: benning"
echo ""
echo "🛠️  Nützliche Befehle:"
echo "   Logs anzeigen:     podman-compose logs -f"
echo "   Services stoppen:  podman-compose down"
echo "   Services starten:  podman-compose up -d"
echo "   In Container:      podman exec -it benning-flask bash"
echo ""
echo "📍 Projekt-Verzeichnis: $(pwd)"
echo ""
echo "📚 Weitere Informationen:"
echo "   Siehe: PODMAN_SETUP.md"
echo ""
