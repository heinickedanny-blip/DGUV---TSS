#!/usr/bin/env bash
# ============================================================================
# ANCHOR: DGUV3 Podman Projektvalidierung
# Datei: validation.sh
# Zweck: Prüft Container, Volume, MySQL, Flask und HTTP-Erreichbarkeit.
# Zielsystem: CachyOS / Arch Linux mit Podman und podman-compose
# ============================================================================

set -u

# SECTION: Farben und Ausgabehelfer
if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_GREEN='\033[0;32m'
  C_RED='\033[0;31m'
  C_YELLOW='\033[0;33m'
  C_BLUE='\033[0;34m'
  C_BOLD='\033[1m'
else
  C_RESET=''
  C_GREEN=''
  C_RED=''
  C_YELLOW=''
  C_BLUE=''
  C_BOLD=''
fi

OK_COUNT=0
WARN_COUNT=0
ERR_COUNT=0

ok() {
  OK_COUNT=$((OK_COUNT + 1))
  printf "%b[OK]%b %s\n" "$C_GREEN" "$C_RESET" "$1"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  printf "%b[WARN]%b %s\n" "$C_YELLOW" "$C_RESET" "$1"
}

err() {
  ERR_COUNT=$((ERR_COUNT + 1))
  printf "%b[FEHLER]%b %s\n" "$C_RED" "$C_RESET" "$1"
}

info() {
  printf "%b[INFO]%b %s\n" "$C_BLUE" "$C_RESET" "$1"
}

headline() {
  printf "\n%b%s%b\n" "$C_BOLD" "$1" "$C_RESET"
  printf '%*s\n' "${#1}" '' | tr ' ' '-'
}

run_quiet() {
  "$@" >/dev/null 2>&1
}

# SECTION: Projektverzeichnis bestimmen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$PWD}"

if [[ -f "$PROJECT_DIR/podman-compose.yml" || -f "$PROJECT_DIR/docker-compose.yml" ]]; then
  cd "$PROJECT_DIR" || exit 1
