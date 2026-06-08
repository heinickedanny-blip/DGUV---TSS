-- ============================================================================
-- Spalte last_inspection von DATE zu DATETIME ändern
-- Datenbank: miro_db
-- ============================================================================

USE miro_db;

-- 1. Aktuellen Datentyp anzeigen
SELECT 
    COLUMN_NAME AS 'Spalte',
    DATA_TYPE AS 'Aktueller Datentyp',
    COLUMN_TYPE AS 'Details'
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'miro_db' 
AND TABLE_NAME = 'devices' 
AND COLUMN_NAME = 'last_inspection';

-- 2. Spalte zu DATETIME ändern
ALTER TABLE devices 
MODIFY COLUMN last_inspection DATETIME;

-- 3. Neuen Datentyp bestätigen
SELECT 
    COLUMN_NAME AS 'Spalte',
    DATA_TYPE AS 'Neuer Datentyp',
    COLUMN_TYPE AS 'Details'
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = 'miro_db' 
AND TABLE_NAME = 'devices' 
AND COLUMN_NAME = 'last_inspection';

-- 4. Beispiel-Werte anzeigen
SELECT 
    id,
    name,
    last_inspection
FROM devices 
WHERE last_inspection IS NOT NULL
ORDER BY id DESC 
LIMIT 5;

-- ============================================================================
-- Erfolgreich: last_inspection ist jetzt DATETIME und kann Uhrzeit speichern
-- ============================================================================
