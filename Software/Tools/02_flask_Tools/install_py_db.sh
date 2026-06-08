#!/bin/bash

###############################################################################
# install_py_db.sh
# 
# Installiert und konfiguriert MySQL-Datenbank für Benning Flask App
# - Erstellt Podman/Docker Container mit MySQL 8.0
# - Richtet Datenbank-Schema ein
# - Fügt Beispieldaten ein
# - Konfiguriert .env für Flask-App
###############################################################################

set -e  # Bei Fehler abbrechen

# Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Konfiguration
CONTAINER_NAME="benning-flask-mysql"
DB_NAME="benning_device_manager"
DB_USER="benning"
DB_PASSWORD="benning"
DB_ROOT_PASSWORD="benning_root_2024"
DB_PORT="3307"  # Anderer Port als Standard, um Konflikte zu vermeiden
FLASK_DIR="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/PRG"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Benning Flask - MySQL Datenbank Installation             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Prüfe ob Podman oder Docker verfügbar ist
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
    echo -e "${GREEN}✓ Podman gefunden${NC}"
elif command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
    echo -e "${GREEN}✓ Docker gefunden${NC}"
else
    echo -e "${RED}✗ Fehler: Weder Podman noch Docker gefunden!${NC}"
    echo "Bitte installieren Sie Podman oder Docker:"
    echo "  sudo apt install podman"
    exit 1
fi

# Prüfe ob Container bereits existiert
if $CONTAINER_CMD ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}⚠ Container '${CONTAINER_NAME}' existiert bereits${NC}"
    read -p "Möchten Sie ihn löschen und neu erstellen? (j/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[JjYy]$ ]]; then
        echo -e "${YELLOW}→ Stoppe und lösche alten Container...${NC}"
        $CONTAINER_CMD stop $CONTAINER_NAME 2>/dev/null || true
        $CONTAINER_CMD rm $CONTAINER_NAME 2>/dev/null || true
    else
        echo -e "${YELLOW}→ Verwende bestehenden Container${NC}"
        $CONTAINER_CMD start $CONTAINER_NAME 2>/dev/null || true
        sleep 3
        # Springe zur Konfiguration
        EXISTING_CONTAINER=true
    fi
fi

# Erstelle neuen Container (falls nicht existierend)
if [ "$EXISTING_CONTAINER" != "true" ]; then
    echo -e "${BLUE}→ Erstelle MySQL Container '${CONTAINER_NAME}'...${NC}"
    
    $CONTAINER_CMD run -d \
        --name $CONTAINER_NAME \
        -e MYSQL_ROOT_PASSWORD=$DB_ROOT_PASSWORD \
        -e MYSQL_DATABASE=$DB_NAME \
        -e MYSQL_USER=$DB_USER \
        -e MYSQL_PASSWORD=$DB_PASSWORD \
        -p $DB_PORT:3306 \
        mysql:8.0 \
        --character-set-server=utf8mb4 \
        --collation-server=utf8mb4_unicode_ci
    
    echo -e "${GREEN}✓ Container erstellt${NC}"
    
    # Warte bis MySQL bereit ist
    echo -e "${YELLOW}→ Warte auf MySQL-Start (max. 60 Sekunden)...${NC}"
    for i in {1..60}; do
        if $CONTAINER_CMD exec $CONTAINER_NAME mysqladmin ping -h localhost -u root -p$DB_ROOT_PASSWORD --silent &> /dev/null; then
            echo -e "${GREEN}✓ MySQL ist bereit!${NC}"
            break
        fi
        echo -n "."
        sleep 1
        if [ $i -eq 60 ]; then
            echo -e "${RED}✗ Timeout: MySQL startet nicht${NC}"
            exit 1
        fi
    done
    echo ""
fi

# Erstelle Datenbank-Schema
echo -e "${BLUE}→ Erstelle Datenbank-Schema...${NC}"

# SQL-Schema in temporäre Datei schreiben
cat > /tmp/benning_schema.sql << 'EOF'
-- Benning Device Manager - Datenbank Schema

USE benning_device_manager;