elif [[ -f "$SCRIPT_DIR/podman-compose.yml" || -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
  cd "$SCRIPT_DIR" || exit 1
else
  warn "Keine podman-compose.yml oder docker-compose.yml im aktuellen Ordner gefunden. Ich prüfe trotzdem globale Container."
fi

PROJECT_DIR="$(pwd)"

# SECTION: .env laden, aber keine Passwörter ausgeben
if [[ -f ".env" ]]; then
  # NOTE: Nur einfache KEY=VALUE-Zeilen werden geladen. Kommentare und leere Zeilen werden ignoriert.
  set -a
  # shellcheck disable=SC1091
  source <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | sed 's/\r$//')
  set +a
  ok ".env gefunden und geladen: $PROJECT_DIR/.env"
else
  warn ".env wurde im Projektordner nicht gefunden: $PROJECT_DIR"
fi

# SECTION: Erwartete Werte mit Defaults
MYSQL_CONTAINER_NAME="${MYSQL_CONTAINER_NAME:-benning-mysql}"
FLASK_CONTAINER_NAME="${FLASK_CONTAINER_NAME:-benning-flask}"
EXPECTED_VOLUME="${MYSQL_VOLUME_NAME:-prg_mysql_data}"
DB_NAME_VALUE="${DB_NAME:-dguv3_db}"
DB_USER_VALUE="${DB_USER:-dguv3}"
DB_ROOT_PASSWORD_VALUE="${DB_ROOT_PASSWORD:-}"
DB_PASSWORD_VALUE="${DB_PASSWORD:-}"
DB_HOST_PORT_VALUE="${DB_HOST_PORT:-3307}"
FLASK_PORT_VALUE="${FLASK_PORT:-5000}"
FLASK_URL="http://127.0.0.1:${FLASK_PORT_VALUE}"

headline "DGUV3 Podman Validation"
info "Projektordner: $PROJECT_DIR"
info "Erwartetes MySQL-Volume: $EXPECTED_VOLUME"
info "Erwartete Datenbank: $DB_NAME_VALUE"
info "Erwarteter DB-Benutzer: $DB_USER_VALUE"
info "Erwarteter Flask-Port: $FLASK_PORT_VALUE"

# SECTION: Basiswerkzeuge prüfen
headline "1. Basiswerkzeuge"

if command -v podman >/dev/null 2>&1; then
  ok "podman ist installiert: $(podman --version 2>/dev/null)"
else
  err "podman ist nicht installiert oder nicht im PATH."
fi

if command -v podman-compose >/dev/null 2>&1; then
  ok "podman-compose ist installiert."
elif command -v docker-compose >/dev/null 2>&1; then
  warn "podman-compose nicht gefunden, aber docker-compose ist vorhanden. Für dieses Setup wird podman-compose empfohlen."
else
  err "podman-compose wurde nicht gefunden."
fi

if command -v curl >/dev/null 2>&1; then
  ok "curl ist installiert."
else
  warn "curl ist nicht installiert. HTTP-Test auf Port $FLASK_PORT_VALUE ist nur eingeschränkt möglich."
fi

# SECTION: Compose-Konfiguration prüfen
headline "2. Compose- und .env-Konfiguration"

COMPOSE_FILE=""
if [[ -f "podman-compose.yml" ]]; then
  COMPOSE_FILE="podman-compose.yml"
  ok "Compose-Datei gefunden: podman-compose.yml"
elif [[ -f "docker-compose.yml" ]]; then
  COMPOSE_FILE="docker-compose.yml"
  ok "Compose-Datei gefunden: docker-compose.yml"
else
  err "Keine Compose-Datei im Projektordner gefunden."
fi

if [[ -n "$COMPOSE_FILE" ]] && command -v podman-compose >/dev/null 2>&1; then
  CONFIG_OUTPUT="$(podman-compose config 2>/tmp/dguv3_validation_compose_error.log || true)"
  if [[ -n "$CONFIG_OUTPUT" ]]; then
    ok "podman-compose config konnte gelesen werden."
    if echo "$CONFIG_OUTPUT" | grep -q "name: ${EXPECTED_VOLUME}"; then
      ok "Compose-Konfiguration zeigt auf Volume: $EXPECTED_VOLUME"
    else
      warn "Compose-Konfiguration enthält nicht sichtbar 'name: $EXPECTED_VOLUME'. Bitte prüfen: podman-compose config | grep -A5 -B5 mysql_data"
    fi
    if echo "$CONFIG_OUTPUT" | grep -q "mysql_data:/var/lib/mysql"; then
      ok "MySQL-Datenverzeichnis ist korrekt auf mysql_data:/var/lib/mysql gemappt."
    else
      warn "Mapping mysql_data:/var/lib/mysql wurde in podman-compose config nicht eindeutig gefunden."
    fi
  else
    err "podman-compose config lieferte keine Ausgabe. Details: /tmp/dguv3_validation_compose_error.log"
  fi
fi

# SECTION: Podman-Volumes prüfen
headline "3. Volume-Prüfung"

if podman volume exists "$EXPECTED_VOLUME" >/dev/null 2>&1; then
  ok "Erwartetes Volume existiert: $EXPECTED_VOLUME"
else
  err "Erwartetes Volume existiert nicht: $EXPECTED_VOLUME"
  info "Wenn es neu angelegt werden soll: podman-compose up -d --build"
fi

info "Aktuelle Podman-Volumes mit tss/prg/vol im Namen:"
podman volume ls 2>/dev/null | grep -E 'tss|prg|vol|mysql' || warn "Keine passenden Volumes in podman volume ls gefunden."

# SECTION: Containerstatus prüfen
headline "4. Containerstatus"

if podman container exists "$MYSQL_CONTAINER_NAME" >/dev/null 2>&1; then
  MYSQL_STATUS="$(podman inspect "$MYSQL_CONTAINER_NAME" --format '{{.State.Status}}' 2>/dev/null || true)"
  ok "MySQL-Container existiert: $MYSQL_CONTAINER_NAME Status=$MYSQL_STATUS"
else
  err "MySQL-Container existiert nicht: $MYSQL_CONTAINER_NAME"
fi

if podman container exists "$FLASK_CONTAINER_NAME" >/dev/null 2>&1; then
  FLASK_STATUS="$(podman inspect "$FLASK_CONTAINER_NAME" --format '{{.State.Status}}' 2>/dev/null || true)"
  ok "Flask-Container existiert: $FLASK_CONTAINER_NAME Status=$FLASK_STATUS"
else
  err "Flask-Container existiert nicht: $FLASK_CONTAINER_NAME"
fi

info "Aktuelle Containerübersicht:"
podman ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true

# SECTION: Tatsächliches MySQL-Volume am laufenden Container prüfen
headline "5. MySQL-Volume-Mount"

if podman container exists "$MYSQL_CONTAINER_NAME" >/dev/null 2>&1; then
  MOUNTS="$(podman inspect "$MYSQL_CONTAINER_NAME" --format '{{range .Mounts}}{{println .Name "->" .Destination}}{{end}}' 2>/dev/null || true)"
  if [[ -n "$MOUNTS" ]]; then
    printf "%s\n" "$MOUNTS"
    if echo "$MOUNTS" | grep -q "^${EXPECTED_VOLUME} -> /var/lib/mysql$"; then
      ok "MySQL verwendet korrekt das Volume $EXPECTED_VOLUME für /var/lib/mysql."
    else
      err "MySQL verwendet offenbar NICHT $EXPECTED_VOLUME für /var/lib/mysql."
      info "Korrektur: podman-compose down && podman rm -f $MYSQL_CONTAINER_NAME $FLASK_CONTAINER_NAME 2>/dev/null && podman-compose up -d --build"
    fi
  else
    warn "Keine Mount-Informationen für $MYSQL_CONTAINER_NAME gefunden."
  fi
fi

# SECTION: Portbelegung prüfen
headline "6. Port-Prüfung"

if command -v ss >/dev/null 2>&1; then
  if ss -ltn | awk '{print $4}' | grep -Eq "(^|:)${FLASK_PORT_VALUE}$"; then
    ok "Auf Host-Port $FLASK_PORT_VALUE lauscht ein Dienst."
  else
    err "Auf Host-Port $FLASK_PORT_VALUE lauscht aktuell kein Dienst."
  fi

  if ss -ltn | awk '{print $4}' | grep -Eq "(^|:)${DB_HOST_PORT_VALUE}$"; then
    ok "Auf Host-Port $DB_HOST_PORT_VALUE lauscht ein Dienst für MySQL."
  else
    warn "Auf Host-Port $DB_HOST_PORT_VALUE lauscht aktuell kein Dienst."
  fi
elif command -v netstat >/dev/null 2>&1; then
  netstat -ltn 2>/dev/null | grep -E ":${FLASK_PORT_VALUE}[[:space:]]" >/dev/null && ok "Port $FLASK_PORT_VALUE lauscht." || err "Port $FLASK_PORT_VALUE lauscht nicht."
else
  warn "Weder ss noch netstat gefunden. Portprüfung übersprungen."
fi

# SECTION: MySQL-Verbindung prüfen
headline "7. MySQL-Verbindung und Datenbank"

if podman container exists "$MYSQL_CONTAINER_NAME" >/dev/null 2>&1; then
  if [[ -n "$DB_ROOT_PASSWORD_VALUE" ]]; then
    if podman exec "$MYSQL_CONTAINER_NAME" mysql -uroot -p"$DB_ROOT_PASSWORD_VALUE" -e "SELECT 1;" >/dev/null 2>&1; then
      ok "Root-Login in MySQL funktioniert mit DB_ROOT_PASSWORD aus .env."
      if podman exec "$MYSQL_CONTAINER_NAME" mysql -uroot -p"$DB_ROOT_PASSWORD_VALUE" -e "SHOW DATABASES LIKE '${DB_NAME_VALUE}';" 2>/dev/null | grep -q "$DB_NAME_VALUE"; then
        ok "Datenbank existiert: $DB_NAME_VALUE"
      else
        err "Datenbank wurde nicht gefunden: $DB_NAME_VALUE"
      fi
      if podman exec "$MYSQL_CONTAINER_NAME" mysql -uroot -p"$DB_ROOT_PASSWORD_VALUE" -e "SELECT user, host FROM mysql.user WHERE user='${DB_USER_VALUE}';" 2>/dev/null | grep -q "$DB_USER_VALUE"; then
        ok "Datenbankbenutzer existiert: $DB_USER_VALUE"
      else
        warn "Datenbankbenutzer wurde nicht gefunden: $DB_USER_VALUE"
      fi
    else
      err "Root-Login in MySQL funktioniert NICHT mit DB_ROOT_PASSWORD aus .env."
      info "Hinweis: Wenn das Volume bereits initialisiert war, gilt das alte Root-Passwort des Volumes."
    fi
  else
    warn "DB_ROOT_PASSWORD ist in .env nicht gesetzt. Root-Login-Test wird übersprungen."
  fi

  if [[ -n "$DB_PASSWORD_VALUE" ]]; then
    if podman exec "$MYSQL_CONTAINER_NAME" mysql -u"$DB_USER_VALUE" -p"$DB_PASSWORD_VALUE" "$DB_NAME_VALUE" -e "SELECT 1;" >/dev/null 2>&1; then
      ok "Login mit DB_USER/DB_PASSWORD auf $DB_NAME_VALUE funktioniert."
    else
      err "Login mit DB_USER/DB_PASSWORD auf $DB_NAME_VALUE funktioniert NICHT."
    fi
  else
    warn "DB_PASSWORD ist in .env nicht gesetzt. User-Login-Test wird übersprungen."
  fi
fi

# SECTION: Flask-Prozess und Logs prüfen
headline "8. Flask-Container und Anwendungsprozess"

if podman container exists "$FLASK_CONTAINER_NAME" >/dev/null 2>&1; then
  FLASK_RUNNING="$(podman inspect "$FLASK_CONTAINER_NAME" --format '{{.State.Running}}' 2>/dev/null || echo false)"
  if [[ "$FLASK_RUNNING" == "true" ]]; then
    ok "Flask-Container läuft."
  else
    err "Flask-Container läuft nicht."
  fi

  if podman exec "$FLASK_CONTAINER_NAME" sh -lc "ps aux | grep -E 'gunicorn|flask|python' | grep -v grep" >/dev/null 2>&1; then
    ok "Im Flask-Container läuft ein Python/Gunicorn/Flask-Prozess."
  else
    warn "Im Flask-Container wurde kein eindeutiger Python/Gunicorn/Flask-Prozess gefunden."
  fi

  info "Letzte Flask-Logs:"
  podman logs "$FLASK_CONTAINER_NAME" --tail=40 2>&1 || true
fi

# SECTION: HTTP-Test auf Flask-Port
headline "9. HTTP-Test"

if command -v curl >/dev/null 2>&1; then
  HTTP_CODE="$(curl -sS -o /tmp/dguv3_validation_http.out -w '%{http_code}' --connect-timeout 3 --max-time 8 "$FLASK_URL" 2>/tmp/dguv3_validation_curl.err || true)"
  if [[ "$HTTP_CODE" =~ ^2|3[0-9][0-9]$ ]]; then
    ok "HTTP-Test erfolgreich: $FLASK_URL liefert Status $HTTP_CODE"
  elif [[ -n "$HTTP_CODE" && "$HTTP_CODE" != "000" ]]; then
    warn "HTTP-Test erreicht Flask, aber Status ist $HTTP_CODE. Antwortauszug:"
    head -n 20 /tmp/dguv3_validation_http.out 2>/dev/null || true
  else
    err "HTTP-Test fehlgeschlagen: $FLASK_URL ist nicht erreichbar."
    if [[ -s /tmp/dguv3_validation_curl.err ]]; then
      info "curl-Fehler: $(cat /tmp/dguv3_validation_curl.err)"
    fi
  fi
else
  warn "curl nicht verfügbar. HTTP-Test übersprungen."
fi

# SECTION: Handlungsempfehlung
headline "10. Zusammenfassung"

printf "OK: %s | WARN: %s | FEHLER: %s\n" "$OK_COUNT" "$WARN_COUNT" "$ERR_COUNT"

if (( ERR_COUNT == 0 )); then
  ok "Validierung ohne harte Fehler abgeschlossen. Öffne: $FLASK_URL"
else
  warn "Es wurden Fehler gefunden. Häufige Korrektur bei Volume-/Port-/Containerproblemen:"
  cat <<EOF

cd "$PROJECT_DIR"
podman-compose down
podman rm -f "$MYSQL_CONTAINER_NAME" "$FLASK_CONTAINER_NAME" 2>/dev/null || true
podman-compose up -d --build
podman ps -a
podman logs "$MYSQL_CONTAINER_NAME" --tail=100
podman logs "$FLASK_CONTAINER_NAME" --tail=100

EOF
  warn "Wenn das Volume $EXPECTED_VOLUME frisch initialisiert werden soll und dort keine wichtigen Daten liegen:"
  cat <<EOF
podman-compose down
podman volume rm "$EXPECTED_VOLUME"
podman-compose up -d --build
EOF
fi

exit 0
