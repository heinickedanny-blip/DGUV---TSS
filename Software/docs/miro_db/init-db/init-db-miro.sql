-- ============================================================================
-- Benning Device Manager - Database Initialization (miro_db)
-- ============================================================================
-- Dieses Skript wird automatisch beim ersten Start des MySQL-Containers
-- ausgeführt und erstellt die notwendigen Benutzer und Berechtigungen
-- ============================================================================

-- Datenbank wird bereits durch MYSQL_DATABASE erstellt

-- Zusätzliche Berechtigungen für den miro-Benutzer
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'%';
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'localhost';

-- Rechte aktualisieren
FLUSH PRIVILEGES;

-- Bestätigung
SELECT 'miro_db Datenbank erfolgreich initialisiert' AS Status;
SELECT User, Host FROM mysql.user WHERE User='miro';

-- Optional: Tabellen-Schema hier einfügen
-- CREATE TABLE IF NOT EXISTS devices (
--     id INT AUTO_INCREMENT PRIMARY KEY,
--     name VARCHAR(255) NOT NULL,
--     model VARCHAR(255),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );
