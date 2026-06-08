#!/usr/bin/env fish

# ============================================================
# Benning Device Manager - Neue Datenbank Setup
# ============================================================
# Dieses Skript erstellt eine neue MySQL-Datenbank "miro_db"
# mit dem Benutzer "miro" und Passwort "miro"
# ============================================================

set -l CONTAINER_NAME "benning-flask"
set -l NEW_DB "miro_db"
set -l NEW_USER "miro"
set -l NEW_PASSWORD "miro"
set -l OLD_DB "benning_device_manager"

echo "🗄️  Benning Device Manager - Datenbank Setup"
echo "=============================================="
echo ""

# Schritt 1: Container-Status prüfen
echo "📊 Schritt 1: Container-Status prüfen..."
if podman ps | grep -q $CONTAINER_NAME
    echo "✓ Container '$CONTAINER_NAME' läuft"
else
    echo "⚠️  Container '$CONTAINER_NAME' läuft nicht"
    echo "Starte Container..."
    podman start $CONTAINER_NAME
    sleep 3
end

echo ""

# Schritt 2: Root-Passwort abfragen
echo "🔐 Schritt 2: MySQL Root-Zugang"
echo "Bitte gib das MySQL Root-Passwort ein:"
read -s ROOT_PASSWORD

echo ""

# Schritt 3: Neue Datenbank und Benutzer erstellen
echo "🔨 Schritt 3: Erstelle neue Datenbank und Benutzer..."

set -l SQL_COMMANDS "
-- Neue Datenbank erstellen
CREATE DATABASE IF NOT EXISTS $NEW_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Neuen Benutzer erstellen (falls nicht vorhanden)
CREATE USER IF NOT EXISTS '$NEW_USER'@'%' IDENTIFIED BY '$NEW_PASSWORD';
CREATE USER IF NOT EXISTS '$NEW_USER'@'localhost' IDENTIFIED BY '$NEW_PASSWORD';

-- Alle Rechte auf die neue Datenbank geben
GRANT ALL PRIVILEGES ON $NEW_DB.* TO '$NEW_USER'@'%';
GRANT ALL PRIVILEGES ON $NEW_DB.* TO '$NEW_USER'@'localhost';

-- Rechte aktualisieren
FLUSH PRIVILEGES;

-- Status anzeigen
SELECT 'Datenbank erstellt:' AS Status;
SHOW DATABASES LIKE '$NEW_DB';

SELECT 'Benutzer erstellt:' AS Status;
SELECT User, Host FROM mysql.user WHERE User='$NEW_USER';
"

# SQL-Befehle ausführen
echo $SQL_COMMANDS | podman exec -i $CONTAINER_NAME mysql -u root -p$ROOT_PASSWORD

if test $status -eq 0
    echo "✓ Datenbank '$NEW_DB' und Benutzer '$NEW_USER' erfolgreich erstellt"
else
    echo "✗ Fehler beim Erstellen der Datenbank"
    exit 1
end

echo ""

# Schritt 4: Verbindung testen
echo "🧪 Schritt 4: Verbindung testen..."
podman exec -i $CONTAINER_NAME mysql -u $NEW_USER -p$NEW_PASSWORD $NEW_DB -e "SELECT 'Verbindung erfolgreich!' AS Status;" 2>/dev/null

if test $status -eq 0
    echo "✓ Verbindung zur neuen Datenbank erfolgreich"
else
    echo "✗ Verbindung zur neuen Datenbank fehlgeschlagen"
    exit 1
end

echo ""

# Schritt 5: Alte Datenbank sichern (optional)
echo "💾 Schritt 5: Alte Datenbank sichern?"
echo "Möchtest du die alte Datenbank '$OLD_DB' sichern? (j/n)"
read -n 1 BACKUP_CHOICE

if test "$BACKUP_CHOICE" = "j" -o "$BACKUP_CHOICE" = "J"
    echo ""
    set -l BACKUP_FILE "backup_$OLD_DB"_(date +%Y%m%d_%H%M%S).sql
    echo "Erstelle Backup: $BACKUP_FILE"
    
    podman exec $CONTAINER_NAME mysqldump -u root -p$ROOT_PASSWORD $OLD_DB > $BACKUP_FILE
    
    if test $status -eq 0
        echo "✓ Backup erfolgreich erstellt: $BACKUP_FILE"
    else
        echo "⚠️  Backup fehlgeschlagen (möglicherweise existiert die Datenbank nicht)"
    end
else
    echo ""
    echo "⏭️  Backup übersprungen"
end

echo ""

# Schritt 6: Container neu starten
echo "🔄 Schritt 6: Container neu starten..."
echo "Möchtest du den Container jetzt neu starten? (j/n)"
read -n 1 RESTART_CHOICE

if test "$RESTART_CHOICE" = "j" -o "$RESTART_CHOICE" = "J"
    echo ""
    echo "Stoppe Container..."
    podman stop $CONTAINER_NAME
    
    echo "Starte Container..."
    podman start $CONTAINER_NAME
    
    sleep 2
    echo "✓ Container neu gestartet"
else
    echo ""
    echo "⏭️  Container-Neustart übersprungen"
    echo "⚠️  WICHTIG: Starte den Container manuell neu:"
    echo "   podman stop $CONTAINER_NAME"
    echo "   podman start $CONTAINER_NAME"
end

echo ""

# Schritt 7: Zusammenfassung
echo "📋 Zusammenfassung"
echo "=================="
echo "✓ Neue Datenbank: $NEW_DB"
echo "✓ Neuer Benutzer: $NEW_USER"
echo "✓ Passwort: $NEW_PASSWORD"
echo "✓ Container: $CONTAINER_NAME"
echo "✓ .env Datei bereits aktualisiert"
echo ""
echo "🚀 Nächste Schritte:"
echo "1. Falls nicht automatisch neu gestartet:"
echo "   podman stop benning-flask"
echo "   podman start benning-flask"
echo ""
echo "2. Logs überprüfen:"
echo "   podman logs -f benning-flask"
echo ""
echo "3. Anwendung testen:"
echo "   curl http://localhost:5000/health"
echo ""
echo "✅ Setup abgeschlossen!"