-- Tabelle: devices (Geräte)
CREATE TABLE IF NOT EXISTS devices (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    location VARCHAR(255),
    manufacturer VARCHAR(100),
    serial_number VARCHAR(100),
    purchase_date DATE,
    last_inspection DATE,
    next_inspection DATE,
    status ENUM('active', 'inactive', 'defect') DEFAULT 'active',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabelle: inspections (Prüfungen)
CREATE TABLE IF NOT EXISTS inspections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    inspection_date DATE NOT NULL,
    inspector_name VARCHAR(255),
    result ENUM('passed', 'failed', 'conditional') DEFAULT 'passed',
    notes TEXT,
    next_inspection_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
    INDEX idx_device_date (device_id, inspection_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabelle: measurements (Messwerte)
CREATE TABLE IF NOT EXISTS measurements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    inspection_id INT NOT NULL,
    measurement_type VARCHAR(100) NOT NULL,
    value DECIMAL(10, 3),
    unit VARCHAR(20),
    min_value DECIMAL(10, 3),
    max_value DECIMAL(10, 3),
    passed BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (inspection_id) REFERENCES inspections(id) ON DELETE CASCADE,
    INDEX idx_inspection (inspection_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabelle: company_settings (Firmendaten für PDF)
CREATE TABLE IF NOT EXISTS company_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(255),
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(100),
    logo_path VARCHAR(500),
    signature_path VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Beispieldaten einfügen
INSERT INTO devices (id, name, type, location, manufacturer, serial_number, purchase_date, last_inspection, next_inspection, status) VALUES
('BENNING-001', 'Bohrmaschine Makita', 'Elektrowerkzeug', 'Werkstatt A', 'Makita', 'MK-2024-001', '2024-01-15', '2024-06-15', '2025-06-15', 'active'),
('BENNING-002', 'Winkelschleifer Bosch', 'Elektrowerkzeug', 'Werkstatt A', 'Bosch', 'BS-2024-002', '2024-02-20', '2024-07-20', '2025-07-20', 'active'),
('BENNING-003', 'Verlängerungskabel 25m', 'Kabel', 'Lager', 'Brennenstuhl', 'BR-2023-045', '2023-11-10', '2024-05-10', '2025-05-10', 'active'),
('BENNING-004', 'Staubsauger Kärcher', 'Reinigungsgerät', 'Werkstatt B', 'Kärcher', 'KA-2024-012', '2024-03-05', '2024-08-05', '2025-08-05', 'active'),
('BENNING-005', 'Schweißgerät MIG/MAG', 'Schweißtechnik', 'Werkstatt C', 'Lorch', 'LO-2023-089', '2023-09-15', '2024-03-15', '2025-03-15', 'active')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- Beispiel-Prüfung
INSERT INTO inspections (device_id, inspection_date, inspector_name, result, notes, next_inspection_date) VALUES
('BENNING-001', '2024-06-15', 'Max Mustermann', 'passed', 'Alle Messwerte im Normbereich', '2025-06-15')
ON DUPLICATE KEY UPDATE inspection_date=VALUES(inspection_date);

-- Beispiel-Messwerte
SET @last_inspection_id = LAST_INSERT_ID();
INSERT INTO measurements (inspection_id, measurement_type, value, unit, min_value, max_value, passed) VALUES
(@last_inspection_id, 'Isolationswiderstand', 50.5, 'MΩ', 1.0, NULL, true),
(@last_inspection_id, 'Schutzleiterwiderstand', 0.15, 'Ω', NULL, 0.3, true),
(@last_inspection_id, 'Ableitstrom', 0.25, 'mA', NULL, 0.5, true)
ON DUPLICATE KEY UPDATE value=VALUES(value);

-- Firmeneinstellungen
INSERT INTO company_settings (company_name, address, phone, email) VALUES
('Musterfirma GmbH', 'Musterstraße 123\n12345 Musterstadt', '+49 123 456789', 'info@musterfirma.de')
ON DUPLICATE KEY UPDATE company_name=VALUES(company_name);

EOF

# Schema in Container importieren
echo -e "${YELLOW}→ Importiere Schema...${NC}"

# Versuche erst mit vordefiniertem Passwort
if $CONTAINER_CMD exec -i $CONTAINER_NAME mysql -u root -p$DB_ROOT_PASSWORD < /tmp/benning_schema.sql 2>/dev/null; then
    echo -e "${GREEN}✓ Schema erfolgreich erstellt${NC}"
    rm /tmp/benning_schema.sql
else
    echo -e "${YELLOW}⚠ Automatische Authentifizierung fehlgeschlagen${NC}"
    echo -e "${CYAN}Bitte geben Sie das MySQL Root-Passwort ein:${NC}"
    echo ""
    
    # Interaktive Eingabe mit mysql -p (mit -it für Terminal-Interaktion)
    # Kopiere Schema-Datei in Container für einfacheren Zugriff
    $CONTAINER_CMD cp /tmp/benning_schema.sql $CONTAINER_NAME:/tmp/schema.sql
    
    if $CONTAINER_CMD exec -it $CONTAINER_NAME sh -c 'mysql -u root -p < /tmp/schema.sql'; then
        echo -e "${GREEN}✓ Schema erfolgreich erstellt${NC}"
        rm /tmp/benning_schema.sql
    else
        echo -e "${RED}✗ Fehler beim Schema-Import${NC}"
        echo ""
        echo -e "${YELLOW}Mögliche Lösungen:${NC}"
        echo "1. Prüfen Sie das Root-Passwort"
        echo "2. Verwenden Sie: bash fix_mysql_db.sh"
        echo "3. Manueller Import:"
        echo "   $CONTAINER_CMD exec -it $CONTAINER_NAME mysql -u root -p"
        echo "   Dann: source /tmp/benning_schema.sql;"
        exit 1
    fi
fi

# Konfiguriere Flask .env
echo -e "${BLUE}→ Konfiguriere Flask-App (.env)...${NC}"

if [ -d "$FLASK_DIR" ]; then
    cat > "$FLASK_DIR/.env" << EOF
# Benning Flask - Datenbank-Konfiguration
# Generiert von install_py_db.sh am $(date)

DB_HOST=localhost
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME

# Flask-Konfiguration
FLASK_ENV=development
FLASK_DEBUG=1
SECRET_KEY=$(openssl rand -hex 32)

# Vollständige Connection-String
DATABASE_URL=mysql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}
EOF
    echo -e "${GREEN}✓ .env erstellt in $FLASK_DIR${NC}"
else
    echo -e "${YELLOW}⚠ Flask-Verzeichnis nicht gefunden: $FLASK_DIR${NC}"
    echo "Bitte erstellen Sie manuell eine .env-Datei mit folgenden Inhalten:"
    echo ""
    echo "DB_HOST=localhost"
    echo "DB_PORT=$DB_PORT"
    echo "DB_USER=$DB_USER"
    echo "DB_PASSWORD=$DB_PASSWORD"
    echo "DB_NAME=$DB_NAME"
fi

# Erstelle Management-Script
echo -e "${BLUE}→ Erstelle Management-Script (manage_flask_db.sh)...${NC}"

cat > "$HOME/Dokumente/vsCode/Benning-DGUV3/manage_flask_db.sh" << 'MANAGE_EOF'
#!/bin/bash

# Benning Flask - Datenbank Management Script

CONTAINER_NAME="benning-flask-mysql"
DB_USER="benning"
DB_PASSWORD="benning"
DB_NAME="benning_device_manager"

# Prüfe Container-Tool
if command -v podman &> /dev/null; then
    CMD="podman"
elif command -v docker &> /dev/null; then
    CMD="docker"
else
    echo "Fehler: Weder Podman noch Docker gefunden!"
    exit 1
fi

case "$1" in
    start)
        echo "→ Starte MySQL Container..."
        $CMD start $CONTAINER_NAME
        echo "✓ Container gestartet"
        ;;
    stop)
        echo "→ Stoppe MySQL Container..."
        $CMD stop $CONTAINER_NAME
        echo "✓ Container gestoppt"
        ;;
    restart)
        echo "→ Starte MySQL Container neu..."
        $CMD restart $CONTAINER_NAME
        echo "✓ Container neu gestartet"
        ;;
    status)
        echo "→ Container Status:"
        $CMD ps -a | grep $CONTAINER_NAME
        ;;
    shell)
        echo "→ Öffne MySQL Shell..."
        $CMD exec -it $CONTAINER_NAME mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME
        ;;
    logs)
        echo "→ Container Logs:"
        $CMD logs $CONTAINER_NAME
        ;;
    backup)
        BACKUP_FILE="benning_backup_$(date +%Y%m%d_%H%M%S).sql"
        echo "→ Erstelle Backup: $BACKUP_FILE"
        $CMD exec $CONTAINER_NAME mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME > "$BACKUP_FILE"
        echo "✓ Backup erstellt: $BACKUP_FILE"
        ;;
    *)
        echo "Benning Flask - Datenbank Management"
        echo ""
        echo "Verwendung: $0 {start|stop|restart|status|shell|logs|backup}"
        echo ""
        echo "Befehle:"
        echo "  start    - Startet den Container"
        echo "  stop     - Stoppt den Container"
        echo "  restart  - Startet den Container neu"
        echo "  status   - Zeigt Container-Status"
        echo "  shell    - Öffnet MySQL Shell"
        echo "  logs     - Zeigt Container-Logs"
        echo "  backup   - Erstellt Datenbank-Backup"
        exit 1
        ;;
