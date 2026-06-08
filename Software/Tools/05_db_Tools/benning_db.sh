#!/bin/bash

# ============================================================================
# Benning Device Manager - Datenbank Setup Script
# Initialisiert die komplette Datenbank-Struktur
# ============================================================================

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Konfiguration
DB_USER="benning"
DB_PASSWORD="benning"
DB_ROOT_PASSWORD="root"
DB_NAME="benning_device_manager"
MYSQL_CONTAINER="benning-mysql"

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# 1. ÜBERPRÜFE CONTAINER
# ============================================================================

check_container() {
    print_header "1. ÜBERPRÜFE MYSQL CONTAINER"
    
    if ! podman ps | grep -q "benning-mysql"; then
        print_error "MySQL Container läuft nicht!"
        echo "Starte mit: podman-compose up -d"
        exit 1
    fi
    
    print_success "MySQL Container läuft"
    echo ""
}

# ============================================================================
# 2. ERSTELLE DATENBANK
# ============================================================================

create_database() {
    print_header "2. ERSTELLE DATENBANK"
    
    print_info "Erstelle Datenbank '$DB_NAME'..."
    
    podman exec "$MYSQL_CONTAINER" mysql -u root -p"$DB_ROOT_PASSWORD" -e \
        "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    
    print_success "Datenbank erstellt"
    echo ""
}

# ============================================================================
# 3. ERSTELLE DEVICES TABELLE
# ============================================================================

