#!/bin/bash

################################################################################
# Sync Canvas - Verbesserte Version v2
# Projekt ↔ Obsidian Vault Synchronisierung mit erweiterten Funktionen
################################################################################

set -o pipefail

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Konfiguration
CONFIG_FILE="${HOME}/.sync_canvas_config"
LAST_SYNC_FILE="${HOME}/.sync_canvas_last_sync"
LOG_FILE="${HOME}/.sync_canvas.log"
BACKUP_DIR="${HOME}/.sync_canvas_backups"

# Script-Pfad (absolut)
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# Globale Variablen
SOURCE_PATH=""
DEST_PATH=""
EXCLUDE_PATTERNS=""
SYNC_MODE=""
DRY_RUN=false
CREATE_BACKUP=true
VERBOSE=false

################################################################################
# Logging
################################################################################

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    
    if [ "$VERBOSE" = true ] || [ "$level" = "ERROR" ]; then
        echo -e "${message}" >&2
    fi
}

################################################################################
# Abhängigkeiten
################################################################################

check_dependencies() {
    local missing_deps=()
    
    for cmd in rsync find du mkdir; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}✗ Erforderliche Programme nicht gefunden:${NC}"
        printf '  - %s\n' "${missing_deps[@]}"
        return 1
    fi
    
    return 0
}

################################################################################
# Pfad-Validierung
################################################################################

validate_path() {
    local path="$1"
    local expanded_path
    
    # Tilde-Expansion
    if [[ "$path" == ~* ]]; then
        expanded_path="${path/#\~/$HOME}"
    else
        expanded_path="$path"
    fi
    
    # Prüfe, ob Verzeichnis existiert
    if [ -d "$expanded_path" ]; then
        echo "$expanded_path"
        return 0
    fi
    
    return 1
}

################################################################################
# Bestätigung
################################################################################

confirm() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$(echo -e "${CYAN}${prompt}${NC}")" response
        case "$response" in
            [Jj][aA]|[Yy][eE][sS])
                return 0
                ;;
            [Nn][eE][iI]|[Nn][oO])
                return 1
                ;;
            *)
                echo -e "${RED}Bitte antworte mit 'ja' oder 'nein'${NC}"
                ;;
        esac
    done
}

################################################################################
# Header
################################################################################

show_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    Sync Canvas - Projekt ↔ Obsidian Vault (v2)            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_help() {
    cat << EOF
${GREEN}Sync Canvas - Projekt ↔ Obsidian Vault Synchronisierung${NC}

${CYAN}Verwendung:${NC}
  $0 [OPTIONEN]

${CYAN}Optionen:${NC}
  -h, --help              Diese Hilfe anzeigen
  -s, --sync              Synchronisierung durchführen (für Cron)
  -d, --dry-run           Dry-Run-Modus (zeigt was synchronisiert würde)
  -v, --verbose           Ausführliche Ausgabe
  -c, --config FILE       Alternative Konfigurationsdatei verwenden
  -l, --log FILE          Alternative Log-Datei verwenden
  --no-backup             Kein Backup vor Synchronisierung erstellen

${CYAN}Beispiele:${NC}
  $0                      Interaktives Menü starten
  $0 --sync               Synchronisierung durchführen (für Cron)
  $0 --dry-run            Vorschau der Synchronisierung

EOF
}

################################################################################
# Konfiguration
################################################################################

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue
            
            value="${value%\"}"
            value="${value#\"}"
            
            case "$key" in
                SOURCE_PATH) SOURCE_PATH="$value" ;;
                DEST_PATH) DEST_PATH="$value" ;;
                EXCLUDE_PATTERNS) EXCLUDE_PATTERNS="$value" ;;
                SYNC_MODE) SYNC_MODE="$value" ;;
            esac
        done < "$CONFIG_FILE"
        return 0
    fi
    return 1
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# Sync Canvas Konfiguration
# Generiert: $(date)
SOURCE_PATH="$SOURCE_PATH"
DEST_PATH="$DEST_PATH"
EXCLUDE_PATTERNS="$EXCLUDE_PATTERNS"
SYNC_MODE="$SYNC_MODE"
EOF
    
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}✓ Konfiguration gespeichert${NC}"
}

################################################################################
# Interaktive Konfiguration
################################################################################