esac
MANAGE_EOF

chmod +x "$HOME/Dokumente/vsCode/Benning-DGUV3/manage_flask_db.sh"
echo -e "${GREEN}✓ Management-Script erstellt${NC}"

# Zusammenfassung
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ Installation erfolgreich abgeschlossen!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Datenbank-Informationen:${NC}"
echo "  Container:  $CONTAINER_NAME"
echo "  Host:       localhost"
echo "  Port:       $DB_PORT"
echo "  Datenbank:  $DB_NAME"
echo "  Benutzer:   $DB_USER"
echo "  Passwort:   $DB_PASSWORD"
echo ""
echo -e "${BLUE}Beispieldaten:${NC}"
echo "  ✓ 5 Geräte (BENNING-001 bis BENNING-005)"
echo "  ✓ 1 Beispiel-Prüfung mit Messwerten"
echo "  ✓ Firmeneinstellungen"
echo ""
echo -e "${BLUE}Flask-App starten:${NC}"
echo "  cd $FLASK_DIR"
echo "  ./venv/bin/python app.py"
echo ""
echo -e "${BLUE}Datenbank verwalten:${NC}"
echo "  ~/Dokumente/vsCode/Benning-DGUV3/manage_flask_db.sh {start|stop|shell|backup}"
echo ""
echo -e "${BLUE}MySQL Shell öffnen:${NC}"
echo "  $CONTAINER_CMD exec -it $CONTAINER_NAME mysql -u $DB_USER -p$DB_PASSWORD $DB_NAME"
echo ""
echo -e "${GREEN}Viel Erfolg! 🚀${NC}"
