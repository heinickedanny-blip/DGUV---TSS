-- ============================================================================
-- Benning / DGUV3 Device Manager - vollständiges MySQL-Schema
-- ============================================================================
-- Dieses Schema ist für die Podman-Initialisierung geeignet. Die Datenbank
-- selbst wird vom MySQL-Container über MYSQL_DATABASE aus .env angelegt.
-- ============================================================================

CREATE TABLE IF NOT EXISTS devices (
    id INT PRIMARY KEY AUTO_INCREMENT,

    -- Kundenfelder
    customer VARCHAR(255) NOT NULL COMMENT 'Kundenname / Kundenpräfix, z. B. TSS',
    customer_device_id VARCHAR(255) UNIQUE DEFAULT NULL COMMENT 'Formatierte Kunden-ID: Kunde-00001',

    -- Gerätedaten
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100) DEFAULT NULL,
    serial_number VARCHAR(255) DEFAULT NULL,
    manufacturer VARCHAR(255) DEFAULT NULL,
    model VARCHAR(255) DEFAULT NULL,
    location VARCHAR(255) DEFAULT NULL,
    purchase_date DATE DEFAULT NULL,
    last_inspection DATE DEFAULT NULL,
    next_inspection DATE DEFAULT NULL,
    status ENUM('active', 'inactive', 'maintenance', 'retired') DEFAULT 'active',
    qr_code LONGBLOB DEFAULT NULL COMMENT 'QR-Code als PNG/Base64',
    notes TEXT DEFAULT NULL,

    -- DGUV3-Prüfwerte
    r_pe DECIMAL(6,3) DEFAULT NULL COMMENT 'Schutzleiterwiderstand in Ohm, Grenzwert typischerweise < 0,3 Ω',
    r_iso DECIMAL(8,3) DEFAULT NULL COMMENT 'Isolationswiderstand in MΩ',
    i_pe DECIMAL(6,3) DEFAULT NULL COMMENT 'Schutzleiterstrom in mA',
    i_b DECIMAL(6,3) DEFAULT NULL COMMENT 'Berührungs-/Ableitstrom in mA',

    -- USB-Kabel-Inspektionsfelder
    cable_type VARCHAR(100) DEFAULT NULL COMMENT 'USB-Kabeltyp, z. B. USB-C, Lightning, Micro-USB',
    test_result VARCHAR(50) DEFAULT NULL COMMENT 'Testergebnis, z. B. bestanden oder nicht_bestanden',
    internal_resistance DECIMAL(10,3) DEFAULT NULL COMMENT 'Innenwiderstand in Ohm',
    emarker_active BOOLEAN DEFAULT NULL COMMENT 'eMarker Status, nur USB-C',
    inspection_notes TEXT DEFAULT NULL COMMENT 'Inspektionsnotizen',

    -- Zeitstempel
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Indizes
    INDEX idx_customer (customer),
    INDEX idx_customer_device_id (customer_device_id),
    INDEX idx_name (name),
    INDEX idx_serial (serial_number),
    INDEX idx_status (status),
    INDEX idx_created (created_at),
    INDEX idx_next_inspection (next_inspection),
    INDEX idx_r_pe (r_pe),
    INDEX idx_r_iso (r_iso),
    INDEX idx_i_pe (i_pe),
    INDEX idx_i_b (i_b),
    INDEX idx_cable_type (cable_type),
    INDEX idx_test_result (test_result)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inspections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    device_id INT NOT NULL,
    inspection_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    result ENUM('pass', 'fail', 'pending') DEFAULT 'pending',
    notes TEXT DEFAULT NULL,
    inspector VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
    INDEX idx_device (device_id),
    INDEX idx_date (inspection_date),
    INDEX idx_result (result)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'inspector', 'viewer') DEFAULT 'viewer',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT DEFAULT NULL,
    action VARCHAR(100) DEFAULT NULL,
    entity_type VARCHAR(100) DEFAULT NULL,
    entity_id INT DEFAULT NULL,
    changes JSON DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Schema erfolgreich erstellt.
-- ============================================================================
