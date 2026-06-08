-- ============================================================================
-- Füge USB-Kabel Inspektionsfelder zur devices Tabelle hinzu
-- ============================================================================
-- Diese Felder werden vom Formular verwendet, fehlen aber möglicherweise in der Datenbank

-- Prüfe zuerst ob die Felder bereits existieren
-- Falls sie existieren, wird ein Fehler angezeigt (kann ignoriert werden)

ALTER TABLE devices ADD COLUMN cable_type VARCHAR(100) DEFAULT NULL COMMENT 'USB-Kabeltyp (USB-C, Lightning, etc.)';
ALTER TABLE devices ADD COLUMN test_result VARCHAR(50) DEFAULT NULL COMMENT 'Testergebnis (bestanden, nicht_bestanden, etc.)';
ALTER TABLE devices ADD COLUMN internal_resistance DECIMAL(10,3) DEFAULT NULL COMMENT 'Innenwiderstand in Ohm';
ALTER TABLE devices ADD COLUMN emarker_active BOOLEAN DEFAULT NULL COMMENT 'eMarker Status (nur USB-C)';
ALTER TABLE devices ADD COLUMN inspection_notes TEXT DEFAULT NULL COMMENT 'Inspektionsnotizen';

-- Zeige die aktualisierte Tabellenstruktur
DESC devices;
