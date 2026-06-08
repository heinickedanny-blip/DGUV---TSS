#!/bin/bash

# MariaDB Repair and Initialization Script for CachyOS
# Dieses Skript repariert eine fehlerhafte MariaDB-Installation

set -e  # Exit on error

echo "================================================"
echo "MariaDB Database Repair and Initialization"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Dieses Skript muss als root oder mit sudo ausgeführt werden${NC}"
   exit 1
fi

echo -e "${YELLOW}[1/5]${NC} Stoppe MariaDB Service..."
systemctl stop mariadb || true
sleep 2
echo -e "${GREEN}✓ Service gestoppt${NC}"
echo ""

echo -e "${YELLOW}[2/5]${NC} Lösche alte Datenbankdateien..."
if [ -d "/var/lib/mysql" ]; then
    rm -rf /var/lib/mysql/*
    echo -e "${GREEN}✓ Alte Dateien gelöscht${NC}"
else
    echo -e "${YELLOW}⚠ Verzeichnis existiert nicht, wird erstellt${NC}"
    mkdir -p /var/lib/mysql
fi
echo ""

echo -e "${YELLOW}[3/5]${NC} Setze korrekte Permissions..."
chown -R mysql:mysql /var/lib/mysql
chmod 700 /var/lib/mysql
echo -e "${GREEN}✓ Permissions gesetzt${NC}"
echo ""

echo -e "${YELLOW}[4/5]${NC} Initialisiere MariaDB Datenbank..."
mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
echo -e "${GREEN}✓ Datenbank initialisiert${NC}"
echo ""

echo -e "${YELLOW}[5/5]${NC} Starte MariaDB Service..."
systemctl start mariadb
sleep 3

# Check if service is running
if systemctl is-active --quiet mariadb; then
    echo -e "${GREEN}✓ MariaDB Service läuft${NC}"
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}✓ Reparatur erfolgreich abgeschlossen!${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo "Nächste Schritte:"
    echo "1. Sicher deine Installation: sudo mariadb-secure-installation"
    echo "2. Überprüfe den Status: sudo systemctl status mariadb"
    echo "3. Verbinde dich mit MariaDB: sudo mariadb -u root"
    echo ""
else
    echo -e "${RED}✗ MariaDB Service läuft nicht!${NC}"
    echo "Überprüfe die Logs mit:"
    echo "  sudo journalctl -xeu mariadb.service --lines=50"
    exit 1
fi
