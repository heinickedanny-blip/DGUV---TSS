#!/bin/bash

echo "🧪 Teste ob last_inspection gespeichert wird..."
echo ""

# Test mit curl
echo "📤 Sende Gerät mit Prüfdatum..."
curl -X POST http://localhost:5000/api/devices \
  -H "Content-Type: application/json" \
  -d '{
    "customer": "TestDatum",
    "name": "Testgerät mit Datum",
    "type": "Elektrowerkzeug",
    "last_inspection": "2026-01-29",
    "r_pe": 0.150,
    "r_iso": 2.500,
    "i_pe": 1.200,
    "i_b": 0.300
  }'

echo ""
echo ""
echo "📊 Prüfe Datenbank..."
podman exec -it benning-mysql mysql -u benning -p -e "SELECT customer_device_id, last_inspection, r_pe FROM benning_device_manager.devices WHERE customer='TestDatum';"
