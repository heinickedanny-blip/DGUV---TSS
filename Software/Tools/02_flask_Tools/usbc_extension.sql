-- USB-C Kabel-Prüfung Erweiterung für Benning Device Manager
-- Datum: 2025-01-22

USE benning_device_manager;

-- Neue Tabelle: usbc_inspections (USB-C spezifische Prüfungen)
CREATE TABLE IF NOT EXISTS usbc_inspections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    inspection_id INT NOT NULL,
    
    -- 1. Vorbereitung
    device_functional BOOLEAN DEFAULT false,
    battery_checked BOOLEAN DEFAULT false,
    cable_visual_ok BOOLEAN DEFAULT false,
    cable_id VARCHAR(100),
    
    -- 2. Schnelltest
    cable_connected BOOLEAN DEFAULT false,
    basic_functions_ok BOOLEAN DEFAULT false,
    protocols_detected TEXT,  -- JSON: ["USB 2.0", "USB 3.2", "DP Alt Mode", "Thunderbolt"]
    
    -- 3. Detailprüfung
    pinout_photo_path VARCHAR(500),
    resistance_test_done BOOLEAN DEFAULT false,
    emarker_present BOOLEAN DEFAULT false,
    emarker_data TEXT,  -- JSON: {"vendor": "...", "product": "...", "current": "5A"}
    
    -- 4. Bewertung
    all_tests_passed BOOLEAN DEFAULT false,
    test_result ENUM('passed', 'failed', 'conditional') DEFAULT 'passed',
    test_date DATE NOT NULL,
    inspector_name VARCHAR(255),
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (inspection_id) REFERENCES inspections(id) ON DELETE CASCADE,
    INDEX idx_inspection (inspection_id),
    INDEX idx_test_date (test_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Neue Tabelle: usbc_resistance_tests (Widerstandsmessungen)
CREATE TABLE IF NOT EXISTS usbc_resistance_tests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usbc_inspection_id INT NOT NULL,
    
    -- Pin-Messungen
    pin_name VARCHAR(20) NOT NULL,  -- z.B. "VBUS", "CC1", "CC2", "D+", "D-", "TX1+", "TX1-", etc.
    resistance_value DECIMAL(10, 3),  -- in Ohm
    expected_min DECIMAL(10, 3),
    expected_max DECIMAL(10, 3),
    passed BOOLEAN DEFAULT true,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (usbc_inspection_id) REFERENCES usbc_inspections(id) ON DELETE CASCADE,
    INDEX idx_usbc_inspection (usbc_inspection_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Neue Tabelle: usbc_protocol_tests (Protokoll-Tests)
CREATE TABLE IF NOT EXISTS usbc_protocol_tests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usbc_inspection_id INT NOT NULL,
    
    protocol_name VARCHAR(100) NOT NULL,  -- "USB 2.0", "USB 3.2 Gen 2", "DisplayPort", "Thunderbolt 3"
    supported BOOLEAN DEFAULT false,
    speed_mbps INT,  -- Geschwindigkeit in Mbps
    power_delivery BOOLEAN DEFAULT false,
    max_power_w DECIMAL(5, 1),  -- Maximale Leistung in Watt
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (usbc_inspection_id) REFERENCES usbc_inspections(id) ON DELETE CASCADE,
    INDEX idx_usbc_inspection (usbc_inspection_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Neue Tabelle: usbc_photos (Foto-Archiv)
CREATE TABLE IF NOT EXISTS usbc_photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usbc_inspection_id INT NOT NULL,
    
    photo_type ENUM('pinout', 'cable', 'connector', 'emarker', 'damage', 'other') NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size INT,  -- in Bytes
    mime_type VARCHAR(100),
    description TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (usbc_inspection_id) REFERENCES usbc_inspections(id) ON DELETE CASCADE,
    INDEX idx_usbc_inspection (usbc_inspection_id),
    INDEX idx_photo_type (photo_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Erweitere devices Tabelle um USB-C spezifische Felder (optional)
ALTER TABLE devices 
ADD COLUMN IF NOT EXISTS cable_length DECIMAL(5, 2) COMMENT 'Kabellänge in Metern',
ADD COLUMN IF NOT EXISTS cable_type VARCHAR(100) COMMENT 'z.B. USB-C to USB-C, USB-C to USB-A',
ADD COLUMN IF NOT EXISTS max_power_rating VARCHAR(50) COMMENT 'z.B. 100W, 240W',
ADD COLUMN IF NOT EXISTS usb_version VARCHAR(50) COMMENT 'z.B. USB 3.2 Gen 2, USB4';

-- Beispiel-Daten für USB-C Kabel
INSERT INTO devices (id, name, type, location, manufacturer, serial_number, purchase_date, status, cable_length, cable_type, max_power_rating, usb_version) VALUES
('USBC-001', 'USB-C Kabel 2m Thunderbolt 4', 'USB-C Kabel', 'IT-Abteilung', 'Anker', 'ANK-TB4-2024-001', '2024-01-15', 'active', 2.0, 'USB-C to USB-C', '100W', 'USB4 / Thunderbolt 4'),
('USBC-002', 'USB-C Ladekabel 1m', 'USB-C Kabel', 'Werkstatt A', 'Belkin', 'BLK-USBC-2024-045', '2024-02-20', 'active', 1.0, 'USB-C to USB-C', '60W', 'USB 3.2 Gen 2'),
('USBC-003', 'USB-C auf USB-A Adapter', 'USB-C Adapter', 'Lager', 'UGREEN', 'UGR-ADP-2023-123', '2023-11-10', 'active', 0.15, 'USB-C to USB-A', '10W', 'USB 3.0')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Standard Pin-Definitionen für USB-C (als Referenz)
CREATE TABLE IF NOT EXISTS usbc_pin_reference (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pin_name VARCHAR(20) NOT NULL UNIQUE,
    pin_number VARCHAR(10),
    function_description TEXT,
    typical_resistance_min DECIMAL(10, 3),
    typical_resistance_max DECIMAL(10, 3),
    critical BOOLEAN DEFAULT false COMMENT 'Kritischer Pin für Funktion'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Standard USB-C Pins einfügen
INSERT INTO usbc_pin_reference (pin_name, pin_number, function_description, typical_resistance_min, typical_resistance_max, critical) VALUES
('VBUS', 'A4/A9/B4/B9', 'Power delivery (+5V bis +20V)', 0.0, 0.5, true),
('GND', 'A1/A12/B1/B12', 'Ground', 0.0, 0.3, true),
('CC1', 'A5', 'Configuration Channel 1', 0.8, 1.2, true),
('CC2', 'B5', 'Configuration Channel 2', 0.8, 1.2, true),
('D+', 'A6', 'USB 2.0 Data+', 0.0, 0.5, false),
('D-', 'A7', 'USB 2.0 Data-', 0.0, 0.5, false),
('TX1+', 'A2', 'SuperSpeed TX Lane 1+', 0.0, 0.3, false),
('TX1-', 'A3', 'SuperSpeed TX Lane 1-', 0.0, 0.3, false),
('RX1+', 'A10', 'SuperSpeed RX Lane 1+', 0.0, 0.3, false),
('RX1-', 'A11', 'SuperSpeed RX Lane 1-', 0.0, 0.3, false),
('TX2+', 'B2', 'SuperSpeed TX Lane 2+', 0.0, 0.3, false),
('TX2-', 'B3', 'SuperSpeed TX Lane 2-', 0.0, 0.3, false),
('RX2+', 'B10', 'SuperSpeed RX Lane 2+', 0.0, 0.3, false),
('RX2-', 'B11', 'SuperSpeed RX Lane 2-', 0.0, 0.3, false),
('SBU1', 'A8', 'Sideband Use 1', NULL, NULL, false),
('SBU2', 'B8', 'Sideband Use 2', NULL, NULL, false)
ON DUPLICATE KEY UPDATE function_description=VALUES(function_description);

-- View für vollständige USB-C Prüfungsübersicht
CREATE OR REPLACE VIEW usbc_inspection_overview AS
SELECT 
    d.id AS device_id,
    d.name AS device_name,
    d.cable_type,
    d.cable_length,
    d.max_power_rating,
    i.id AS inspection_id,
    i.inspection_date,
    i.inspector_name,
    u.id AS usbc_inspection_id,
    u.cable_id,
    u.protocols_detected,
    u.emarker_present,
    u.all_tests_passed,
    u.test_result,
    u.pinout_photo_path,
    COUNT(DISTINCT r.id) AS resistance_tests_count,
    COUNT(DISTINCT p.id) AS protocol_tests_count,
    COUNT(DISTINCT ph.id) AS photos_count
FROM devices d
LEFT JOIN inspections i ON d.id = i.device_id
LEFT JOIN usbc_inspections u ON i.id = u.inspection_id
LEFT JOIN usbc_resistance_tests r ON u.id = r.usbc_inspection_id
LEFT JOIN usbc_protocol_tests p ON u.id = p.usbc_inspection_id
LEFT JOIN usbc_photos ph ON u.id = ph.usbc_inspection_id
WHERE d.type LIKE '%USB-C%' OR d.type LIKE '%Kabel%'
GROUP BY d.id, i.id, u.id
ORDER BY i.inspection_date DESC;

-- Beispiel-Prüfung für USBC-001
SET @device_id = 'USBC-001';
SET @inspection_id = NULL;

-- Erstelle Basis-Prüfung
INSERT INTO inspections (device_id, inspection_date, inspector_name, result, notes, next_inspection_date)
VALUES (@device_id, CURDATE(), 'Max Mustermann', 'passed', 'USB-C Kabel vollständig geprüft', DATE_ADD(CURDATE(), INTERVAL 1 YEAR));

SET @inspection_id = LAST_INSERT_ID();

-- Erstelle USB-C spezifische Prüfung
INSERT INTO usbc_inspections (
    inspection_id, 
    device_functional, battery_checked, cable_visual_ok, cable_id,
    cable_connected, basic_functions_ok, protocols_detected,
    resistance_test_done, emarker_present, emarker_data,
    all_tests_passed, test_result, test_date, inspector_name
) VALUES (
    @inspection_id,
    true, true, true, 'USBC-001',
    true, true, '["USB 3.2 Gen 2", "DisplayPort Alt Mode", "Power Delivery 3.0", "Thunderbolt 4"]',
    true, true, '{"vendor": "Intel", "product": "Thunderbolt 4 Cable", "max_current": "5A", "max_voltage": "20V"}',
    true, 'passed', CURDATE(), 'Max Mustermann'
);

SET @usbc_inspection_id = LAST_INSERT_ID();

-- Füge Widerstandsmessungen hinzu
INSERT INTO usbc_resistance_tests (usbc_inspection_id, pin_name, resistance_value, expected_min, expected_max, passed) VALUES
(@usbc_inspection_id, 'VBUS', 0.15, 0.0, 0.5, true),
(@usbc_inspection_id, 'GND', 0.08, 0.0, 0.3, true),
(@usbc_inspection_id, 'CC1', 1.0, 0.8, 1.2, true),
(@usbc_inspection_id, 'CC2', 1.05, 0.8, 1.2, true),
(@usbc_inspection_id, 'TX1+', 0.12, 0.0, 0.3, true),
(@usbc_inspection_id, 'TX1-', 0.11, 0.0, 0.3, true),
(@usbc_inspection_id, 'RX1+', 0.13, 0.0, 0.3, true),
(@usbc_inspection_id, 'RX1-', 0.12, 0.0, 0.3, true);

-- Füge Protokoll-Tests hinzu
INSERT INTO usbc_protocol_tests (usbc_inspection_id, protocol_name, supported, speed_mbps, power_delivery, max_power_w) VALUES
(@usbc_inspection_id, 'USB 3.2 Gen 2', true, 10000, false, NULL),
(@usbc_inspection_id, 'DisplayPort Alt Mode', true, NULL, false, NULL),
(@usbc_inspection_id, 'Power Delivery 3.0', true, NULL, true, 100),
(@usbc_inspection_id, 'Thunderbolt 4', true, 40000, true, 100);

-- Erfolgsmeldung
SELECT 
    'USB-C Erweiterung erfolgreich installiert!' AS status,
    COUNT(DISTINCT TABLE_NAME) AS neue_tabellen
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'benning_device_manager' 
AND TABLE_NAME LIKE 'usbc_%';