ask_paths() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Pfade konfigurieren${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Quell-Pfad
    while true; do
        read -p "$(echo -e "${CYAN}Quell-Ordner (Projekt)${NC}) [${GREEN}${SOURCE_PATH}${NC}]: ")" input
        if [ -n "$input" ]; then
            SOURCE_PATH="$input"
        fi
        
        if [ -z "$SOURCE_PATH" ]; then
            echo -e "${RED}✗ Quell-Pfad kann nicht leer sein${NC}"
            continue
        fi
        
        EXPANDED_SOURCE=$(validate_path "$SOURCE_PATH")
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Quell-Pfad gültig: $EXPANDED_SOURCE${NC}"
            break
        else
            echo -e "${RED}✗ Quell-Pfad nicht gefunden: $SOURCE_PATH${NC}"
            echo -e "${YELLOW}Bitte überprüfe den Pfad${NC}"
        fi
    done
    echo ""
    
    # Ziel-Pfad
    while true; do
        read -p "$(echo -e "${CYAN}Ziel-Ordner (Obsidian)${NC}) [${GREEN}${DEST_PATH}${NC}]: ")" input
        if [ -n "$input" ]; then
            DEST_PATH="$input"
        fi
        
        if [ -z "$DEST_PATH" ]; then
            echo -e "${RED}✗ Ziel-Pfad kann nicht leer sein${NC}"
            continue
        fi
        
        EXPANDED_DEST=$(validate_path "$DEST_PATH")
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Ziel-Pfad gültig: $EXPANDED_DEST${NC}"
            break
        else
            if confirm "Ziel-Ordner existiert nicht. Erstellen? (ja/nein): "; then
                if mkdir -p "$DEST_PATH" 2>/dev/null; then
                    echo -e "${GREEN}✓ Ziel-Ordner erstellt${NC}"
                    break
                else
                    echo -e "${RED}✗ Konnte Ziel-Ordner nicht erstellen${NC}"
                fi
            fi
        fi
    done
    echo ""
}

ask_excludes() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Ausschlüsse konfigurieren${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Standard-Ausschlüsse:${NC}"
    echo "  - .git, .gitignore"
    echo "  - node_modules"
    echo "  - .env, .env.local"
    echo "  - .obsidian"
    echo ""
    
    read -p "$(echo -e "${CYAN}Zusätzliche Ausschlüsse (durch Komma getrennt)${NC}) [${GREEN}${EXCLUDE_PATTERNS}${NC}]: ")" input
    if [ -n "$input" ]; then
        EXCLUDE_PATTERNS="$input"
    fi
    
    if [ -z "$EXCLUDE_PATTERNS" ]; then
        EXCLUDE_PATTERNS=".DS_Store,Thumbs.db"
    fi
    echo -e "${GREEN}✓ Ausschlüsse gesetzt${NC}"
    echo ""
}

ask_sync_mode() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Sync-Modus wählen${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}1${NC}) Einseitig: Projekt → Obsidian"
    echo -e "${CYAN}2${NC}) Einseitig: Obsidian → Projekt"
    echo -e "${CYAN}3${NC}) Bidirektional"
    echo ""
    
    while true; do
        read -p "$(echo -e "${CYAN}Modus wählen (1-3) [${GREEN}${SYNC_MODE:-1}${NC}]: ")" input
        if [ -n "$input" ]; then
            SYNC_MODE="$input"
        fi
        
        case "${SYNC_MODE:-1}" in
            1)
                echo -e "${GREEN}✓ Modus: Projekt → Obsidian${NC}"
                break
                ;;
            2)
                echo -e "${GREEN}✓ Modus: Obsidian → Projekt${NC}"
                break
                ;;
            3)
                echo -e "${GREEN}✓ Modus: Bidirektional${NC}"
                break
                ;;
            *)
                echo -e "${RED}Ungültige Auswahl. Bitte 1, 2 oder 3 eingeben.${NC}"
                ;;
        esac
    done
    echo ""
}

################################################################################
# Rsync-Ausschlüsse
################################################################################

