#!/bin/bash

###############################################################################
# fix_duplicate_routes_v2.sh
# 
# Entfernt doppelte USB-C Routen aus app.py
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_FILE="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/PRG/app.py"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Doppelte USB-C Routen entfernen                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ! -f "$APP_FILE" ]; then
    echo -e "${RED}✗ app.py nicht gefunden: $APP_FILE${NC}"
    exit 1
fi

# Prüfe Anzahl der USB-C Routen
COUNT=$(grep -c "def usbc_inspection" "$APP_FILE" || true)

echo -e "${YELLOW}Gefundene 'usbc_inspection' Funktionen: $COUNT${NC}"

if [ "$COUNT" -eq 0 ]; then
    echo -e "${RED}✗ Keine USB-C Routen gefunden${NC}"
    echo "Führen Sie zuerst patch_app_usbc.sh aus"
    exit 1
fi

if [ "$COUNT" -eq 1 ]; then
    echo -e "${GREEN}✓ Keine Duplikate gefunden (nur 1 Funktion)${NC}"
    echo ""
    echo -e "${YELLOW}Aber der Fehler trat trotzdem auf?${NC}"
    echo "Prüfen Sie, ob die Route mehrfach dekoriert ist:"
    echo ""
    grep -B2 "def usbc_inspection" "$APP_FILE"
    echo ""
    exit 0
fi

# Backup erstellen
BACKUP_FILE="${APP_FILE}.fix_backup_$(date +%Y%m%d_%H%M%S)"
cp "$APP_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup erstellt: $BACKUP_FILE${NC}"

# Entferne Duplikate mit Python
echo -e "${YELLOW}→ Entferne Duplikate...${NC}"

cat > /tmp/fix_duplicates.py << 'EOFPYTHON'
import re
import sys

app_file = sys.argv[1]

with open(app_file, 'r') as f:
    content = f.read()

# Finde alle USB-C Routen-Blöcke
pattern = r'# ============================================================================\n# USB-C KABEL-PRÜFUNG ERWEITERUNG\n# ============================================================================.*?(?=\n@app\.route|if __name__)'

matches = list(re.finditer(pattern, content, re.DOTALL))

print(f"Gefundene USB-C Blöcke: {len(matches)}")

if len(matches) > 1:
    # Behalte nur den ersten Block
    # Entferne alle anderen
    new_content = content
    for match in reversed(matches[1:]):  # Rückwärts, um Indizes nicht zu verschieben
        new_content = new_content[:match.start()] + new_content[match.end():]
    
    with open(app_file, 'w') as f:
        f.write(new_content)
    
    print(f"✓ {len(matches) - 1} Duplikat(e) entfernt")
elif len(matches) == 1:
    print("Nur 1 USB-C Block gefunden, keine Duplikate")
else:
    print("Keine USB-C Blöcke gefunden")
EOFPYTHON

python3 /tmp/fix_duplicates.py "$APP_FILE"

echo -e "${GREEN}✓ Bereinigung abgeschlossen${NC}"
echo ""
echo "Prüfe Ergebnis:"
COUNT_AFTER=$(grep -c "def usbc_inspection" "$APP_FILE" || true)
echo "  usbc_inspection Funktionen: $COUNT_AFTER"
echo ""

if [ "$COUNT_AFTER" -eq 1 ]; then
    echo -e "${GREEN}✓ Perfekt! Nur noch 1 Funktion vorhanden${NC}"
else
    echo -e "${YELLOW}⚠ Immer noch $COUNT_AFTER Funktionen${NC}"
    echo "Möglicherweise müssen Sie manuell bereinigen"
fi

echo ""
echo "Starten Sie Flask neu:"
echo "  cd ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG"
echo "  ./venv/bin/python app.py"
echo ""
