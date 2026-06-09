#!/usr/bin/env bash

# ============================================================================
# Benning / DGUV3 Device Manager - Podman-Projektinstallation
# ============================================================================
# Zweck:
#   Installiert bzw. startet das bestehende Projekt als Podman-Compose-Stack.
#   Die Datenbank wird beim ersten Start automatisch aus Software/PRG/init-db
#   initialisiert. Datenbankname, Benutzer und Standardkunde stehen in .env.
#
# Nutzung:
#   bash Software/Tools/05_db_Tools/install_dguv3_podman_project.sh Software/PRG
#   oder aus Software/PRG heraus:
#   bash ../Tools/05_db_Tools/install_dguv3_podman_project.sh .
# ============================================================================

set -euo pipefail

PROJECT_PATH="${1:-.}"

printf '\nBenning / DGUV3 Device Manager - Podman Installation\n'
printf '====================================================\n\n'

if [ ! -d "$PROJECT_PATH" ]; then
    echo "FEHLER: Projektpfad nicht gefunden: $PROJECT_PATH"
    exit 1
fi

cd "$PROJECT_PATH"
echo "Projektpfad: $(pwd)"

if ! command -v podman >/dev/null 2>&1; then
    echo "FEHLER: Podman ist nicht installiert."
    echo "Hinweis: Installiere auf CachyOS/Arch z. B. podman und podman-compose."
    echo "Im Repository gibt es dafür: Software/Tools/05_db_Tools/install_podman_cachyos.sh"
    exit 1
fi

if ! command -v podman-compose >/dev/null 2>&1; then
    echo "FEHLER: podman-compose ist nicht installiert."
    echo "Hinweis: Installiere podman-compose über den Paketmanager deines Systems."
    exit 1
fi

for required_file in Dockerfile.benning podman-compose.yml schema.sql; do
    if [ ! -f "$required_file" ]; then
        echo "FEHLER: $required_file fehlt. Bitte im Verzeichnis Software/PRG ausführen."
        exit 1
    fi
done

mkdir -p init-db logs static/uploads
cp schema.sql init-db/01_schema.sql

if [ ! -f .env ]; then
    if [ -f env.template ]; then
        cp env.template .env
        echo ".env wurde aus env.template erstellt."
    elif [ -f .env.example ]; then
        cp .env.example .env
        echo ".env wurde aus .env.example erstellt."
    else
        cat > .env <<'EOF'
DB_HOST=mysql
DB_PORT=3306
DB_USER=dguv3
DB_PASSWORD=change_me_dguv3
DB_NAME=dguv3_db
DB_ROOT_PASSWORD=change_me_root
DB_HOST_PORT=3307
DEFAULT_CUSTOMER=TSS
FLASK_APP=src.main
FLASK_ENV=production
FLASK_DEBUG=False
FLASK_PORT=5000
SECRET_KEY=change-me-to-a-long-random-secret
LOG_LEVEL=INFO
PYTHONUNBUFFERED=1
PYTHONOPTIMIZE=2
EOF
        echo ".env wurde mit Standardwerten erstellt."
    fi
    echo "Bitte prüfe .env und ändere insbesondere DB_PASSWORD, DB_ROOT_PASSWORD, SECRET_KEY und DEFAULT_CUSTOMER."
else
    echo ".env existiert bereits und wird nicht überschrieben."
fi

# Shellcheck-kompatibles Einlesen einfacher KEY=VALUE-Zeilen für Anzeigezwecke.
set -a
# shellcheck disable=SC1091
. ./.env
set +a

echo ""
echo "Aktive Projektparameter:"
echo "  DB_NAME=${DB_NAME:-dguv3_db}"
echo "  DB_USER=${DB_USER:-dguv3}"
echo "  DEFAULT_CUSTOMER=${DEFAULT_CUSTOMER:-TSS}"
echo "  FLASK_PORT=${FLASK_PORT:-5000}"
echo "  Host-MySQL-Port=${DB_HOST_PORT:-${DB_PORT:-3307}}"
echo ""

echo "Baue Container-Images..."
podman-compose build

echo "Starte Container neu..."
podman-compose down || true
podman-compose up -d

echo "Warte auf Container..."
sleep 8

echo ""
echo "Containerstatus:"
podman-compose ps

echo ""
echo "Letzte Logs:"
podman-compose logs --tail=40

echo ""
echo "Installation abgeschlossen."
echo "Anwendung: http://localhost:${FLASK_PORT:-5000}"
echo "MySQL Host-Zugriff: localhost:${DB_HOST_PORT:-${DB_PORT:-3307}}"
echo "Wichtige Befehle:"
echo "  Logs:      podman-compose logs -f"
echo "  Stoppen:   podman-compose down"
echo "  Starten:   podman-compose up -d"
echo "  DB Shell:  podman exec -it benning-mysql mysql -u\${DB_USER:-dguv3} -p \${DB_NAME:-dguv3_db}"