create_devices_table() {
    print_header "3. ERSTELLE DEVICES TABELLE"
    
    print_info "Erstelle 'devices' Tabelle..."
    
    podman exec -i "$MYSQL_CONTAINER" mysql -u root -p"$DB_ROOT_PASSWORD" "$DB_NAME" << 'EOF' 2>/dev/null
CREATE TABLE IF NOT EXISTS devices (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer VARCHAR(255) NOT NULL COMMENT 'Kundenname für ID-Format',
    device_id VARCHAR(255) UNIQUE NOT NULL COMMENT 'Formatierte ID: Kunde-00001',
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    serial_number VARCHAR(255) UNIQUE,
    manufacturer VARCHAR(255),
    model VARCHAR(255),
    location VARCHAR(255),
    purchase_date DATE,
    last_inspection DATE,
    next_inspection DATE,
    status ENUM('active', 'inactive', 'maintenance', 'retired') DEFAULT 'active',
    qr_code LONGBLOB COMMENT 'QR-Code als PNG/Base64',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer (customer),
    INDEX idx_device_id (device_id),
    INDEX idx_name (name),
    INDEX idx_serial (serial_number),
    INDEX idx_status (status),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF
    
    print_success "Devices Tabelle erstellt"
    echo ""
}

# ============================================================================
# 4. ERSTELLE INSPECTIONS TABELLE
# ============================================================================

create_inspections_table() {
    print_header "4. ERSTELLE INSPECTIONS TABELLE"
    
    print_info "Erstelle 'inspections' Tabelle..."
    
    podman exec -i "$MYSQL_CONTAINER" mysql -u root -p"$DB_ROOT_PASSWORD" "$DB_NAME" << 'EOF' 2>/dev/null
CREATE TABLE IF NOT EXISTS inspections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    device_id INT NOT NULL,
    inspection_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    result ENUM('pass', 'fail', 'pending') DEFAULT 'pending',
    notes TEXT,
    inspector VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
    INDEX idx_device (device_id),
    INDEX idx_date (inspection_date),
    INDEX idx_result (result)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF
    
    print_success "Inspections Tabelle erstellt"
    echo ""
}

# ============================================================================
# 5. ERSTELLE USERS TABELLE
# ============================================================================

create_users_table() {
    print_header "5. ERSTELLE USERS TABELLE"
    
    print_info "Erstelle 'users' Tabelle..."
    
    podman exec -i "$MYSQL_CONTAINER" mysql -u root -p"$DB_ROOT_PASSWORD" "$DB_NAME" << 'EOF' 2>/dev/null
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
EOF
    
    print_success "Users Tabelle erstellt"
    echo ""
}

# ============================================================================
# 6. ERSTELLE AUDIT LOG TABELLE
# ============================================================================

create_audit_log_table() {
    print_header "6. ERSTELLE AUDIT LOG TABELLE"
    
    print_info "Erstelle 'audit_log' Tabelle..."
    
    podman exec -i "$MYSQL_CONTAINER" mysql -u root -p"$DB_ROOT_PASSWORD" "$DB_NAME" << 'EOF' 2>/dev/null
CREATE TABLE IF NOT EXISTS audit_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    action VARCHAR(100),
    entity_type VARCHAR(100),
    entity_id INT,
    changes JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF
    
    print_success "Audit Log Tabelle erstellt"
    echo ""
}

# ============================================================================
# 7. ÜBERPRÜFE TABELLEN
# ============================================================================

verify_tables() {
    print_header "7. ÜBERPRÜFE TABELLEN"
    
    print_info "Überprüfe erstellte Tabellen..."
    
    TABLES=$(podman exec "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES;" 2>/dev/null | tail -n +2)
    
    for table in devices inspections users audit_log; do
        if echo "$TABLES" | grep -q "^$table$"; then
            print_success "Tabelle '$table' existiert"
        else
            print_error "Tabelle '$table' existiert nicht!"
        fi
    done
    
    echo ""
}

# ============================================================================
# 8. ÜBERPRÜFE DEVICES STRUKTUR
# ============================================================================

verify_devices_structure() {
    print_header "8. ÜBERPRÜFE DEVICES STRUKTUR"
    
    print_info "Überprüfe Spalten in 'devices' Tabelle..."
    
    echo ""
    podman exec "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "DESC devices;" 2>/dev/null
    
    echo ""
}

# ============================================================================
# 9. ZUSAMMENFASSUNG
# ============================================================================

print_summary() {
    print_header "SETUP ABGESCHLOSSEN"
    
    echo "Benning Device Manager Datenbank wurde erfolgreich initialisiert!"
    echo ""
    print_info "Datenbank: $DB_NAME"
    print_info "Container: $MYSQL_CONTAINER"
    print_info "Benutzer: $DB_USER"
    echo ""
    print_success "Alle Tabellen erstellt und überprüft"
    echo ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    print_header "BENNING DEVICE MANAGER - DATENBANK SETUP"
    
    check_container
    create_database
    create_devices_table
    create_inspections_table
    create_users_table
    create_audit_log_table
    verify_tables
    verify_devices_structure
    print_summary
}

main
[2026-01-24 21:55:21 +0000] [1] [INFO] Using worker: sync
[2026-01-24 21:55:21 +0000] [7] [INFO] Booting worker with pid: 7
[2026-01-24 21:55:21 +0000] [8] [INFO] Booting worker with pid: 8
[2026-01-24 21:55:21 +0000] [9] [INFO] Booting worker with pid: 9
[2026-01-24 21:55:22 +0000] [10] [INFO] Booting worker with pid: 10
10.89.0.141 - - [24/Jan/2026:21:55:33 +0000] "GET /quick-add HTTP/1.1" 200 6019 "http://localhost:5000/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:33 +0000] "GET /static/css/style.css HTTP/1.1" 304 0 "http://localhost:5000/quick-add" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:33 +0000] "GET /.well-known/appspecific/com.chrome.devtools.json HTTP/1.1" 404 207 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:35 +0000] "GET /quick-add HTTP/1.1" 200 6019 "http://localhost:5000/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:35 +0000] "GET /.well-known/appspecific/com.chrome.devtools.json HTTP/1.1" 404 207 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:35 +0000] "GET /static/css/style.css HTTP/1.1" 200 0 "http://localhost:5000/quick-add" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:35 +0000] "GET /favicon.ico HTTP/1.1" 404 207 "http://localhost:5000/quick-add" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:36 +0000] "GET /quick-add HTTP/1.1" 200 6019 "http://localhost:5000/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:36 +0000] "GET /static/css/style.css HTTP/1.1" 304 0 "http://localhost:5000/quick-add" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:36 +0000] "GET /.well-known/appspecific/com.chrome.devtools.json HTTP/1.1" 404 207 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:40 +0000] "GET /api/devices/next-id?customer=Parloa HTTP/1.1" 200 21 "http://localhost:5000/quick-add" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:55:56 +0000] "POST /api/devices HTTP/1.1" 201 97 "http://localhost:5000/quick-add" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:56:01 +0000] "GET /devices HTTP/1.1" 200 1471 "http://localhost:5000/quick-add" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:56:01 +0000] "GET /.well-known/appspecific/com.chrome.devtools.json HTTP/1.1" 404 207 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:56:01 +0000] "GET /static/css/style.css HTTP/1.1" 304 0 "http://localhost:5000/devices" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:56:11 +0000] "GET /devices HTTP/1.1" 200 1471 "http://localhost:5000/devices" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:56:11 +0000] "GET /static/css/style.css HTTP/1.1" 304 0 "http://localhost:5000/devices" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:56:14 +0000] "GET /quick-add HTTP/1.1" 200 6019 "http://localhost:5000/devices" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:56:14 +0000] "GET /static/css/style.css HTTP/1.1" 304 0 "http://localhost:5000/quick-add" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36"
10.89.0.141 - - [24/Jan/2026:21:57:55 +0000] "GET /api/devices HTTP/1.1" 200 779 "-" "curl/8.18.0"
10.89.0.141 - - [24/Jan/2026:21:57:55 +0000] "GET /api/devices/next-id HTTP/1.1" 200 21 "-" "curl/8.18.0"
10.89.0.141 - - [24/Jan/2026:21:57:55 +0000] "GET / HTTP/1.1" 200 1702 "-" "curl/8.18.0"
10.89.0.141 - - [24/Jan/2026:21:57:55 +0000] "GET /quick-add HTTP/1.1" 200 6019 "-" "curl/8.18.0"
10.89.0.141 - - [24/Jan/2026:21:57:55 +0000] "GET /devices HTTP/1.1" 200 1471 "-" "curl/8.18.0"
10.89.0.141 - - [24/Jan/2026:21:57:55 +0000] "POST /api/devices HTTP/1.1" 201 101 "-" "curl/8.18.0"
