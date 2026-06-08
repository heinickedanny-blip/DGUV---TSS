#!/bin/bash

# ============================================================================
# DGUV3 Test-Geräte mit curl anlegen
# ============================================================================
# Dieses Skript legt verschiedene Testgeräte mit DGUV3-Prüfwerten an
# Enthält: Bestanden, Grenzwertig, Durchgefallen
# ============================================================================

API_URL="http://localhost:5000/api/devices"

echo "🧪 DGUV3 Test-Geräte werden angelegt..."
echo "========================================="
echo ""

# ============================================================================
# Test 1: Bohrmaschine - ALLE WERTE BESTANDEN ✅
# ============================================================================
echo "📌 Test 1: Bohrmaschine (Alle Werte OK)"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Parloa",
    "name": "Bohrmaschine Bosch GSB 13 RE",
    "type": "Elektrowerkzeug",
    "manufacturer": "Bosch",
    "serial_number": "GSB-2024-001",
    "location": "Werkstatt A",
    "status": "active",
    "last_inspection": "2024-01-15",
    "r_pe": 0.15,
    "r_iso": 2.5,
    "i_pe": 1.2,
    "i_b": 0.25
  }'
echo -e "\n"

# ============================================================================
# Test 2: Winkelschleifer - R_PE GRENZWERTIG ⚠️
# ============================================================================
echo "📌 Test 2: Winkelschleifer (R_PE grenzwertig)"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Parloa",
    "name": "Winkelschleifer Makita GA9020",
    "type": "Elektrowerkzeug",
    "manufacturer": "Makita",
    "serial_number": "GA9-2024-002",
    "location": "Werkstatt B",
    "status": "active",
    "last_inspection": "2024-01-16",
    "r_pe": 0.28,
    "r_iso": 3.2,
    "i_pe": 2.1,
    "i_b": 0.35
  }'
echo -e "\n"

# ============================================================================
# Test 3: Stichsäge - R_PE DURCHGEFALLEN ❌
# ============================================================================
echo "📌 Test 3: Stichsäge (R_PE durchgefallen)"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Parloa",
    "name": "Stichsäge Festool PSB 300 EQ",
    "type": "Elektrowerkzeug",
    "manufacturer": "Festool",
    "serial_number": "PSB-2024-003",
    "location": "Werkstatt A",
    "status": "inactive",
    "last_inspection": "2024-01-17",
    "r_pe": 0.45,
    "r_iso": 2.8,
    "i_pe": 1.5,
    "i_b": 0.3
  }'
echo -e "\n"

# ============================================================================
# Test 4: Kreissäge - R_ISO DURCHGEFALLEN ❌
# ============================================================================
echo "📌 Test 4: Kreissäge (R_ISO zu niedrig)"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Siemens",
    "name": "Kreissäge DeWalt DWE575K",
    "type": "Elektrowerkzeug",
    "manufacturer": "DeWalt",
    "serial_number": "DWE-2024-004",
    "location": "Halle 3",
    "status": "maintenance",
    "last_inspection": "2024-01-18",
    "r_pe": 0.18,
    "r_iso": 0.8,
    "i_pe": 1.8,
    "i_b": 0.28
  }'
echo -e "\n"

# ============================================================================
# Test 5: Schlagbohrmaschine - I_PE DURCHGEFALLEN ❌
# ============================================================================
echo "📌 Test 5: Schlagbohrmaschine (I_PE zu hoch)"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Siemens",
    "name": "Schlagbohrmaschine Hilti TE 6-A36",
    "type": "Elektrowerkzeug",
    "manufacturer": "Hilti",
    "serial_number": "TE6-2024-005",
    "location": "Halle 2",
    "status": "inactive",
    "last_inspection": "2024-01-19",
    "r_pe": 0.22,
    "r_iso": 4.5,
    "i_pe": 4.2,
    "i_b": 0.32
  }'
echo -e "\n"

# ============================================================================
# Test 6: Akkuschrauber - I_B DURCHGEFALLEN ❌
# ============================================================================
echo "📌 Test 6: Akkuschrauber (I_B zu hoch)"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Siemens",
    "name": "Akkuschrauber Metabo BS 18 LT",
    "type": "Elektrowerkzeug",
    "manufacturer": "Metabo",
    "serial_number": "BS18-2024-006",
    "location": "Halle 1",
    "status": "inactive",
    "last_inspection": "2024-01-20",
    "r_pe": 0.19,
    "r_iso": 3.8,
    "i_pe": 2.5,
    "i_b": 0.65
  }'
echo -e "\n"

# ============================================================================
# Test 7: Exzenterschleifer - PERFEKTE WERTE ✅
# ============================================================================
echo "📌 Test 7: Exzenterschleifer (Perfekte Werte)"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "BMW",
    "name": "Exzenterschleifer Mirka DEROS 5650CV",
    "type": "Elektrowerkzeug",
    "manufacturer": "Mirka",
    "serial_number": "DEROS-2024-007",
    "location": "Lackiererei",
    "status": "active",
    "last_inspection": "2024-01-21",
    "r_pe": 0.08,
    "r_iso": 5.2,
    "i_pe": 0.5,
    "i_b": 0.12
  }'
echo -e "\n"

# ============================================================================
# Test 8: Heißluftgebläse - MEHRERE WERTE DURCHGEFALLEN ❌❌
# ============================================================================
echo "📌 Test 8: Heißluftgebläse (Mehrere Werte durchgefallen)"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "BMW",
    "name": "Heißluftgebläse Steinel HG 2320 E",
    "type": "Elektrowerkzeug",
    "manufacturer": "Steinel",
    "serial_number": "HG-2024-008",
    "location": "Werkstatt",
    "status": "retired",
    "last_inspection": "2024-01-22",
    "r_pe": 0.52,
    "r_iso": 0.6,
    "i_pe": 5.8,
    "i_b": 0.85
  }'
echo -e "\n"

# ============================================================================
# Test 9: Kompressor - OHNE DGUV3-WERTE (optional)
# ============================================================================
echo "📌 Test 9: Kompressor (Ohne DGUV3-Werte)"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "BMW",
    "name": "Kompressor Einhell TC-AC 190/24/8",
    "type": "Elektrowerkzeug",
    "manufacturer": "Einhell",
    "serial_number": "TC-2024-009",
    "location": "Werkstatt",
    "status": "active",
    "last_inspection": "2024-01-23"
  }'
echo -e "\n"

# ============================================================================
# Test 10: Schweißgerät - GRENZWERTIG BEI MEHREREN WERTEN ⚠️⚠️
# ============================================================================
echo "📌 Test 10: Schweißgerät (Mehrere Werte grenzwertig)"
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "Audi",
    "name": "Schweißgerät Lorch S3 SpeedPulse XT",
    "type": "Elektrowerkzeug",
    "manufacturer": "Lorch",
    "serial_number": "S3-2024-010",
    "location": "Schweißerei",
    "status": "active",
    "last_inspection": "2024-01-24",
    "r_pe": 0.29,
    "r_iso": 1.05,
    "i_pe": 3.4,
    "i_b": 0.48
  }'
echo -e "\n"

echo "========================================="
echo "✅ Alle Test-Geräte wurden angelegt!"
echo ""
echo "📊 Zusammenfassung:"
echo "  - 2 Geräte: Alle Werte OK ✅"
echo "  - 2 Geräte: Grenzwertig ⚠️"
echo "  - 5 Geräte: Durchgefallen ❌"
echo "  - 1 Gerät: Ohne DGUV3-Werte"
echo ""
echo "🌐 Öffnen Sie http://localhost:5000/devices um die Ergebnisse zu sehen!"
