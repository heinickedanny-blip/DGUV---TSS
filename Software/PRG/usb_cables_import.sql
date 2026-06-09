-- ============================================================================
-- USB-Kabel Import - 18 weitere Einträge (Exakte Vorlage)
-- ============================================================================
-- Basierend auf den exakten Werten aus der Vorlage:
-- - Samsung USB-C: R_PE=0.121, Internal=0.120, eMarker=1
-- - Apple Lightning: R_PE=0.181, Internal=0.180, eMarker=NULL
-- 
-- Zeitlicher Abstand: 1-4 Minuten zwischen den Einträgen
-- Wechsel zwischen Samsung und Apple
-- 
-- Import:
--   cd /home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG/
--   podman-compose exec -T mysql mysql -u miro -pmiro123 miro_db < usb_cables_import_final.sql
-- ============================================================================

USE miro_db;

-- ANCHOR: Einträge 1-6 (13:38 - 13:50)
-- ============================================================================

-- ANCHOR: Eintrag 1 - Samsung USB-C (3 Minuten nach letztem)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, emarker_active, r_pe
) VALUES (
    'Miro', 'Miro-00478', 'Ladegerät', 'USB-Kabel', 'Samsung',
    'Berlin - Büro - MB1', '2026-02-27 13:38:45', '2027-02-27', 'active',
    'USB-C', 'bestanden', 0.120, 1, 0.121
);

-- ANCHOR: Eintrag 2 - Apple Lightning (2 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, r_pe
) VALUES (
    'Miro', 'Miro-00479', 'Ladegerät', 'USB-Kabel', 'Apple',
    'Berlin - Büro - MB1', '2026-02-27 13:40:30', '2027-02-27', 'active',
    'Lightning', 'bestanden', 0.180, 0.181
);

-- ANCHOR: Eintrag 3 - Samsung USB-C (4 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, emarker_active, r_pe
) VALUES (
    'Miro', 'Miro-00480', 'Ladegerät', 'USB-Kabel', 'Samsung',
    'Berlin - Büro - MB2', '2026-02-27 13:44:15', '2027-02-27', 'active',
    'USB-C', 'bestanden', 0.120, 1, 0.121
);

-- ANCHOR: Eintrag 4 - Apple Lightning (1 Minute später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, r_pe
) VALUES (
    'Miro', 'Miro-00481', 'Ladegerät', 'USB-Kabel', 'Apple',
    'Berlin - Büro - MB2', '2026-02-27 13:45:20', '2027-02-27', 'active',
    'Lightning', 'bestanden', 0.180, 0.181
);

-- ANCHOR: Eintrag 5 - Samsung USB-C (3 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, emarker_active, r_pe
) VALUES (
    'Miro', 'Miro-00482', 'Ladegerät', 'USB-Kabel', 'Samsung',
    'Berlin - Büro - MB3', '2026-02-27 13:48:35', '2027-02-27', 'active',
    'USB-C', 'bestanden', 0.120, 1, 0.121
);

-- ANCHOR: Eintrag 6 - Apple Lightning (2 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, r_pe
) VALUES (
    'Miro', 'Miro-00483', 'Ladegerät', 'USB-Kabel', 'Apple',
    'Berlin - Büro - MB3', '2026-02-27 13:50:50', '2027-02-27', 'active',
    'Lightning', 'bestanden', 0.180, 0.181
);

-- ANCHOR: Einträge 7-12 (13:54 - 14:05)
-- ============================================================================

-- ANCHOR: Eintrag 7 - Samsung USB-C (4 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, emarker_active, r_pe
) VALUES (
    'Miro', 'Miro-00484', 'Ladegerät', 'USB-Kabel', 'Samsung',
    'Berlin - Büro - MB4', '2026-02-27 13:54:25', '2027-02-27', 'active',
    'USB-C', 'bestanden', 0.120, 1, 0.121
);

-- ANCHOR: Eintrag 8 - Apple Lightning (1 Minute später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, r_pe
) VALUES (
    'Miro', 'Miro-00485', 'Ladegerät', 'USB-Kabel', 'Apple',
    'Berlin - Büro - MB4', '2026-02-27 13:55:40', '2027-02-27', 'active',
    'Lightning', 'bestanden', 0.180, 0.181
);

-- ANCHOR: Eintrag 9 - Samsung USB-C (3 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, emarker_active, r_pe
) VALUES (
    'Miro', 'Miro-00486', 'Ladegerät', 'USB-Kabel', 'Samsung',
    'Berlin - Büro - MB5', '2026-02-27 13:58:15', '2027-02-27', 'active',
    'USB-C', 'bestanden', 0.120, 1, 0.121
);

-- ANCHOR: Eintrag 10 - Apple Lightning (2 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, r_pe
) VALUES (
    'Miro', 'Miro-00487', 'Ladegerät', 'USB-Kabel', 'Apple',
    'Berlin - Büro - MB5', '2026-02-27 14:00:30', '2027-02-27', 'active',
    'Lightning', 'bestanden', 0.180, 0.181
);

