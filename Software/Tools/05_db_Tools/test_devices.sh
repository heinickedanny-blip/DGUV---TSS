#!/bin/bash

# ============================================================================
# Benning Device Manager - curl Test Script
# ============================================================================
# Dieses Script testet die API mit verschiedenen Testvarianten
# Erstellt Geräte mit unterschiedlichen Konfigurationen
# ============================================================================

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# KONFIGURATION
# ============================================================================

API_URL="${API_URL:-http://localhost:5000}"
CONTENT_TYPE="Content-Type: application/json"

# ============================================================================
# FUNKTIONEN
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}========================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================================================${NC}"
}

print_test() {
    echo -e "${CYAN}TEST: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Sende POST Request und speichere Response
send_request() {
    local name=$1
    local data=$2
    
    print_test "$name"
    print_info "Daten: $data"
    
    response=$(curl -s -X POST "$API_URL/device/add" \
        -H "$CONTENT_TYPE" \
        -d "$data")
    
    echo "Response: $response"
    
    if echo "$response" | grep -q '"status":"success"'; then
        print_success "$name erfolgreich"
    else
        print_error "$name fehlgeschlagen"
    fi
    
    echo ""
}

# ============================================================================
# HAUPTLOGIK
# ============================================================================

print_header "Benning Device Manager - API Test"

print_info "API URL: $API_URL"
print_info "Starte Tests..."

# Überprüfe ob API erreichbar ist
echo ""
print_test "API Verbindung überprüfen"

if curl -s "$API_URL/" > /dev/null 2>&1; then
    print_success "API ist erreichbar"
else
    print_error "API ist nicht erreichbar unter $API_URL"
    print_info "Stelle sicher, dass die Flask-App läuft:"
    print_info "  python3 /home/ubuntu/src/main.py"
    exit 1
fi

# ============================================================================
# TESTVARIANTE 1: Einfaches Gerät (Minimal)
# ============================================================================

print_header "Testvariante 1: Einfaches Gerät (Minimal)"

send_request "Minimal Device" '{
    "customer": "Benning",
    "name": "Test Device 1",
    "type": "Multimeter"
}'

# ============================================================================
# TESTVARIANTE 2: Gerät mit allen Feldern
# ============================================================================

print_header "Testvariante 2: Gerät mit allen Feldern"

send_request "Vollständiges Gerät" '{
    "customer": "Benning",
    "name": "Test Device 2",
    "type": "Oszilloskop",
    "location": "Labor 1",
    "manufacturer": "Siemens",
    "serial_number": "SN-2024-001",
    "purchase_date": "2024-01-15",
    "status": "active",
    "notes": "Neues Testgerät für Labortests"
}'

# ============================================================================
# TESTVARIANTE 3: USB-Kabel mit bestandener Prüfung
# ============================================================================

print_header "Testvariante 3: USB-Kabel mit bestandener Prüfung"

send_request "USB-Kabel (bestanden)" '{
    "customer": "Benning",
    "name": "USB-C Kabel 1",
    "type": "USB-Kabel",
    "location": "Lager",
    "manufacturer": "Apple",
    "cable_type": "USB-C",
    "test_result": "bestanden",
    "internal_resistance": 0.5,
    "emarker_active": true,
    "inspection_notes": "Kabel in gutem Zustand"
}'

# ============================================================================
# TESTVARIANTE 4: USB-Kabel mit nicht bestandener Prüfung
# ============================================================================

print_header "Testvariante 4: USB-Kabel mit nicht bestandener Prüfung"

send_request "USB-Kabel (nicht bestanden)" '{
    "customer": "Benning",
    "name": "USB-C Kabel 2",
    "type": "USB-Kabel",
    "location": "Lager",
    "manufacturer": "Generic",
    "cable_type": "USB-C",
    "test_result": "nicht_bestanden",
    "internal_resistance": 2.5,
    "emarker_active": false,
    "inspection_notes": "Hoher Innenwiderstand, nicht verwendbar"
}'

# ============================================================================
# TESTVARIANTE 5: USB-Kabel verloren
# ============================================================================

print_header "Testvariante 5: USB-Kabel verloren"

send_request "USB-Kabel (verloren)" '{
    "customer": "Benning",
    "name": "USB-A Kabel 1",
    "type": "USB-Kabel",
    "location": "Unbekannt",
    "manufacturer": "Belkin",
    "cable_type": "USB-A",
    "test_result": "verloren",
    "inspection_notes": "Kabel während Transport verloren gegangen"
}'

# ============================================================================
# TESTVARIANTE 6: USB-Kabel nicht vorhanden
# ============================================================================

print_header "Testvariante 6: USB-Kabel nicht vorhanden"

