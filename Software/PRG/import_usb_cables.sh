#!/bin/bash

# ============================================================================
# USB-Kabel Import Script
# ============================================================================
# Importiert 18 neue USB-Kabel in die Datenbank
# 
# Verwendung:
#   chmod +x import_usb_cables.sh
#   ./import_usb_cables.sh
# ============================================================================

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_DIR="/home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}USB-Kabel Import${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Prüfe ob im richtigen Verzeichnis
if [ ! -f "docker-compose.yml" ] && [ ! -f "podman-compose.yml" ]; then
    echo -e "${RED}❌ Fehler: Nicht im Projekt-Verzeichnis!${NC}"
    echo -e "${YELLOW}Bitte wechsle in: $BASE_DIR${NC}"
    exit 1
fi

# Prüfe ob SQL-Datei existiert
if [ ! -f "usb_cables_import.sql" ]; then
    echo -e "${RED}❌ Fehler: usb_cables_import.sql nicht gefunden!${NC}"
    echo -e "${YELLOW}Bitte kopiere die Datei ins Projekt-Verzeichnis.${NC}"
    exit 1
fi

echo -e "${YELLOW}Importiere 18 USB-Kabel...${NC}"
echo ""
echo -e "${BLUE}Details:${NC}"
echo -e "  Kunde: Miro"
echo -e "  IDs: Miro-00478 bis Miro-00495"
echo -e "  Typen: USB-C, Lightning, Micro-USB"
echo -e "  Hersteller: Apple, Samsung, Anker, Belkin"
echo -e "  Zeitraum: 13:38 - 14:20 Uhr"
echo ""

# Sicherheitsabfrage
read -p "Möchtest du fortfahren? (ja/nein): " CONFIRM

if [ "$CONFIRM" != "ja" ]; then
    echo -e "${BLUE}Abgebrochen.${NC}"
    exit 0
fi

# Backup erstellen
echo ""
echo -e "${YELLOW}Erstelle Sicherheits-Backup...${NC}"
BACKUP_FILE="backups/db_before_usb_import_$(date +%Y%m%d_%H%M%S).sql.gz"
mkdir -p backups

if podman-compose exec mysql mysqldump -u miro -pmiro miro_db 2>/dev/null | gzip > "$BACKUP_FILE"; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✅ Backup erstellt: $(basename "$BACKUP_FILE") ($BACKUP_SIZE)${NC}"
else
    echo -e "${YELLOW}⚠️  Backup fehlgeschlagen (fortfahren trotzdem)${NC}"
fi

# Import durchführen
echo ""
echo -e "${YELLOW}Importiere Daten...${NC}"

if podman-compose exec -T mysql mysql -u miro -pmiro miro_db < usb_cables_import.sql 2>/dev/null; then
    echo -e "${GREEN}✅ Import erfolgreich${NC}"
else
    echo -e "${RED}❌ Import fehlgeschlagen!${NC}"
    exit 1
fi

# Zeige Statistiken
echo ""
echo -e "${YELLOW}Prüfe Import...${NC}"

TOTAL_DEVICES=$(podman-compose exec -T mysql mysql -u miro -pmiro miro_db -e "SELECT COUNT(*) FROM devices;" 2>/dev/null | tail -1 | tr -d ' ')
USB_CABLES=$(podman-compose exec -T mysql mysql -u miro -pmiro miro_db -e "SELECT COUNT(*) FROM devices WHERE type = 'USB-Kabel';" 2>/dev/null | tail -1 | tr -d ' ')
NEW_CABLES=$(podman-compose exec -T mysql mysql -u miro -pmiro miro_db -e "SELECT COUNT(*) FROM devices WHERE customer_device_id >= 'Miro-00478' AND customer_device_id <= 'Miro-00495';" 2>/dev/null | tail -1 | tr -d ' ')

echo -e "${GREEN}✅ Gesamt Geräte: $TOTAL_DEVICES${NC}"
echo -e "${GREEN}✅ USB-Kabel gesamt: $USB_CABLES${NC}"
echo -e "${GREEN}✅ Neu importiert: $NEW_CABLES${NC}"

# Zeige letzte 5 Einträge
echo ""
echo -e "${BLUE}Letzte 5 importierte Einträge:${NC}"
podman-compose exec -T mysql mysql -u miro -pmiro miro_db -t -e "SELECT id, customer_device_id, name, cable_type, manufacturer, test_result, last_inspection FROM devices WHERE customer_device_id >= 'Miro-00478' ORDER BY id DESC LIMIT 5;" 2>/dev/null

# Erfolgs-Meldung
echo ""
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}✅ Import erfolgreich abgeschlossen!${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo -e "${BLUE}📊 Zusammenfassung:${NC}"
echo -e "   Importiert: 18 USB-Kabel"
echo -e "   IDs: Miro-00478 bis Miro-00495"
echo -e "   Backup: $(basename "$BACKUP_FILE")"
echo ""
echo -e "${BLUE}🔍 Alle neuen Einträge anzeigen:${NC}"
echo -e "   ${YELLOW}podman-compose exec mysql mysql -u miro -pmiro miro_db -t -e \"SELECT * FROM devices WHERE customer_device_id >= 'Miro-00478' ORDER BY id;\"${NC}"
echo ""
echo -e "${GREEN}Fertig! 🎉${NC}"
