#!/bin/bash

# ============================================================================
# Benning Device Manager - Datenbank Reset Script
# ============================================================================
# Dieses Script setzt die Datenbank zurück und erstellt eine saubere Umgebung
# für Tests mit curl
# ============================================================================

set -e  # Exit on error

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# KONFIGURATION
# ============================================================================

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3307}"
DB_USER="${DB_USER:-root}"
DB_NAME="benning_device_manager"
SCHEMA_FILE="/home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG/schema.sql"

# ============================================================================
# FUNKTIONEN
# ============================================================================

print_header() {
    echo -e "${BLUE}========================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# HAUPTLOGIK
# ============================================================================

print_header "Benning Device Manager - Datenbank Reset"

# Prüfe ob Schema-Datei existiert
if [ ! -f "$SCHEMA_FILE" ]; then
    print_error "Schema-Datei nicht gefunden: $SCHEMA_FILE"
    exit 1
fi

print_info "Datenbankverbindung: $DB_HOST:$DB_PORT (Container)"
print_info "Datenbankbenutzer: $DB_USER"
print_info "Datenbankname: $DB_NAME"
print_info "Hinweis: MySQL läuft im Container auf Port 3307"

# Frage nach Bestätigung
echo ""
read -p "Möchtest du die Datenbank wirklich zurücksetzen? (ja/nein): " confirm
if [ "$confirm" != "ja" ]; then
    print_warning "Abgebrochen"
    exit 0
fi

# ============================================================================
# Datenbank löschen und neu erstellen
# ============================================================================

print_header "Schritt 1: Datenbank zurücksetzen"

# Lese Passwort vom Benutzer (sicher)
read -sp "MySQL Root-Passwort: " DB_PASSWORD
echo ""

# Löschen und neu erstellen
echo "Verbinde zu MySQL Container..."
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" 2>/dev/null << EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

if [ $? -eq 0 ]; then
    print_success "Datenbank gelöscht und neu erstellt"
else
    print_error "Fehler beim Löschen/Erstellen der Datenbank"
    exit 1
fi

# ============================================================================
# Schema importieren
# ============================================================================

print_header "Schritt 2: Schema importieren"

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" 2>/dev/null < "$SCHEMA_FILE"

if [ $? -eq 0 ]; then
    print_success "Schema erfolgreich importiert"
else
    print_error "Fehler beim Importieren des Schemas"
    exit 1
fi

# ============================================================================
# Tabellen überprüfen
# ============================================================================

print_header "Schritt 3: Tabellen überprüfen"

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES;"

print_success "Datenbank ist bereit für Tests!"

echo ""
print_info "Nächste Schritte:"
echo "  1. Starten Sie das Test-Script: ./test_devices.sh"
echo "  2. Oder verwenden Sie curl direkt"
echo ""

# ============================================================================
# Speichere Konfiguration für Test-Script
# ============================================================================

cat > /tmp/db_config.env << EOF
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
EOF

print_success "Konfiguration gespeichert in /tmp/db_config.env"