send_request "USB-Kabel (nicht vorhanden)" '{
    "customer": "Benning",
    "name": "Lightning Kabel 1",
    "type": "USB-Kabel",
    "location": "Lager",
    "manufacturer": "Apple",
    "cable_type": "Lightning",
    "test_result": "nicht_vorhanden",
    "inspection_notes": "Kabel wurde nicht mit Gerät geliefert"
}'

# ============================================================================
# TESTVARIANTE 7: Verschiedene USB-Kabel Typen
# ============================================================================

print_header "Testvariante 7: Verschiedene USB-Kabel Typen"

# USB-Micro
send_request "USB-Micro Kabel" '{
    "customer": "Benning",
    "name": "Micro USB Kabel",
    "type": "USB-Kabel",
    "cable_type": "Micro-USB",
    "test_result": "bestanden",
    "internal_resistance": 0.3,
    "inspection_notes": "Micro USB Kabel - bestanden"
}'

# USB-B
send_request "USB-B Kabel" '{
    "customer": "Benning",
    "name": "USB-B Kabel",
    "type": "USB-Kabel",
    "cable_type": "USB-B",
    "test_result": "bestanden",
    "internal_resistance": 0.4,
    "inspection_notes": "USB-B Kabel - bestanden"
}'

# Andere
send_request "Proprietäres Kabel" '{
    "customer": "Benning",
    "name": "Proprietäres Kabel",
    "type": "USB-Kabel",
    "cable_type": "Andere",
    "test_result": "bestanden",
    "internal_resistance": 0.6,
    "inspection_notes": "Proprietäres Kabel - bestanden"
}'

# ============================================================================
# TESTVARIANTE 8: Mehrere Kunden
# ============================================================================

print_header "Testvariante 8: Mehrere Kunden"

send_request "Gerät von Kunde A" '{
    "customer": "Kunde A",
    "name": "Prüfgerät A1",
    "type": "Prüfgerät",
    "location": "Standort A",
    "manufacturer": "Hersteller A"
}'

send_request "Gerät von Kunde B" '{
    "customer": "Kunde B",
    "name": "Prüfgerät B1",
    "type": "Prüfgerät",
    "location": "Standort B",
    "manufacturer": "Hersteller B"
}'

# ============================================================================
# TESTVARIANTE 9: Geräte mit Inspektionsdaten
# ============================================================================

print_header "Testvariante 9: Geräte mit Inspektionsdaten"

send_request "Gerät mit Inspektionsdaten" '{
    "customer": "Benning",
    "name": "Inspiziertes Gerät",
    "type": "Multimeter",
    "location": "Labor",
    "manufacturer": "Fluke",
    "serial_number": "FL-2024-100",
    "purchase_date": "2023-06-01",
    "last_inspection": "2024-01-20",
    "next_inspection": "2025-01-20",
    "status": "active",
    "notes": "Regelmäßig inspiziertes Gerät"
}'

# ============================================================================
# TESTVARIANTE 10: Geräte mit verschiedenen Status
# ============================================================================

print_header "Testvariante 10: Geräte mit verschiedenen Status"

send_request "Gerät - Status: maintenance" '{
    "customer": "Benning",
    "name": "Gerät in Wartung",
    "type": "Oszilloskop",
    "status": "maintenance",
    "notes": "Gerät ist derzeit in Wartung"
}'

send_request "Gerät - Status: retired" '{
    "customer": "Benning",
    "name": "Gerät ausgemustert",
    "type": "Analog Multimeter",
    "status": "retired",
    "notes": "Gerät wurde ausgemustert"
}'

send_request "Gerät - Status: inactive" '{
    "customer": "Benning",
    "name": "Gerät inaktiv",
    "type": "Stromprüfer",
    "status": "inactive",
    "notes": "Gerät ist derzeit nicht in Verwendung"
}'

# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================

print_header "Test abgeschlossen"

print_info "Alle Testvarianten wurden ausgeführt!"
print_info "Überprüfe die Geräteliste unter: $API_URL/devices"
print_info ""
print_info "Testvarianten:"
echo "  1. Einfaches Gerät (Minimal)"
echo "  2. Gerät mit allen Feldern"
echo "  3. USB-Kabel mit bestandener Prüfung"
echo "  4. USB-Kabel mit nicht bestandener Prüfung"
echo "  5. USB-Kabel verloren"
echo "  6. USB-Kabel nicht vorhanden"
echo "  7. Verschiedene USB-Kabel Typen (Micro, USB-B, Andere)"
echo "  8. Mehrere Kunden"
echo "  9. Geräte mit Inspektionsdaten"
echo "  10. Geräte mit verschiedenen Status"
echo ""

print_success "Test-Script abgeschlossen!"
