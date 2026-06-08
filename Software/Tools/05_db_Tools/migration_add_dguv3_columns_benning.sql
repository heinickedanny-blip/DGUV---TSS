-- ============================================================================
-- Migration: DGUV3 Prüfwerte zu devices-Tabelle hinzufügen
-- Datum: 2026-01-28
-- Beschreibung: Fügt vier neue Spalten für DGUV3-Prüfwerte hinzu
-- Benutzer: benning
-- ============================================================================

USE benning_device_manager;

-- Neue Spalten zur devices-Tabelle hinzufügen
ALTER TABLE devices
    ADD COLUMN r_pe DECIMAL(6,3) NULL COMMENT 'Schutzleiterwiderstand in Ohm (Grenzwert: < 0,3 Ω)',
    ADD COLUMN r_iso DECIMAL(8,3) NULL COMMENT 'Isolationswiderstand in MegaOhm (Grenzwert: > 1,0 MΩ)',
    ADD COLUMN i_pe DECIMAL(6,3) NULL COMMENT 'Schutzleiterstrom in mA (Grenzwert: < 3,5 mA)',
    ADD COLUMN i_b DECIMAL(6,3) NULL COMMENT 'Berührungsstrom in mA (Grenzwert: < 0,5 mA)';

-- Indizes für bessere Performance bei Abfragen
CREATE INDEX idx_r_pe ON devices(r_pe);
CREATE INDEX idx_r_iso ON devices(r_iso);
CREATE INDEX idx_i_pe ON devices(i_pe);
CREATE INDEX idx_i_b ON devices(i_b);

-- Bestätigung der Änderungen
DESC devices;

-- ============================================================================
-- Migration erfolgreich abgeschlossen!
-- ============================================================================
