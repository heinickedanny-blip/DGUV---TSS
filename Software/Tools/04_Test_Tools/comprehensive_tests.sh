#!/bin/bash

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:5001"
TEST_RESULTS="/tmp/test_results.txt"

# Initialisiere Test-Ergebnisse
> $TEST_RESULTS

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1" | tee -a $TEST_RESULTS
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a $TEST_RESULTS
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a $TEST_RESULTS
}

log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1" | tee -a $TEST_RESULTS
}

# ========================================================================
# TEST 1: Erfolgreiche Device-Erstellung mit vollständigen Daten
# ========================================================================
log_test "Test 1: Erfolgreiche Device-Erstellung mit vollständigen Daten"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "TestKunde1",
    "name": "Bohrmaschine",
    "type": "Elektrowerkzeug",
    "location": "Lager A",
    "manufacturer": "Bosch",
    "serial_number": "SN-BOSCH-001",
    "purchase_date": "2023-01-15",
    "status": "active",
    "notes": "Neue Bohrmaschine"
  }')

if echo "$RESPONSE" | grep -q '"success":true'; then
    log_pass "Device erstellt: $(echo $RESPONSE | grep -o '"customer_device_id":"[^"]*' | cut -d'"' -f4)"
    DEVICE_ID_1=$(echo $RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
else
    log_fail "Device-Erstellung fehlgeschlagen: $RESPONSE"
fi

# ========================================================================
# TEST 2: Device mit leeren optionalen Feldern
# ========================================================================
log_test "Test 2: Device mit leeren optionalen Feldern"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "TestKunde2",
    "name": "Schleifer",
    "type": "Elektrowerkzeug",
    "serial_number": "",
    "manufacturer": "",
    "location": "",
    "purchase_date": "",
    "notes": ""
  }')

if echo "$RESPONSE" | grep -q '"success":true'; then
    log_pass "Device mit leeren Feldern erstellt"
else
    log_fail "Device-Erstellung fehlgeschlagen: $RESPONSE"
fi

# ========================================================================
# TEST 3: Fehlende erforderliche Felder (customer)
# ========================================================================
log_test "Test 3: Fehlende erforderliche Felder (customer)"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test",
    "type": "Elektrowerkzeug"
  }')

if echo "$RESPONSE" | grep -q '"customer is required"'; then
    log_pass "Validierungsfehler korrekt erkannt"
else
    log_fail "Validierungsfehler nicht erkannt: $RESPONSE"
fi

# ========================================================================
# TEST 4: Fehlende erforderliche Felder (type)
# ========================================================================
log_test "Test 4: Fehlende erforderliche Felder (type)"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Test",
    "name": "Test"
  }')

if echo "$RESPONSE" | grep -q '"type is required"'; then
    log_pass "Validierungsfehler korrekt erkannt"
else
    log_fail "Validierungsfehler nicht erkannt: $RESPONSE"
fi

# ========================================================================
# TEST 5: Ungültiges Datumsformat
# ========================================================================
log_test "Test 5: Ungültiges Datumsformat"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Test",
    "name": "Test",
    "type": "Elektrowerkzeug",
    "purchase_date": "2023-13-45"
  }')

if echo "$RESPONSE" | grep -q '"purchase_date must be in ISO format"'; then
    log_pass "Datumsvalidierungsfehler korrekt erkannt"
else
    log_fail "Datumsvalidierungsfehler nicht erkannt: $RESPONSE"
fi

# ========================================================================
# TEST 6: Ungültiger Status
# ========================================================================
log_test "Test 6: Ungültiger Status"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Test",
    "name": "Test",
    "type": "Elektrowerkzeug",
    "status": "invalid_status"
  }')

if echo "$RESPONSE" | grep -q '"status must be one of"'; then
    log_pass "Status-Validierungsfehler korrekt erkannt"
else
    log_fail "Status-Validierungsfehler nicht erkannt: $RESPONSE"
fi

# ========================================================================
# TEST 7: Zu lange Strings (name > 255 Zeichen)
# ========================================================================
log_test "Test 7: Zu lange Strings (name > 255 Zeichen)"
LONG_NAME=$(python3 -c "print('x' * 300)")
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d "{
    \"customer\": \"Test\",
    \"name\": \"$LONG_NAME\",
    \"type\": \"Elektrowerkzeug\"
  }")

if echo "$RESPONSE" | grep -q '"name must not exceed 255 characters"'; then
    log_pass "Längenbeschränkung korrekt erkannt"
else
    log_fail "Längenbeschränkung nicht erkannt: $RESPONSE"
fi

# ========================================================================
# TEST 8: Doppelte Seriennummer
# ========================================================================
log_test "Test 8: Doppelte Seriennummer"
# Erste Erstellung
curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "TestKunde3",
    "name": "Device 1",
    "type": "Elektrowerkzeug",
    "serial_number": "SN-DUPLICATE-TEST"
  }' > /dev/null

# Zweite Erstellung mit gleicher SN
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "TestKunde4",
    "name": "Device 2",
    "type": "Elektrowerkzeug",
    "serial_number": "SN-DUPLICATE-TEST"
  }')