build_exclude_array() {
    local -n exclude_array=$1
    
    local standard_excludes=(".git" ".gitignore" "node_modules" ".env" ".env.local" ".obsidian")
    for exclude in "${standard_excludes[@]}"; do
        exclude_array+=("--exclude=$exclude")
    done
    
    if [ -n "$EXCLUDE_PATTERNS" ]; then
        IFS=',' read -ra extra_excludes <<< "$EXCLUDE_PATTERNS"
        for exclude in "${extra_excludes[@]}"; do
            exclude=$(echo "$exclude" | xargs)
            if [ -n "$exclude" ]; then
                exclude_array+=("--exclude=$exclude")
            fi
        done
    fi
}

################################################################################
# Backup
################################################################################

create_backup() {
    local dest="$1"
    
    if [ "$CREATE_BACKUP" = false ]; then
        return 0
    fi
    
    if [ ! -d "$dest" ] || [ -z "$(find "$dest" -type f 2>/dev/null)" ]; then
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    echo -e "${CYAN}Erstelle Backup: $backup_name${NC}"
    
    if cp -r "$dest" "$backup_path" 2>/dev/null; then
        echo -e "${GREEN}✓ Backup erstellt${NC}"
        log "INFO" "Backup erstellt: $backup_path"
        return 0
    else
        echo -e "${RED}✗ Backup fehlgeschlagen${NC}"
        log "ERROR" "Backup fehlgeschlagen für $dest"
        return 1
    fi
}

cleanup_old_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then
        return 0
    fi
    
    find "$BACKUP_DIR" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null
    log "INFO" "Alte Backups gelöscht"
}

################################################################################
# Synchronisierung
################################################################################

perform_sync() {
    local source expanded_source dest expanded_dest
    local -a rsync_excludes
    local rsync_opts="-av"
    
    source=$(validate_path "$SOURCE_PATH")
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Quell-Pfad nicht gültig: $SOURCE_PATH${NC}"
        log "ERROR" "Quell-Pfad nicht gültig: $SOURCE_PATH"
        return 1
    fi
    
    dest=$(validate_path "$DEST_PATH")
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Ziel-Pfad nicht gültig: $DEST_PATH${NC}"
        log "ERROR" "Ziel-Pfad nicht gültig: $DEST_PATH"
        return 1
    fi
    
    if [[ ! "$SYNC_MODE" =~ ^[1-3]$ ]]; then
        echo -e "${RED}✗ Ungültiger Sync-Modus: $SYNC_MODE${NC}"
        log "ERROR" "Ungültiger Sync-Modus: $SYNC_MODE"
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        rsync_opts="$rsync_opts --dry-run"
        echo -e "${YELLOW}[DRY-RUN-MODUS]${NC}"
    fi
    
    build_exclude_array rsync_excludes
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Synchronisiere...${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    log "INFO" "Synchronisierung gestartet (Modus: $SYNC_MODE)"
    
    case "$SYNC_MODE" in
        1)
            echo -e "${CYAN}Richtung: Projekt → Obsidian${NC}"
            echo "Quelle:  $source"
            echo "Ziel:    $dest"
            echo ""
            
            if [ "$DRY_RUN" = false ]; then
                create_backup "$dest" || return 1
            fi
            
            if rsync $rsync_opts --delete "${rsync_excludes[@]}" "$source/" "$dest/"; then
                log "INFO" "Synchronisierung erfolgreich (Projekt → Obsidian)"
                return 0
            else
                log "ERROR" "Synchronisierung fehlgeschlagen (Projekt → Obsidian)"
                return 1
            fi
            ;;
            
        2)
            echo -e "${CYAN}Richtung: Obsidian → Projekt${NC}"
            echo "Quelle:  $dest"
            echo "Ziel:    $source"
            echo ""
            
            if [ "$DRY_RUN" = false ]; then
                create_backup "$source" || return 1
            fi
            
            if rsync $rsync_opts --delete "${rsync_excludes[@]}" "$dest/" "$source/"; then
                log "INFO" "Synchronisierung erfolgreich (Obsidian → Projekt)"
                return 0
            else
                log "ERROR" "Synchronisierung fehlgeschlagen (Obsidian → Projekt)"
                return 1
            fi
            ;;
            
        3)
            echo -e "${CYAN}Richtung: Bidirektional${NC}"
            echo "Projekt: $source"
            echo "Obsidian: $dest"
            echo ""
            
            if [ "$DRY_RUN" = false ]; then
                create_backup "$dest" || return 1
                create_backup "$source" || return 1
            fi
            
            echo -e "${YELLOW}→ Projekt zu Obsidian...${NC}"
            if ! rsync $rsync_opts --delete "${rsync_excludes[@]}" "$source/" "$dest/"; then
                log "ERROR" "Synchronisierung fehlgeschlagen (Projekt → Obsidian)"
                return 1
            fi
            
            echo -e "${YELLOW}← Obsidian zu Projekt...${NC}"
            if ! rsync $rsync_opts --delete "${rsync_excludes[@]}" "$dest/" "$source/"; then
                log "ERROR" "Synchronisierung fehlgeschlagen (Obsidian → Projekt)"
                return 1
            fi
            
            log "INFO" "Synchronisierung erfolgreich (Bidirektional)"
            return 0
            ;;
    esac
}

