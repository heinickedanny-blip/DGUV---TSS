-- ============================================================
-- Benning Device Manager - Neue Datenbank Setup
-- ============================================================
-- Dieses SQL-Skript erstellt eine neue Datenbank "miro_db"
-- mit dem Benutzer "miro" und Passwort "miro"
-- ============================================================

-- Neue Datenbank erstellen
CREATE DATABASE IF NOT EXISTS miro_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Neuen Benutzer erstellen (falls nicht vorhanden)
CREATE USER IF NOT EXISTS 'miro'@'%' IDENTIFIED BY 'miro';
CREATE USER IF NOT EXISTS 'miro'@'localhost' IDENTIFIED BY 'miro';

-- Alle Rechte auf die neue Datenbank geben
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'%';
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'localhost';

-- Rechte aktualisieren
FLUSH PRIVILEGES;

-- Status anzeigen
SELECT '=== Datenbank erfolgreich erstellt ===' AS Status;
SHOW DATABASES LIKE 'miro_db';

SELECT '=== Benutzer erfolgreich erstellt ===' AS Status;
SELECT User, Host FROM mysql.user WHERE User='miro';

SELECT '=== Berechtigungen ===' AS Status;
SHOW GRANTS FOR 'miro'@'%';

-- Datenbank verwenden
USE miro_db;

-- Status anzeigen
SELECT DATABASE() AS 'Aktuelle Datenbank';
