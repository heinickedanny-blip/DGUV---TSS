#!/bin/bash

# ============================================================================
# DGUV3 Datenbank Restore Script
# ============================================================================
# Stellt ein Datenbank-Backup wieder her
#
# Verwendung:
#   chmod +x db_restore.sh
#   ./db_restore.sh [backup_datei.sql.gz]
#
# Beispiel:
#   ./db_restore.sh backups/db_20260226_155446.sql.gz
# ============================================================================

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Konfiguration
BASE_DIR="/home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG"
BACKUP_DIR="$BASE_DIR/backups"

# Datenbank-Konfiguration
DB_NAME="miro_db"
DB_USER="miro"
DB_PASS="miro123"
CONTAINER_NAME="benning-mysql"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}DGUV3 Datenbank Restore${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Backup-Datei aus Argument oder wähle neuestes
if [ -n "$1" ]; then
    BACKUP_FILE="$1"
else
    # Finde neuestes Backup
    BACKUP_FILE=$(ls -t "$BACKUP_DIR"/db_*.sql* 2>/dev/null | head -1)
fi

# Prüfe ob Backup-Datei existiert
if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Keine Backup-Datei gefunden!${NC}"
    echo ""
    echo -e "${YELLOW}Verfügbare Backups:${NC}"
    ls -lht "$BACKUP_DIR"/db_*.sql* 2>/dev/null | head -10 | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
    echo -e "${YELLOW}Verwendung: $0 [backup_datei]${NC}"
    exit 1
fi

echo -e "${BLUE}Backup-Datei: ${YELLOW}$BACKUP_FILE${NC}"
echo -e "${BLUE}Datenbank: ${YELLOW}$DB_NAME${NC}"
echo -e "${BLUE}Container: ${YELLOW}$CONTAINER_NAME${NC}"
echo ""

# Wechsle ins Projekt-Verzeichnis
cd "$BASE_DIR"

# Sicherheitsabfrage
echo -e "${RED}⚠️  WARNUNG: Diese Aktion überschreibt die aktuelle Datenbank!${NC}"
echo ""
read -p "Möchtest du fortfahren? (ja/nein): " CONFIRM

if [ "$CONFIRM" != "ja" ]; then
    echo -e "${BLUE}Abgebrochen.${NC}"
    exit 0
fi

# Erstelle Backup der aktuellen Datenbank
echo ""
echo -e "${YELLOW}Erstelle Backup der aktuellen Datenbank...${NC}"
SAFETY_BACKUP="$BACKUP_DIR/db_before_restore_$(date +%Y%m%d_%H%M%S).sql.gz"

if command -v podman-compose &> /dev/null; then
    podman-compose exec -T mysql mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null | gzip > "$SAFETY_BACKUP" || true
elif command -v podman &> /dev/null; then
    podman exec "$CONTAINER_NAME" mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null | gzip > "$SAFETY_BACKUP" || true
fi

if [ -f "$SAFETY_BACKUP" ] && [ -s "$SAFETY_BACKUP" ]; then
    echo -e "${GREEN}✅ Sicherheits-Backup erstellt: $SAFETY_BACKUP${NC}"
else
    echo -e "${YELLOW}⚠️  Sicherheits-Backup fehlgeschlagen (fortfahren trotzdem)${NC}"
fi

# Dekomprimiere Backup falls nötig
RESTORE_FILE="$BACKUP_FILE"
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo ""
    echo -e "${YELLOW}Dekomprimiere Backup...${NC}"
    RESTORE_FILE="${BACKUP_FILE%.gz}"
    gunzip -c "$BACKUP_FILE" > "$RESTORE_FILE"
    echo -e "${GREEN}✅ Dekomprimiert${NC}"
fi

# Restore durchführen
echo ""
echo -e "${YELLOW}Stelle Datenbank wieder her...${NC}"

RESTORE_SUCCESS=false

# Methode 1: podman-compose exec
if command -v podman-compose &> /dev/null; then
    echo -e "${BLUE}Versuche: podman-compose exec...${NC}"
    if podman-compose exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$RESTORE_FILE" 2>/dev/null; then
        RESTORE_SUCCESS=true
        echo -e "${GREEN}✅ Restore erfolgreich mit podman-compose${NC}"
    fi
fi

# Methode 2: podman exec
if [ "$RESTORE_SUCCESS" = false ] && command -v podman &> /dev/null; then
    echo -e "${BLUE}Versuche: podman exec...${NC}"
    if cat "$RESTORE_FILE" | podman exec -i "$CONTAINER_NAME" mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null; then
        RESTORE_SUCCESS=true
        echo -e "${GREEN}✅ Restore erfolgreich mit podman exec${NC}"
    fi
fi

# Methode 3: docker exec
if [ "$RESTORE_SUCCESS" = false ] && command -v docker &> /dev/null; then
    echo -e "${BLUE}Versuche: docker exec...${NC}"
    if cat "$RESTORE_FILE" | docker exec -i "$CONTAINER_NAME" mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null; then
        RESTORE_SUCCESS=true
        echo -e "${GREEN}✅ Restore erfolgreich mit docker exec${NC}"
    fi
fi

# Methode 4: mysql client über Host-Port
if [ "$RESTORE_SUCCESS" = false ] && command -v mysql &> /dev/null; then
    echo -e "${BLUE}Versuche: mysql client über Port 3307...${NC}"
    if mysql -h 127.0.0.1 -P 3307 -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$RESTORE_FILE" 2>/dev/null; then
        RESTORE_SUCCESS=true
        echo -e "${GREEN}✅ Restore erfolgreich mit mysql client${NC}"
    fi
fi

# Lösche temporäre dekomprimierte Datei
if [[ "$BACKUP_FILE" == *.gz ]] && [ -f "$RESTORE_FILE" ]; then
    rm "$RESTORE_FILE"
fi

# Prüfe Erfolg
if [ "$RESTORE_SUCCESS" = false ]; then
    echo -e "${RED}❌ Restore fehlgeschlagen!${NC}"
    echo ""
    echo -e "${YELLOW}Versuche manuell:${NC}"
    echo -e "  gunzip -c $BACKUP_FILE | podman-compose exec -T mysql mysql -u miro -pmiro123 miro_db"
    exit 1
fi

# Zeige Datenbank-Status
echo ""
echo -e "${YELLOW}Prüfe Datenbank-Status...${NC}"

if command -v podman-compose &> /dev/null; then
    TABLE_COUNT=$(podman-compose exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SHOW TABLES;" 2>/dev/null | wc -l)
    DEVICE_COUNT=$(podman-compose exec -T mysql mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT COUNT(*) FROM devices;" 2>/dev/null | tail -1)
    
    echo -e "${GREEN}✅ Anzahl Tabellen: $TABLE_COUNT${NC}"
    echo -e "${GREEN}✅ Anzahl Geräte: $DEVICE_COUNT${NC}"
fi

echo ""
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}✅ Datenbank erfolgreich wiederhergestellt!${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo -e "${BLUE}Wiederhergestellt von:${NC}"
echo -e "  ${YELLOW}$BACKUP_FILE${NC}"
echo ""
echo -e "${BLUE}Sicherheits-Backup:${NC}"
echo -e "  ${YELLOW}$SAFETY_BACKUP${NC}"
echo ""
echo -e "${YELLOW}Container neu starten:${NC}"
echo -e "  podman-compose restart flask"
echo ""
echo -e "${GREEN}Fertig! 🎉${NC}"