################################################################################
# Status
################################################################################

show_status() {
    local source dest
    
    source=$(validate_path "$SOURCE_PATH")
    dest=$(validate_path "$DEST_PATH")
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Status${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${CYAN}Quell-Ordner (Projekt):${NC}"
    echo "  Pfad: $SOURCE_PATH"
    if [ -n "$source" ]; then
        echo -e "  Status: ${GREEN}✓ Vorhanden${NC}"
        echo "  Dateien: $(find "$source" -type f 2>/dev/null | wc -l)"
        echo "  Größe: $(du -sh "$source" 2>/dev/null | cut -f1)"
    else
        echo -e "  Status: ${RED}✗ Nicht vorhanden${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}Ziel-Ordner (Obsidian):${NC}"
    echo "  Pfad: $DEST_PATH"
    if [ -n "$dest" ]; then
        echo -e "  Status: ${GREEN}✓ Vorhanden${NC}"
        echo "  Dateien: $(find "$dest" -type f 2>/dev/null | wc -l)"
        echo "  Größe: $(du -sh "$dest" 2>/dev/null | cut -f1)"
    else
        echo -e "  Status: ${RED}✗ Nicht vorhanden${NC}"
    fi
    echo ""
    
    echo -e "${CYAN}Sync-Modus:${NC}"
    case "$SYNC_MODE" in
        1) echo "  Projekt → Obsidian" ;;
        2) echo "  Obsidian → Projekt" ;;
        3) echo "  Bidirektional" ;;
        *) echo "  Nicht konfiguriert" ;;
    esac
    echo ""
    
    echo -e "${CYAN}Ausschlüsse:${NC}"
    echo "  $EXCLUDE_PATTERNS"
    echo ""
    
    if [ -f "$LAST_SYNC_FILE" ]; then
        echo -e "${CYAN}Letzter Sync:${NC}"
        echo "  $(cat "$LAST_SYNC_FILE")"
    else
        echo -e "${CYAN}Letzter Sync:${NC}"
        echo "  Noch nie synchronisiert"
    fi
    echo ""
}

show_menu() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Hauptmenü${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}1${NC}) Konfigurieren"
    echo -e "${CYAN}2${NC}) Status anzeigen"
    echo -e "${CYAN}3${NC}) Dry-Run durchführen"
    echo -e "${CYAN}4${NC}) Jetzt synchronisieren"
    echo -e "${CYAN}5${NC}) Cron einrichten"
    echo -e "${CYAN}6${NC}) Log anzeigen"
    echo -e "${CYAN}7${NC}) Konfiguration löschen"
    echo -e "${CYAN}0${NC}) Beenden"
    echo ""
}

################################################################################
# Cron
################################################################################

setup_cron() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Automatischer Sync (Cron)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Intervall wählen:${NC}"
    echo "  1) Jede Minute"
    echo "  2) Alle 5 Minuten"
    echo "  3) Alle 15 Minuten"
    echo "  4) Jede Stunde"
    echo "  5) Täglich (00:00)"
    echo "  0) Abbrechen"
    echo ""
    
    read -p "$(echo -e "${CYAN}Auswahl (0-5): ${NC}")" cron_choice
    
    local cron_pattern=""
    case "$cron_choice" in
        1) cron_pattern="* * * * *" ;;
        2) cron_pattern="*/5 * * * *" ;;
        3) cron_pattern="*/15 * * * *" ;;
        4) cron_pattern="0 * * * *" ;;
        5) cron_pattern="0 0 * * *" ;;
        0) return ;;
        *) echo -e "${RED}Ungültige Auswahl${NC}"; return ;;
    esac
    
    local cron_command="$cron_pattern $SCRIPT_PATH --sync >> $LOG_FILE 2>&1"
    
    (crontab -l 2>/dev/null | grep -v "sync_canvas"; echo "$cron_command") | crontab -
    
    echo ""
    echo -e "${GREEN}✓ Cron-Job hinzugefügt${NC}"
    echo "  Pattern: $cron_pattern"
    echo "  Script: $SCRIPT_PATH"
    echo ""
    
    log "INFO" "Cron-Job hinzugefügt: $cron_pattern"
}

