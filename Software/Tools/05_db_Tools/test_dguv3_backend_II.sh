#!/bin/bash

echo "🔍 Prüfe ob DGUV3-Felder aus der Datenbank gelesen werden..."
echo ""

# Teste API-Endpunkt
echo "📡 Teste API: /api/devices"
curl -s http://localhost:5000/api/devices | python3 -m json.tool | head -50

echo ""
echo "---"
echo ""

# Prüfe ob mysql_device_repository die DGUV3-Felder hat
echo "📄 Prüfe mysql_device_repository.py:"
echo ""

if grep -q "r_pe.*row" src/adapters/persistence/mysql_device_repository.py; then
    echo "✅ DGUV3-Felder werden aus der Datenbank gemappt"
else
    echo "❌ DGUV3-Felder fehlen im Mapping!"
    echo ""
    echo "Sie müssen mysql_device_repository_fixed.py installieren:"
    echo "cp mysql_device_repository_fixed.py src/adapters/persistence/mysql_device_repository.py"
fi

echo ""
echo "---"
echo ""

# Prüfe Datenbank direkt
echo "📊 Prüfe Datenbank direkt:"
podman exec -it benning-mysql mysql -u benning -p -e "SELECT customer_device_id, r_pe, r_iso, i_pe, i_b FROM benning_device_manager.devices LIMIT 5;"
