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
