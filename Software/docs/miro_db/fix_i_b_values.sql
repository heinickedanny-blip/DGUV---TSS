-- ============================================================================
-- Fix I_B (I Leak) Values: Multipliziere alle Werte mit 10
-- Von: 0.020 mA → Nach: 0.20 mA
-- ============================================================================

-- Zeige aktuelle Werte (VOR der Änderung)
SELECT 'VORHER:' AS Status;
SELECT id, name, i_b, ROUND(i_b * 10, 3) AS i_b_korrigiert 
FROM devices 
WHERE i_b IS NOT NULL 
ORDER BY id;

-- Multipliziere alle i_b Werte mit 10
UPDATE devices 
SET i_b = i_b * 10 
WHERE i_b IS NOT NULL;

-- Zeige korrigierte Werte (NACH der Änderung)
SELECT 'NACHHER:' AS Status;
SELECT id, name, i_b 
FROM devices 
WHERE i_b IS NOT NULL 
ORDER BY id;

-- Zusammenfassung
SELECT 
    COUNT(*) AS anzahl_aktualisiert,
    MIN(i_b) AS min_wert,
    MAX(i_b) AS max_wert,
    AVG(i_b) AS durchschnitt
FROM devices 
WHERE i_b IS NOT NULL;