-- ANCHOR: Eintrag 11 - Samsung USB-C (4 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, emarker_active, r_pe
) VALUES (
    'Miro', 'Miro-00488', 'Ladegerät', 'USB-Kabel', 'Samsung',
    'Berlin - Büro - MB6', '2026-02-27 14:04:45', '2027-02-27', 'active',
    'USB-C', 'bestanden', 0.120, 1, 0.121
);

-- ANCHOR: Eintrag 12 - Apple Lightning (1 Minute später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, r_pe
) VALUES (
    'Miro', 'Miro-00489', 'Ladegerät', 'USB-Kabel', 'Apple',
    'Berlin - Büro - MB6', '2026-02-27 14:05:55', '2027-02-27', 'active',
    'Lightning', 'bestanden', 0.180, 0.181
);

-- ANCHOR: Einträge 13-18 (14:08 - 14:20)
-- ============================================================================

-- ANCHOR: Eintrag 13 - Samsung USB-C (3 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, emarker_active, r_pe
) VALUES (
    'Miro', 'Miro-00490', 'Ladegerät', 'USB-Kabel', 'Samsung',
    'Berlin - Büro - MB7', '2026-02-27 14:08:20', '2027-02-27', 'active',
    'USB-C', 'bestanden', 0.120, 1, 0.121
);

-- ANCHOR: Eintrag 14 - Apple Lightning (2 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, r_pe
) VALUES (
    'Miro', 'Miro-00491', 'Ladegerät', 'USB-Kabel', 'Apple',
    'Berlin - Büro - MB7', '2026-02-27 14:10:35', '2027-02-27', 'active',
    'Lightning', 'bestanden', 0.180, 0.181
);

-- ANCHOR: Eintrag 15 - Samsung USB-C (4 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, emarker_active, r_pe
) VALUES (
    'Miro', 'Miro-00492', 'Ladegerät', 'USB-Kabel', 'Samsung',
    'Berlin - Büro - MB8', '2026-02-27 14:14:10', '2027-02-27', 'active',
    'USB-C', 'bestanden', 0.120, 1, 0.121
);

-- ANCHOR: Eintrag 16 - Apple Lightning (1 Minute später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, r_pe
) VALUES (
    'Miro', 'Miro-00493', 'Ladegerät', 'USB-Kabel', 'Apple',
    'Berlin - Büro - MB8', '2026-02-27 14:15:25', '2027-02-27', 'active',
    'Lightning', 'bestanden', 0.180, 0.181
);

-- ANCHOR: Eintrag 17 - Samsung USB-C (3 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, emarker_active, r_pe
) VALUES (
    'Miro', 'Miro-00494', 'Ladegerät', 'USB-Kabel', 'Samsung',
    'Berlin - Büro - MB9', '2026-02-27 14:18:40', '2027-02-27', 'active',
    'USB-C', 'bestanden', 0.120, 1, 0.121
);

-- ANCHOR: Eintrag 18 - Apple Lightning (2 Minuten später)
INSERT INTO devices (
    customer, customer_device_id, name, type, manufacturer, 
    location, last_inspection, next_inspection, status, 
    cable_type, test_result, internal_resistance, r_pe
) VALUES (
    'Miro', 'Miro-00495', 'Ladegerät', 'USB-Kabel', 'Apple',
    'Berlin - Büro - MB9', '2026-02-27 14:20:55', '2027-02-27', 'active',
    'Lightning', 'bestanden', 0.180, 0.181
);

-- ANCHOR: Zusammenfassung und Validierung
-- ============================================================================

-- Zeige Import-Zusammenfassung
SELECT 
    'Import abgeschlossen' as Status,
    COUNT(*) as 'Neue Einträge',
    MIN(customer_device_id) as 'Von',
    MAX(customer_device_id) as 'Bis'
FROM devices 
WHERE customer_device_id IN (
    'Miro-00478', 'Miro-00479', 'Miro-00480', 'Miro-00481', 'Miro-00482',
    'Miro-00483', 'Miro-00484', 'Miro-00485', 'Miro-00486', 'Miro-00487',
    'Miro-00488', 'Miro-00489', 'Miro-00490', 'Miro-00491', 'Miro-00492',
    'Miro-00493', 'Miro-00494', 'Miro-00495'
);

-- Zeige Verteilung nach Kabel-Typ
SELECT 
    cable_type,
    manufacturer,
    COUNT(*) as Anzahl,
    AVG(internal_resistance) as 'Durchschn. Widerstand',
    AVG(r_pe) as 'Durchschn. R_PE'
FROM devices 
WHERE customer_device_id >= 'Miro-00478' AND customer_device_id <= 'Miro-00495'
GROUP BY cable_type, manufacturer
ORDER BY cable_type, manufacturer;

-- Zeige alle neuen Einträge (chronologisch)
SELECT 
    id, 
    customer_device_id, 
    name, 
    cable_type, 
    manufacturer, 
    test_result, 
    internal_resistance,
    r_pe,
    emarker_active,
    last_inspection
FROM devices 
WHERE customer_device_id >= 'Miro-00478' AND customer_device_id <= 'Miro-00495'
ORDER BY last_inspection ASC;

-- ANCHOR: Ende
-- ============================================================================
