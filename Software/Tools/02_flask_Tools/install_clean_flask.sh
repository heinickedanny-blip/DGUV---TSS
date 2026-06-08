#!/bin/bash

###############################################################################
# install_clean_flask.sh
# 
# Vollständige Neuinstallation der Flask-App mit USB-C Integration
# Version: 3.0 (Clean Install)
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Konfiguration
INSTALL_DIR="$HOME/Dokumente/vsCode/Benning-DGUV3/Software"
APP_DIR="$INSTALL_DIR/PRG_v3"
BACKUP_DIR="$INSTALL_DIR/BackUp/$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Benning Flask v3.0 - Clean Install                      ║${NC}"
echo -e "${BLUE}║  + USB-C Kabel-Prüfung Integration                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Prüfe ob alte Installation existiert
if [ -d "$INSTALL_DIR/PRG" ]; then
    echo -e "${YELLOW}⚠ Alte Installation gefunden: $INSTALL_DIR/PRG${NC}"
    echo -e "${YELLOW}Möchten Sie ein Backup erstellen? (j/n):${NC} "
    read -r BACKUP_CHOICE
    
    if [ "$BACKUP_CHOICE" = "j" ] || [ "$BACKUP_CHOICE" = "J" ]; then
        echo -e "${YELLOW}→ Erstelle Backup...${NC}"
        mkdir -p "$BACKUP_DIR"
        cp -r "$INSTALL_DIR/PRG" "$BACKUP_DIR/"
        echo -e "${GREEN}✓ Backup erstellt: $BACKUP_DIR${NC}"
    fi
fi

# Erstelle Verzeichnisse
echo -e "${YELLOW}→ Erstelle Verzeichnisstruktur...${NC}"
mkdir -p "$APP_DIR"/{templates,static/{css,uploads/usbc}}

echo -e "${GREEN}✓ Verzeichnisse erstellt${NC}"

# Erstelle requirements.txt
echo -e "${YELLOW}→ Erstelle requirements.txt...${NC}"

cat > "$APP_DIR/requirements.txt" << 'EOF'
Flask==3.0.0
mysql-connector-python==8.2.0
qrcode[pil]==7.4.2
reportlab==4.0.7
Werkzeug==3.0.1
python-dotenv==1.0.0
EOF

echo -e "${GREEN}✓ requirements.txt erstellt${NC}"

# Erstelle .gitignore
cat > "$APP_DIR/.gitignore" << 'EOF'
venv/
__pycache__/
*.pyc
.env
*.log
static/uploads/
EOF

# Python Virtual Environment
echo -e "${YELLOW}→ Erstelle Virtual Environment...${NC}"
cd "$APP_DIR"
python3 -m venv venv

echo -e "${YELLOW}→ Installiere Dependencies...${NC}"
./venv/bin/pip install --upgrade pip > /dev/null 2>&1
./venv/bin/pip install -r requirements.txt

echo -e "${GREEN}✓ Dependencies installiert${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ✓ Installation abgeschlossen!                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${MAGENTA}Nächste Schritte:${NC}"
echo ""
echo -e "1. Kopieren Sie die Dateien:"
echo -e "   ${YELLOW}cp app.py templates/* static/css/* $APP_DIR/${NC}"
echo ""
echo -e "2. Konfigurieren Sie .env:"
echo -e "   ${YELLOW}nano $APP_DIR/.env${NC}"
echo ""
echo -e "3. Starten Sie die App:"
echo -e "   ${YELLOW}cd $APP_DIR${NC}"
echo -e "   ${YELLOW}./venv/bin/python app.py${NC}"
echo ""
echo -e "Installation in: ${GREEN}$APP_DIR${NC}"
echo ""
