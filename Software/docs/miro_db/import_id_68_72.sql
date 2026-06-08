-- ============================================================================
-- Import von IDs 68-72 in miro_db
-- Zeitstempel: Fortlaufend +7 Minuten pro Eintrag
-- Start: 2026-02-18 18:11:00
-- ============================================================================

-- Sicherheitscheck: Zeige aktuelle höchste ID
SELECT MAX(id) AS 'Aktuelle höchste ID' FROM devices;

-- Daten einfügen
INSERT INTO devices (
    id, customer, customer_device_id, name, type, serial_number, manufacturer, model, 
    location, purchase_date, last_inspection, next_inspection, status, notes,
    r_pe, r_iso, i_pe, i_b, created_at, updated_at
) VALUES
-- ID 68: Monitor (18:11:00)
(68, 'Miro', 'Miro-00068', 'Monitor', 'Elektrogerät', NULL, 'Samsung', NULL,
 'Berlin - Büro', '2025-01-01', '2026-02-18', '2027-02-18', 'active', NULL,
 0.017, 20.000, NULL, 0.200, '2026-02-18 18:11:00', '2026-02-18 18:11:00'),

-- ID 69: Monitor (18:18:00 = +7 Min)
(69, 'Miro', 'Miro-00069', 'Monitor', 'Elektrogerät', NULL, 'Samsung', NULL,
 'Berlin - Büro', '2025-01-01', '2026-02-18', '2027-02-18', 'active', NULL,
 0.019, 20.000, NULL, 0.200, '2026-02-18 18:18:00', '2026-02-18 18:18:00'),

-- ID 70: Monitor (18:25:00 = +7 Min)
(70, 'Miro', 'Miro-00070', 'Monitor', 'Elektrogerät', NULL, 'Samsung', NULL,
 'Berlin - Büro', '2025-01-01', '2026-02-18', '2027-02-18', 'active', NULL,
 0.018, 20.000, NULL, 0.200, '2026-02-18 18:25:00', '2026-02-18 18:25:00'),

-- ID 71: Drucker (18:32:00 = +7 Min)
(71, 'Miro', 'Miro-00071', 'Drucker', 'Elektrogerät', NULL, 'HP', NULL,
 'Berlin - Büro', '2025-01-01', '2026-02-18', '2027-02-18', 'active', NULL,
 0.021, 20.000, NULL, 0.200, '2026-02-18 18:32:00', '2026-02-18 18:32:00'),

-- ID 72: Wasserkocher (18:39:00 = +7 Min)
(72, 'Miro', 'Miro-00072', 'Wasserkocher', 'Elektrogerät', NULL, 'Philips', NULL,
 'Berlin - Küche', '2025-01-01', '2026-02-18', '2027-02-18', 'active', NULL,
 0.015, 20.000, NULL, 0.200, '2026-02-18 18:39:00', '2026-02-18 18:39:00');

-- Prüfung: Zeige eingefügte Daten
SELECT id, name, type, r_pe, r_iso, i_b, created_at FROM devices WHERE id BETWEEN 68 AND 72;

-- Statistik
SELECT 
    'Anzahl Geräte' AS Info, 
    COUNT(*) AS Wert 
FROM devices;

-- Auto-Increment anpassen
ALTER TABLE devices AUTO_INCREMENT = 73;
