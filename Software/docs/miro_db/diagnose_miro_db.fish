#!/usr/bin/env fish

# ============================================================
# Diagnose: miro_db Verbindung und Tabellen prüfen
# ============================================================

echo "🔍 Diagnose: miro_db Verbindung"
echo "================================"
echo ""

# 1. Container-Status
echo "📊 1. Container-Status"
echo "----------------------"
podman ps | grep benning
echo ""

# 2. .env Datei prüfen
echo "📋 2. .env Datei - Datenbank-Konfiguration"
echo "-------------------------------------------"
cat .env | grep DB_
echo ""

# 3. MySQL-Verbindung testen
echo "🧪 3. MySQL-Verbindung testen"
echo "------------------------------"
podman exec -it benning-mysql mysql -u miro -pmiro -e "SELECT 'Verbindung OK' AS Status;"
echo ""

# 4. Datenbanken anzeigen
echo "🗄️  4. Verfügbare Datenbanken"
echo "-----------------------------"
podman exec -it benning-mysql mysql -u miro -pmiro -e "SHOW DATABASES;"
echo ""

# 5. Tabellen in miro_db prüfen
echo "📊 5. Tabellen in miro_db"
echo "-------------------------"
podman exec -it benning-mysql mysql -u miro -pmiro miro_db -e "SHOW TABLES;"
echo ""

# 6. Flask Logs prüfen (letzte 50 Zeilen)
echo "📜 6. Flask Logs (letzte 50 Zeilen)"
echo "------------------------------------"
podman logs --tail 50 benning-flask
echo ""

# 7. Nach Datenbankfehlern suchen
echo "🚨 7. Datenbankfehler in Flask Logs"
echo "------------------------------------"
podman logs --tail 200 benning-flask | grep -i "error\|exception\|database\|mysql\|table\|miro"
echo ""

# 8. Zusammenfassung
echo "📋 Zusammenfassung"
echo "=================="
echo ""
echo "Bitte prüfe:"
echo "1. Sind alle Tabellen in miro_db vorhanden?"
echo "2. Gibt es Fehler in den Flask Logs?"
echo "3. Ist die .env Datei korrekt?"
echo ""
echo "Falls Tabellen fehlen, führe aus:"
echo "  podman exec -i benning-mysql mysql -u miro -pmiro miro_db < schema.sql"
