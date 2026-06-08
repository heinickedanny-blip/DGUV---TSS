#!/bin/bash

# ============================================================================
# Benning Device Manager - Podman Installation für CachyOS
# ============================================================================
# Installiert Podman und alle notwendigen Tools für CachyOS

set -e

echo ""
echo "🚀 Benning Device Manager - Podman Setup für CachyOS"
echo "======================================================"
echo ""

# ANCHOR: Check if running on CachyOS
if ! grep -q "CachyOS" /etc/os-release 2>/dev/null; then
    echo "⚠️  Warnung: Dieses Script ist für CachyOS optimiert"
    echo "   Es kann auch auf anderen Arch-basierten Systemen funktionieren"
    echo ""
fi

# ANCHOR: Update system
echo "📦 Aktualisiere Paketmanager..."
sudo pacman -Sy

# ANCHOR: Install Podman
echo "📦 Installiere Podman..."
sudo pacman -S --noconfirm podman podman-compose

# ANCHOR: Install additional tools
echo "📦 Installiere zusätzliche Tools..."
sudo pacman -S --noconfirm \
    git \
    curl \
    wget \
    vim \
    htop

# ANCHOR: Enable Podman socket (für rootless mode)
echo "🔧 Konfiguriere Podman..."
systemctl --user enable podman.socket
systemctl --user start podman.socket

# ANCHOR: Set Podman to use rootless mode
echo "🔐 Aktiviere Rootless Mode..."
sudo usermod --add-subuids 100000-165535 $(whoami)
sudo usermod --add-subgids 100000-165535 $(whoami)

# ANCHOR: Verify installation
echo ""
echo "✅ Überprüfe Installation..."
podman --version
podman-compose --version

echo ""
echo "✅ Podman erfolgreich installiert!"
echo ""
echo "🎯 Nächste Schritte:"
echo "  1. Projekt klonen: git clone https://github.com/ydh-embedded/Benning---DGUV3.git"
echo "  2. Zum Projekt: cd Benning---DGUV3/Software/PRG"
echo "  3. Container starten: bash install_benning_podman.sh"
echo ""
