#!/bin/bash

# ============================================================================
# Benning Device Manager - Mapping Test Script FINAL
# Überprüft Routes, Datenbank-Tabellen und Device-Speicherung
# ============================================================================

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Konfiguration
API_BASE="http://localhost:5000"
DB_USER="benning"
DB_PASSWORD="benning"
DB_NAME="benning_device_manager"
MYSQL_CONTAINER="benning-mysql"

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
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
# 1. CONTAINER STATUS
# ============================================================================

check_containers() {
    print_header "1. CONTAINER STATUS"
    
    if podman ps | grep -q "benning-mysql"; then
        print_success "MySQL Container läuft"
    else
        print_error "MySQL Container läuft nicht!"
        exit 1
    fi
    
    if podman ps | grep -q "benning-flask"; then
        print_success "Flask Container läuft"
    else
        print_error "Flask Container läuft nicht!"
        exit 1
    fi
    
    echo ""
}

# ============================================================================
# 2. DATENBANK-VERBINDUNG
# ============================================================================

check_database_connection() {
    print_header "2. DATENBANK-VERBINDUNG"
    
    if podman exec "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" &>/dev/null; then
        print_success "Datenbank-Verbindung erfolgreich"
    else
        print_error "Datenbank-Verbindung fehlgeschlagen!"
        exit 1
    fi
    
    echo ""
}

# ============================================================================
# 3. DATENBANK-TABELLEN
# ============================================================================

check_database_tables() {
    print_header "3. DATENBANK-TABELLEN"
    
    TABLES=$(podman exec "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES;" 2>/dev/null | tail -n +2)
    
    for table in devices inspections users audit_log; do
        if echo "$TABLES" | grep -q "^$table$"; then
            print_success "Tabelle '$table' existiert"
        else
            print_error "Tabelle '$table' existiert nicht!"
        fi
    done
    
    echo ""
}

# ============================================================================
# 4. DEVICES TABELLEN-STRUKTUR (DIREKT)
# ============================================================================

check_devices_structure() {
    print_header "4. DEVICES TABELLEN-STRUKTUR"
    
    echo "Spalten in 'devices' Tabelle:"
    echo ""
    podman exec "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "DESC devices\G" 2>/dev/null | grep -E "Field|Type|Null|Key|Default" | head -40
    
    echo ""
}

# ============================================================================
# 5. API ROUTES
# ============================================================================

check_api_routes() {
    print_header "5. API ROUTES"
    
    for endpoint in "/api/devices" "/api/devices/next-id" "/" "/quick-add" "/devices"; do
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE$endpoint")
        if [ "$HTTP_CODE" = "200" ]; then
            print_success "GET $endpoint ($HTTP_CODE)"
        else
            print_error "GET $endpoint ($HTTP_CODE)"
        fi
    done
    
    echo ""
}

# ============================================================================
# 6. DEVICE-ERSTELLUNG TEST
# ============================================================================

test_device_creation() {
    print_header "6. DEVICE-ERSTELLUNG TEST"
    
    echo "Erstelle Test Device..."
    
    RESPONSE=$(curl -s -X POST "$API_BASE/api/devices" \
        -H "Content-Type: application/json" \
        -d '{
            "customer": "TestDevice",
            "name": "Test Gerät",
            "type": "Prüfgerät",
            "location": "Testlabor"
        }')
    
    echo "API Response:"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    
    if echo "$RESPONSE" | grep -q '"device_id"'; then
        print_success "Device erfolgreich erstellt"
        DEVICE_ID=$(echo "$RESPONSE" | grep -o '"device_id":"[^"]*"' | cut -d'"' -f4)
        print_info "Device ID: $DEVICE_ID"
    else
        print_error "Device-Erstellung fehlgeschlagen!"
        print_error "Response: $RESPONSE"
    fi
    
    echo ""
}

# ============================================================================
# 7. DATENBANK-INHALTE ÜBERPRÜFEN
# ============================================================================

check_database_content() {
    print_header "7. DATENBANK-INHALTE"
    
    COUNT=$(podman exec "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT COUNT(*) FROM devices;" 2>/dev/null | tail -n 1)
    
    print_info "Anzahl Devices in Datenbank: $COUNT"
    
    echo ""
    echo "Alle Devices:"
    echo ""
    podman exec "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT id, customer, device_id, name, type, location, status FROM devices;" 2>/dev/null
    
    echo ""
}

# ============================================================================
# 8. ÜBERPRÜFE QR-CODE
# ============================================================================

check_qr_code() {
    print_header "8. QR-CODE ÜBERPRÜFUNG"
    
    QR_COUNT=$(podman exec "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT COUNT(*) FROM devices WHERE qr_code IS NOT NULL;" 2>/dev/null | tail -n 1)
    
    if [ "$QR_COUNT" -gt 0 ]; then
        print_success "QR-Codes generiert: $QR_COUNT Devices"
    else
        print_warning "Keine QR-Codes gefunden (optional)"
    fi
    
    echo ""
}

# ============================================================================
# 9. ZUSAMMENFASSUNG
# ============================================================================

print_summary() {
    print_header "ZUSAMMENFASSUNG"
    
    echo "Benning Device Manager Test abgeschlossen!"
    echo ""
    print_info "API Base URL: $API_BASE"
    print_info "Datenbank: $DB_NAME"
    print_info "Container: $MYSQL_CONTAINER"
    echo ""
    print_success "Alle Tests durchgeführt"
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    print_header "BENNING DEVICE MANAGER - MAPPING TEST FINAL"
    
    check_containers
    check_database_connection
    check_database_tables
    check_devices_structure
    check_api_routes
    test_device_creation
    check_database_content
    check_qr_code
    print_summary
}

main
