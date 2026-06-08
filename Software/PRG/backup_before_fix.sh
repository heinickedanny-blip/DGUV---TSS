#!/bin/bash
# ============================================================================
# Backup der Datenbank VOR der Riso-Korrektur
# ============================================================================

echo "📦 Erstelle Backup der miro_db Datenbank..."
podman exec benning-mysql mysqldump -u miro -pmiro miro_db > backup_miro_db_$(date +%Y%m%d_%H%M%S).sql

if [ $? -eq 0 ]; then
    echo "✅ Backup erfolgreich erstellt!"
    ls -lh backup_miro_db_*.sql | tail -1
else
    echo "❌ Backup fehlgeschlagen!"
    exit 1
fi