if echo "$RESPONSE" | grep -q '"Duplicate entry"'; then
    log_pass "Duplicate-Fehler korrekt erkannt (409 Conflict)"
elif echo "$RESPONSE" | grep -q '"success":false'; then
    log_fail "Duplicate-Fehler erkannt, aber falscher Status-Code"
else
    log_fail "Duplicate-Fehler nicht erkannt: $RESPONSE"
fi

# ========================================================================
# TEST 9: GET Device by ID
# ========================================================================
if [ ! -z "$DEVICE_ID_1" ]; then
    log_test "Test 9: GET Device by ID"
    RESPONSE=$(curl -s -X GET "$BASE_URL/api/devices/$DEVICE_ID_1")
    
    if echo "$RESPONSE" | grep -q '"success":true'; then
        log_pass "Device abgerufen: ID $DEVICE_ID_1"
    else
        log_fail "Device abrufen fehlgeschlagen: $RESPONSE"
    fi
fi

# ========================================================================
# TEST 10: GET alle Devices
# ========================================================================
log_test "Test 10: GET alle Devices"
RESPONSE=$(curl -s -X GET "$BASE_URL/api/devices")

if echo "$RESPONSE" | grep -q '"success":true'; then
    COUNT=$(echo "$RESPONSE" | grep -o '"id"' | wc -l)
    log_pass "Alle Devices abgerufen: $COUNT Geräte"
else
    log_fail "Devices abrufen fehlgeschlagen: $RESPONSE"
fi

# ========================================================================
# TEST 11: Mehrere Geräte für gleichen Kunden (Sequenzen-Test)
# ========================================================================
log_test "Test 11: Mehrere Geräte für gleichen Kunden (Sequenzen-Test)"
for i in {1..3}; do
    RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
      -H "Content-Type: application/json" \
      -d "{
        \"customer\": \"SequenceTest\",
        \"name\": \"Device $i\",
        \"type\": \"Elektrowerkzeug\"
      }")
    
    if echo "$RESPONSE" | grep -q '"success":true'; then
        CUST_DEV_ID=$(echo "$RESPONSE" | grep -o '"customer_device_id":"[^"]*' | cut -d'"' -f4)
        log_info "  Device $i erstellt: $CUST_DEV_ID"
    else
        log_fail "  Device $i fehlgeschlagen"
    fi
done

# ========================================================================
# TEST 12: NULL vs. leere Strings
# ========================================================================
log_test "Test 12: NULL vs. leere Strings"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "TestKunde5",
    "name": "Test Device",
    "type": "Elektrowerkzeug",
    "serial_number": null,
    "manufacturer": null,
    "location": null,
    "purchase_date": null,
    "notes": null
  }')

if echo "$RESPONSE" | grep -q '"success":true'; then
    log_pass "Device mit NULL-Werten erstellt"
else
    log_fail "Device mit NULL-Werten fehlgeschlagen: $RESPONSE"
fi

# ========================================================================
# TEST 13: Alle gültigen Status-Werte
# ========================================================================
log_test "Test 13: Alle gültigen Status-Werte"
for status in "active" "inactive" "maintenance" "retired"; do
    RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
      -H "Content-Type: application/json" \
      -d "{
        \"customer\": \"StatusTest\",
        \"name\": \"Device with status $status\",
        \"type\": \"Elektrowerkzeug\",
        \"status\": \"$status\"
      }")
    
    if echo "$RESPONSE" | grep -q '"success":true'; then
        log_info "  Status '$status' akzeptiert"
    else
        log_fail "  Status '$status' abgelehnt: $RESPONSE"
    fi
done

# ========================================================================
# TEST 14: Spezielle Zeichen in Strings
# ========================================================================
log_test "Test 14: Spezielle Zeichen in Strings"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Kund€ mit Ümlauten",
    "name": "Gerät \"mit\" Anführungszeichen",
    "type": "Elektrowerkzeug",
    "notes": "Notizen mit Sonderzeichen: äöü ß € ©"
  }')

if echo "$RESPONSE" | grep -q '"success":true'; then
    log_pass "Spezielle Zeichen korrekt verarbeitet"
else
    log_fail "Spezielle Zeichen nicht verarbeitet: $RESPONSE"
fi

# ========================================================================
# TEST 15: Leere Strings vs. Whitespace
# ========================================================================
log_test "Test 15: Leere Strings vs. Whitespace"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/devices" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Test",
    "name": "Test",
    "type": "Elektrowerkzeug",
    "location": "   ",
    "manufacturer": ""
  }')

if echo "$RESPONSE" | grep -q '"success":true'; then
    log_pass "Whitespace korrekt verarbeitet"
else
    log_fail "Whitespace nicht verarbeitet: $RESPONSE"
fi

echo ""
echo -e "${BLUE}=== TEST ZUSAMMENFASSUNG ===${NC}"
echo "Alle Test-Ergebnisse in: $TEST_RESULTS"
cat $TEST_RESULTS | grep -E "\[PASS\]|\[FAIL\]" | sort | uniq -c

