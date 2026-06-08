#!/usr/bin/env fish

# ============================================================
# Schneller Fix: miro Benutzer und Datenbank erstellen
# ============================================================

echo "🔧 Schneller Fix: miro Benutzer erstellen"
echo "=========================================="
echo ""

# Schritt 1: Container prüfen
echo "📊 Schritt 1: Container-Status prüfen..."
if podman ps | grep -q benning-mysql
    echo "✓ Container 'benning-mysql' läuft"
else
    echo "✗ Container 'benning-mysql' läuft nicht"
    echo "Starte Container..."
    podman start benning-mysql
    sleep 3
end

echo ""

# Schritt 2: Root-Passwort abfragen
echo "🔐 Schritt 2: MySQL Root-Passwort"
echo "Bitte gib das MySQL Root-Passwort ein (Standard: root):"
read -s ROOT_PASSWORD

if test -z "$ROOT_PASSWORD"
    set ROOT_PASSWORD "root"
    echo "Verwende Standard-Passwort: root"
end

echo ""

# Schritt 3: Benutzer und Datenbank erstellen
echo "🔨 Schritt 3: Erstelle Benutzer und Datenbank..."

set -l SQL_COMMANDS "
CREATE DATABASE IF NOT EXISTS miro_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'miro'@'%' IDENTIFIED BY 'miro';
CREATE USER IF NOT EXISTS 'miro'@'localhost' IDENTIFIED BY 'miro';
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'%';
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'localhost';
FLUSH PRIVILEGES;
SELECT 'Datenbank und Benutzer erstellt!' AS Status;
"

echo $SQL_COMMANDS | podman exec -i benning-mysql mysql -u root -p$ROOT_PASSWORD

if test $status -eq 0
    echo "✓ Benutzer 'miro' und Datenbank 'miro_db' erfolgreich erstellt"
else
    echo "✗ Fehler beim Erstellen. Prüfe das Root-Passwort!"
    exit 1
end

echo ""

# Schritt 4: Verbindung testen
echo "🧪 Schritt 4: Verbindung testen..."
podman exec -i benning-mysql mysql -u miro -pmiro miro_db -e "SELECT 'Verbindung erfolgreich!' AS Status;" 2>/dev/null

if test $status -eq 0
    echo "✓ Verbindung zur Datenbank erfolgreich"
else
    echo "✗ Verbindung fehlgeschlagen"
    exit 1
end

echo ""

# Schritt 5: Flask neu starten
echo "🔄 Schritt 5: Flask-Container neu starten..."
echo "Möchtest du den Flask-Container jetzt neu starten? (j/n)"
read -n 1 RESTART_CHOICE

if test "$RESTART_CHOICE" = "j" -o "$RESTART_CHOICE" = "J"
    echo ""
    echo "Stoppe Flask-Container..."
    podman stop benning-flask
    
    echo "Starte Flask-Container..."
    podman start benning-flask
    
    sleep 2
    echo "✓ Flask-Container neu gestartet"
    
    echo ""
    echo "📋 Logs (Ctrl+C zum Beenden):"
    podman logs -f benning-flask
else
    echo ""
    echo "⏭️  Flask-Neustart übersprungen"
    echo "⚠️  WICHTIG: Starte Flask manuell neu:"
    echo "   podman stop benning-flask"
    echo "   podman start benning-flask"
end

echo ""
echo "✅ Fix abgeschlossen!"
echo ""
echo "🧪 Teste die Anwendung:"
echo "   curl http://localhost:5000/"
echo ""
echo "🗄️  Verbinde mit der Datenbank:"
echo "   podman exec -it benning-mysql mysql -u miro -pmiro miro_db"
