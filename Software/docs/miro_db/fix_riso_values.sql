-- ============================================================================
-- Fix Riso Values: Multipliziere alle Werte mit 1000
-- Von: 0.020 MΩ → Nach: 20 MΩ
-- ============================================================================

-- Zeige aktuelle Werte (VOR der Änderung)
SELECT 'VORHER:' AS Status;
SELECT id, name, r_iso, ROUND(r_iso * 1000, 3) AS r_iso_korrigiert 
FROM devices 
WHERE r_iso IS NOT NULL 
ORDER BY id;

-- Multipliziere alle r_iso Werte mit 1000
UPDATE devices 
SET r_iso = r_iso * 1000 
WHERE r_iso IS NOT NULL;

-- Zeige korrigierte Werte (NACH der Änderung)
SELECT 'NACHHER:' AS Status;
SELECT id, name, r_iso 
FROM devices 
WHERE r_iso IS NOT NULL 
ORDER BY id;

-- Zusammenfassung
SELECT 
    COUNT(*) AS anzahl_aktualisiert,
    MIN(r_iso) AS min_wert,
    MAX(r_iso) AS max_wert,
    AVG(r_iso) AS durchschnitt
FROM devices 
WHERE r_iso IS NOT NULL;
