#!/bin/bash

# ============================================================================
# DGUV3 Datenbank Backup Script
# ============================================================================
# Erstellt ein vollständiges Backup der miro_db Datenbank
#
# Verwendung:
#   chmod +x db_backup.sh
#   ./db_backup.sh
#
# Backup wird gespeichert in: backups/db_YYYYMMDD_HHMMSS.sql
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
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/db_$TIMESTAMP.sql"
COMPRESSED_FILE="$BACKUP_DIR/db_$TIMESTAMP.sql.gz"

# Datenbank-Konfiguration
DB_NAME="miro_db"
DB_USER="miro"
DB_PASS="miro123"
CONTAINER_NAME="benning-mysql"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}DGUV3 Datenbank Backup${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Backup-Verzeichnis erstellen
mkdir -p "$BACKUP_DIR"

# Wechsle ins Projekt-Verzeichnis
cd "$BASE_DIR"

echo -e "${YELLOW}Erstelle Datenbank-Backup...${NC}"
echo -e "${BLUE}Datenbank: $DB_NAME${NC}"
echo -e "${BLUE}Container: $CONTAINER_NAME${NC}"
echo ""

# Backup erstellen (versuche verschiedene Methoden)
BACKUP_SUCCESS=false

# Methode 1: podman-compose exec
if command -v podman-compose &> /dev/null; then
    echo -e "${YELLOW}Versuche: podman-compose exec...${NC}"
    if podman-compose exec -T mysql mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null; then
        BACKUP_SUCCESS=true
        echo -e "${GREEN}✅ Backup erstellt mit podman-compose${NC}"
    fi
fi

# Methode 2: podman exec
if [ "$BACKUP_SUCCESS" = false ] && command -v podman &> /dev/null; then
    echo -e "${YELLOW}Versuche: podman exec...${NC}"
    if podman exec "$CONTAINER_NAME" mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null; then
        BACKUP_SUCCESS=true
        echo -e "${GREEN}✅ Backup erstellt mit podman exec${NC}"
    fi
fi

# Methode 3: docker exec
if [ "$BACKUP_SUCCESS" = false ] && command -v docker &> /dev/null; then
    echo -e "${YELLOW}Versuche: docker exec...${NC}"
    if docker exec "$CONTAINER_NAME" mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null; then
        BACKUP_SUCCESS=true
        echo -e "${GREEN}✅ Backup erstellt mit docker exec${NC}"
    fi
fi

# Methode 4: mysqldump über Host-Port
if [ "$BACKUP_SUCCESS" = false ] && command -v mysqldump &> /dev/null; then
    echo -e "${YELLOW}Versuche: mysqldump über Port 3307...${NC}"
    if mysqldump -h 127.0.0.1 -P 3307 -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null; then
        BACKUP_SUCCESS=true
        echo -e "${GREEN}✅ Backup erstellt mit mysqldump client${NC}"
    fi
fi

# Prüfe ob Backup erfolgreich war
if [ "$BACKUP_SUCCESS" = false ]; then
    echo -e "${RED}❌ Backup fehlgeschlagen!${NC}"
    echo ""
    echo -e "${YELLOW}Versuche manuell:${NC}"
    echo -e "  podman-compose exec mysql mysqldump -u miro -pmiro123 miro_db > backups/db_manual.sql"
    exit 1
fi

# Prüfe Backup-Größe
if [ ! -s "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Backup-Datei ist leer!${NC}"
    exit 1
fi

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo -e "${GREEN}✅ Backup-Größe: $BACKUP_SIZE${NC}"

# Komprimiere Backup
echo ""
echo -e "${YELLOW}Komprimiere Backup...${NC}"
gzip -c "$BACKUP_FILE" > "$COMPRESSED_FILE"

if [ -f "$COMPRESSED_FILE" ]; then
    COMPRESSED_SIZE=$(du -h "$COMPRESSED_FILE" | cut -f1)
    echo -e "${GREEN}✅ Komprimiert: $COMPRESSED_SIZE${NC}"
    
    # Lösche unkomprimiertes Backup
    rm "$BACKUP_FILE"
    echo -e "${GREEN}✅ Unkomprimiertes Backup gelöscht${NC}"
else
    echo -e "${YELLOW}⚠️  Komprimierung fehlgeschlagen, behalte unkomprimiertes Backup${NC}"
    COMPRESSED_FILE="$BACKUP_FILE"
fi

# Zeige Backup-Informationen
echo ""
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}✅ Backup erfolgreich erstellt!${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo -e "${BLUE}Backup-Datei:${NC}"
echo -e "  ${YELLOW}$COMPRESSED_FILE${NC}"
echo ""
echo -e "${BLUE}Backup-Größe:${NC}"
if [ -f "$COMPRESSED_FILE" ]; then
    ls -lh "$COMPRESSED_FILE" | awk '{print "  " $5 " (" $9 ")"}'
fi
echo ""

# Zeige Anzahl der Tabellen im Backup
TABLE_COUNT=$(grep -c "CREATE TABLE" "$COMPRESSED_FILE" 2>/dev/null || zgrep -c "CREATE TABLE" "$COMPRESSED_FILE" 2>/dev/null || echo "?")
echo -e "${BLUE}Anzahl Tabellen: ${YELLOW}$TABLE_COUNT${NC}"
echo ""

# Zeige letzte 5 Backups
echo -e "${BLUE}Letzte 5 Backups:${NC}"
ls -lht "$BACKUP_DIR"/db_*.sql* 2>/dev/null | head -5 | awk '{print "  " $9 " (" $5 ")"}'
echo ""

# Alte Backups löschen (älter als 30 Tage)
OLD_BACKUPS=$(find "$BACKUP_DIR" -name "db_*.sql*" -type f -mtime +30 2>/dev/null | wc -l)
if [ "$OLD_BACKUPS" -gt 0 ]; then
    echo -e "${YELLOW}Gefunden: $OLD_BACKUPS alte Backups (älter als 30 Tage)${NC}"
    read -p "Möchtest du diese löschen? (ja/nein): " DELETE_OLD
    if [ "$DELETE_OLD" = "ja" ]; then
        find "$BACKUP_DIR" -name "db_*.sql*" -type f -mtime +30 -delete
        echo -e "${GREEN}✅ Alte Backups gelöscht${NC}"
    fi
fi

echo ""
echo -e "${BLUE}Backup wiederherstellen:${NC}"
echo -e "  ${YELLOW}./db_restore.sh $COMPRESSED_FILE${NC}"
echo ""
echo -e "${GREEN}Fertig! 🎉${NC}"
