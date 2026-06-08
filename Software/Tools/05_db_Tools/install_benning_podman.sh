#!/bin/bash

# ============================================================================
# Benning Device Manager - Installation Script für Podman/CachyOS
# ============================================================================

set -e

echo ""
echo "🚀 Benning Device Manager - Podman Installation"
echo "================================================"
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

# ANCHOR: Build images
echo "🔨 Baue Docker Images..."
podman-compose build

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
echo "📋 Aktuelle Logs:"
echo ""
podman-compose logs -f --tail=20 &
LOGS_PID=$!

# ANCHOR: Wait a bit for logs to show
sleep 3

# ANCHOR: Kill logs process
kill $LOGS_PID 2>/dev/null || true

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
echo "📚 Weitere Informationen:"
echo "   Siehe: PODMAN_SETUP.md"
echo ""