show_log() {
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Sync-Log (letzte 50 Einträge)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -f "$LOG_FILE" ]; then
        tail -50 "$LOG_FILE"
    else
        echo -e "${YELLOW}Noch keine Log-Einträge${NC}"
    fi
    echo ""
}

delete_config() {
    echo ""
    if confirm "Wirklich die Konfiguration löschen? (ja/nein): "; then
        rm -f "$CONFIG_FILE"
        echo -e "${GREEN}✓ Konfiguration gelöscht${NC}"
        SOURCE_PATH=""
        DEST_PATH=""
        SYNC_MODE=""
        EXCLUDE_PATTERNS=""
        log "INFO" "Konfiguration gelöscht"
    else
        echo -e "${YELLOW}→ Abgebrochen${NC}"
    fi
}

################################################################################
# Hauptprogramm
################################################################################

main() {
    if ! check_dependencies; then
        exit 1
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--sync)
                DRY_RUN=false
                load_config
                if [ -z "$SOURCE_PATH" ] || [ -z "$DEST_PATH" ]; then
                    log "ERROR" "Konfiguration nicht vollständig"
                    echo "Fehler: Konfiguration nicht vollständig." >&2
                    exit 1
                fi
                perform_sync
                if [ $? -eq 0 ]; then
                    date > "$LAST_SYNC_FILE"
                    cleanup_old_backups
                    exit 0
                else
                    exit 1
                fi
                ;;
            -d|--dry-run)
                DRY_RUN=true
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift
                ;;
            --no-backup)
                CREATE_BACKUP=false
                ;;
            *)
                echo "Unbekannte Option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
    
    show_header
    
    if ! load_config; then
        echo -e "${YELLOW}Keine Konfiguration gefunden. Bitte konfigurieren.${NC}"
        echo ""
        ask_paths
        ask_excludes
        ask_sync_mode
        save_config
    fi
    
    while true; do
        show_header
        show_status
        show_menu
        
        read -p "$(echo -e "${CYAN}Auswahl (0-7): ${NC}")" choice
        
        case "$choice" in
            1)
                ask_paths
                ask_excludes
                ask_sync_mode
                save_config
                ;;
            2)
                show_header
                show_status
                ;;
            3)
                show_header
                DRY_RUN=true
                perform_sync
                DRY_RUN=false
                echo ""
                read -p "$(echo -e "${CYAN}[Enter] zum Fortfahren...${NC})")"
                ;;
            4)
                show_header
                DRY_RUN=false
                if perform_sync; then
                    date > "$LAST_SYNC_FILE"
                    cleanup_old_backups
                    echo -e "${GREEN}✓ Synchronisierung erfolgreich${NC}"
                else
                    echo -e "${RED}✗ Synchronisierung fehlgeschlagen${NC}"
                fi
                echo ""
                read -p "$(echo -e "${CYAN}[Enter] zum Fortfahren...${NC})")"
                ;;
            5)
                show_header
                setup_cron
                read -p "$(echo -e "${CYAN}[Enter] zum Fortfahren...${NC})")"
                ;;
            6)
                show_header
                show_log
                read -p "$(echo -e "${CYAN}[Enter] zum Fortfahren...${NC})")"
                ;;
            7)
                show_header
                delete_config
                echo ""
                read -p "$(echo -e "${CYAN}[Enter] zum Fortfahren...${NC})")"
                ;;
            0)
                echo ""
                echo -e "${GREEN}Auf Wiedersehen!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Ungültige Auswahl${NC}"
                read -p "$(echo -e "${CYAN}[Enter] zum Fortfahren...${NC})")"
                ;;
        esac
    done
}

main "$@"
