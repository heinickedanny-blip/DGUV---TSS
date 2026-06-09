#!/usr/bin/env bash

# ============================================================================
# DGUV3 / Benning Device Manager - Interaktiver Runtime-Starter
# ============================================================================
# Zweck:
#   Startet die Podman-Containerumgebung und bietet vorher eine Eingabemaske,
#   um eine neue Datenbank für einen neuen oder bestehenden Kunden anzulegen.
#
# Speicherort:
#   Software/PRG/start_runtime.sh
#
# Nutzung:
#   cd Software/PRG
#   chmod +x start_runtime.sh
#   ./start_runtime.sh
#
# Voraussetzungen:
#   - podman
#   - podman-compose
#   - schema.sql im aktuellen Projektverzeichnis
#   - podman-compose.yml im aktuellen Projektverzeichnis
# ============================================================================

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

COMPOSE_FILE="podman-compose.yml"
ENV_FILE=".env"
ENV_TEMPLATE="env.template"
SCHEMA_FILE="schema.sql"
DOCKERFILE_BENNING="Dockerfile.benning"
REQUIREMENTS_FILE="requirements_hexagon.txt"
INIT_DB_DIR="init-db"
INIT_SCHEMA_FILE="${INIT_DB_DIR}/01_schema.sql"
MYSQL_CONTAINER="benning-mysql"
FLASK_CONTAINER="benning-flask"

DEFAULT_DB_HOST="mysql"
DEFAULT_DB_PORT="3306"
DEFAULT_DB_HOST_PORT="3307"
DEFAULT_FLASK_PORT="5000"
DEFAULT_DB_USER="dguv3"
DEFAULT_CUSTOMER="TSS"

log() {
    printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

warn() {
    printf '\nWARNUNG: %s\n' "$*" >&2
}

fail() {
    printf '\nFEHLER: %s\n' "$*" >&2
    exit 1
}

line() {
    printf '%s\n' '----------------------------------------------------------------------------'
}

require_command() {
    local cmd="$1"
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        fail "${cmd} ist nicht installiert. Bitte zuerst install_container_tools.sh ausführen."
    fi
}

read_default() {
    local prompt="$1"
    local default_value="$2"
    local value=""

    if [ -n "${default_value}" ]; then
        read -r -p "${prompt} [${default_value}]: " value
        printf '%s' "${value:-${default_value}}"
    else
        read -r -p "${prompt}: " value
        printf '%s' "${value}"
    fi
}

read_secret_default() {
    local prompt="$1"
    local default_value="$2"
    local value=""

    if [ -n "${default_value}" ]; then
        read -r -s -p "${prompt} [vorhandenen Wert übernehmen mit Enter]: " value
        printf '\n' >&2
        printf '%s' "${value:-${default_value}}"
    else
        read -r -s -p "${prompt}: " value
        printf '\n' >&2
        printf '%s' "${value}"
    fi
}

confirm() {
    local prompt="$1"
    local answer=""
    read -r -p "${prompt} [j/N]: " answer
    case "${answer}" in
        j|J|ja|JA|Ja|yes|YES|Yes|y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

sanitize_identifier() {
    local raw="$1"
    local sanitized=""
    sanitized="$(printf '%s' "${raw}" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/ä/ae/g; s/ö/oe/g; s/ü/ue/g; s/ß/ss/g; s/[^a-z0-9]+/_/g; s/^_+//; s/_+$//; s/_+/_/g')"

    if [ -z "${sanitized}" ]; then
        sanitized="kunde"
    fi

    if ! printf '%s' "${sanitized}" | grep -Eq '^[a-z]'; then
        sanitized="k_${sanitized}"
    fi

    printf '%s' "${sanitized}"
}

sanitize_customer_display() {
    local raw="$1"
    local customer=""
    customer="$(printf '%s' "${raw}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/_/g')"
    if [ -z "${customer}" ]; then
        customer="${DEFAULT_CUSTOMER}"
    fi
    printf '%s' "${customer}"
}

validate_mysql_identifier() {
    local label="$1"
    local value="$2"

    if ! printf '%s' "${value}" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]{0,63}$'; then
        fail "${label} darf nur Buchstaben, Zahlen und Unterstriche enthalten, muss mit Buchstabe/Unterstrich beginnen und maximal 64 Zeichen lang sein: ${value}"
    fi
}

sql_escape_string() {
    local value="$1"
    printf '%s' "${value}" | sed "s/'/''/g"
}

trim_value() {
    local value="$1"
    printf '%s' "${value}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

validate_port() {
    local label="$1"
    local value="$2"

    if ! printf '%s' "${value}" | grep -Eq '^[0-9]+$'; then
        fail "${label} muss eine Zahl sein: ${value}"
    fi

    if [ "${value}" -lt 1 ] || [ "${value}" -gt 65535 ]; then
        fail "${label} muss zwischen 1 und 65535 liegen: ${value}"
    fi
}

get_env_value() {
    local key="$1"
    local default_value="$2"

    if [ -f "${ENV_FILE}" ] && grep -Eq "^${key}=" "${ENV_FILE}"; then
        grep -E "^${key}=" "${ENV_FILE}" | tail -n 1 | cut -d '=' -f 2-
    else
        printf '%s' "${default_value}"
    fi
}

set_env_value() {
    local key="$1"
    local value="$2"
    local escaped=""
    local tmp_file=""

    tmp_file="$(mktemp)"
    escaped="$(printf '%s' "${value}" | sed 's/[&/\\]/\\&/g')"

    if [ -f "${ENV_FILE}" ] && grep -Eq "^${key}=" "${ENV_FILE}"; then
        sed -E "s/^${key}=.*/${key}=${escaped}/" "${ENV_FILE}" > "${tmp_file}"
    else
        if [ -f "${ENV_FILE}" ]; then
            cp "${ENV_FILE}" "${tmp_file}"
        else
            : > "${tmp_file}"
        fi
        printf '%s=%s\n' "${key}" "${value}" >> "${tmp_file}"
    fi

    mv "${tmp_file}" "${ENV_FILE}"
}

ensure_requirements_hexagon() {
    if [ -f "${REQUIREMENTS_FILE}" ]; then
        return 0
    fi

    warn "${REQUIREMENTS_FILE} fehlt. Die Datei wird automatisch neu erstellt, damit der Flask-Container gebaut werden kann."

    cat > "${REQUIREMENTS_FILE}" <<'EOF'
# Core Framework
Flask==2.3.3
Werkzeug==2.3.7

# Database
mysql-connector-python==8.1.0

# Utilities
python-dotenv==1.0.0
qrcode==7.4.2

# Testing
pytest==7.4.0
pytest-cov==4.1.0
pytest-mock==3.11.1

# Development
black==23.9.1
flake8==6.1.0
mypy==1.5.1
isort==5.12.0

# Production
gunicorn==21.2.0
EOF

    log "${REQUIREMENTS_FILE} wurde neu erstellt."
}

ensure_dockerfile_benning() {
    if [ -f "${DOCKERFILE_BENNING}" ]; then
        return 0
    fi

    warn "${DOCKERFILE_BENNING} fehlt. Die Datei wird automatisch neu erstellt, damit podman-compose bauen kann."

    cat > "${DOCKERFILE_BENNING}" <<'EOF'
# ============================================================================
# Benning Device Manager - Dockerfile
# Optimiert für Podman/CachyOS-Runtime
# ============================================================================

FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    libmariadb-dev \
    pkg-config \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements_hexagon.txt .

ENV PYTHONOPTIMIZE=2 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN pip install --upgrade pip setuptools wheel && \
    pip install -r requirements_hexagon.txt

COPY . .

RUN useradd -m -u 1000 benning && \
    chown -R benning:benning /app

USER benning

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

ENV FLASK_APP=src.main
ENV FLASK_ENV=production
ENV PYTHONPATH=/app:$PYTHONPATH

CMD ["python", "-m", "gunicorn", \
     "--bind", "0.0.0.0:5000", \
     "--workers", "4", \
     "--worker-class", "sync", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "src.main:create_app()"]
EOF

    log "${DOCKERFILE_BENNING} wurde neu erstellt."
}

ensure_project_files() {
    [ -f "${COMPOSE_FILE}" ] || fail "${COMPOSE_FILE} fehlt. Bitte dieses Skript aus Software/PRG starten."
    [ -f "${SCHEMA_FILE}" ] || fail "${SCHEMA_FILE} fehlt. Die Datenbank kann nicht initialisiert werden."
    ensure_requirements_hexagon
    ensure_dockerfile_benning

    mkdir -p "${INIT_DB_DIR}" logs static/uploads
    cp "${SCHEMA_FILE}" "${INIT_SCHEMA_FILE}"

    if [ ! -f "${ENV_FILE}" ]; then
        if [ -f "${ENV_TEMPLATE}" ]; then
            cp "${ENV_TEMPLATE}" "${ENV_FILE}"
            log ".env wurde aus env.template erstellt."
        else
            cat > "${ENV_FILE}" <<EOF
DB_HOST=${DEFAULT_DB_HOST}
DB_PORT=${DEFAULT_DB_PORT}
DB_USER=${DEFAULT_DB_USER}
DB_PASSWORD=change_me_dguv3
DB_NAME=dguv3_db
DB_ROOT_PASSWORD=change_me_root
DB_HOST_PORT=${DEFAULT_DB_HOST_PORT}
DEFAULT_CUSTOMER=${DEFAULT_CUSTOMER}
FLASK_APP=src.main
FLASK_ENV=production
FLASK_DEBUG=False
FLASK_PORT=${DEFAULT_FLASK_PORT}
SECRET_KEY=change-me-to-a-long-random-secret
LOG_LEVEL=INFO
PYTHONUNBUFFERED=1
PYTHONOPTIMIZE=2
EOF
            log ".env wurde mit Standardwerten erstellt."
        fi
    fi
}

print_current_config() {
    line
    printf 'Aktuelle Runtime-Konfiguration aus %s\n' "${ENV_FILE}"
    line
    printf 'Kunde:          %s\n' "$(get_env_value DEFAULT_CUSTOMER "${DEFAULT_CUSTOMER}")"
    printf 'Datenbank:      %s\n' "$(get_env_value DB_NAME dguv3_db)"
    printf 'DB-Benutzer:    %s\n' "$(get_env_value DB_USER "${DEFAULT_DB_USER}")"
    printf 'DB Host-Port:   %s\n' "$(get_env_value DB_HOST_PORT "${DEFAULT_DB_HOST_PORT}")"
    printf 'Flask-Port:     %s\n' "$(get_env_value FLASK_PORT "${DEFAULT_FLASK_PORT}")"
    line
}

write_runtime_env() {
    local db_name="$1"
    local db_user="$2"
    local db_password="$3"
    local db_root_password="$4"
    local db_host_port="$5"
    local flask_port="$6"
    local customer="$7"

    set_env_value DB_HOST "${DEFAULT_DB_HOST}"
    set_env_value DB_PORT "${DEFAULT_DB_PORT}"
    set_env_value DB_NAME "${db_name}"
    set_env_value DB_USER "${db_user}"
    set_env_value DB_PASSWORD "${db_password}"
    set_env_value DB_ROOT_PASSWORD "${db_root_password}"
    set_env_value DB_HOST_PORT "${db_host_port}"
    set_env_value DEFAULT_CUSTOMER "${customer}"
    set_env_value FLASK_APP "src.main"
    set_env_value FLASK_ENV "production"
    set_env_value FLASK_DEBUG "False"
    set_env_value FLASK_PORT "${flask_port}"
    set_env_value PYTHONUNBUFFERED "1"
    set_env_value PYTHONOPTIMIZE "2"

    if ! grep -Eq '^SECRET_KEY=' "${ENV_FILE}"; then
        set_env_value SECRET_KEY "change-me-to-a-long-random-secret"
    fi
}

start_mysql() {
    log "Starte MySQL-Container."
    podman-compose up -d mysql
}

wait_for_mysql() {
    local root_password="$1"
    local attempt=1
    local max_attempts=45

    log "Warte auf MySQL-Bereitschaft."
    while [ "${attempt}" -le "${max_attempts}" ]; do
        if podman exec "${MYSQL_CONTAINER}" mysqladmin ping -h localhost -uroot -p"${root_password}" --silent >/dev/null 2>&1; then
            log "MySQL ist erreichbar."
            return 0
        fi
        sleep 2
        attempt=$((attempt + 1))
    done

    warn "MySQL war nicht innerhalb der erwarteten Zeit erreichbar. Letzte Container-Logs folgen."
    podman-compose logs --tail=80 mysql || true
    fail "MySQL konnte nicht erfolgreich gestartet oder authentifiziert werden. Prüfe DB_ROOT_PASSWORD in .env."
}

mysql_exec_root() {
    local root_password="$1"
    local sql="$2"
    podman exec -i "${MYSQL_CONTAINER}" mysql -uroot -p"${root_password}" --protocol=socket -e "${sql}"
}

create_or_update_database() {
    local db_name="$1"
    local db_user="$2"
    local db_password="$3"
    local root_password="$4"
    local db_user_sql=""
    local db_password_sql=""

    db_user_sql="$(sql_escape_string "${db_user}")"
    db_password_sql="$(sql_escape_string "${db_password}")"

    log "Lege Datenbank und Anwendungsbenutzer an, falls sie noch nicht existieren."

    mysql_exec_root "${root_password}" "CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql_exec_root "${root_password}" "CREATE USER IF NOT EXISTS '${db_user_sql}'@'%' IDENTIFIED BY '${db_password_sql}';"
    mysql_exec_root "${root_password}" "ALTER USER '${db_user_sql}'@'%' IDENTIFIED BY '${db_password_sql}';"
    mysql_exec_root "${root_password}" "GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user_sql}'@'%'; FLUSH PRIVILEGES;"

    log "Importiere beziehungsweise aktualisiere das Projektschema in ${db_name}."
    podman exec -i "${MYSQL_CONTAINER}" mysql -uroot -p"${root_password}" "${db_name}" < "${SCHEMA_FILE}"
}

start_application() {
    local build_mode="$1"

    if [ "${build_mode}" = "rebuild" ]; then
        log "Baue und starte Flask-Container neu."
        podman-compose up -d --build
    else
        log "Starte Projektcontainer."
        podman-compose up -d
    fi
}

ensure_flask_container_running() {
    local status=""

    if ! podman container exists "${FLASK_CONTAINER}" >/dev/null 2>&1; then
        warn "${FLASK_CONTAINER} wurde noch nicht erstellt. Versuche den Flask-Service gezielt zu starten."
        podman-compose up -d flask || true
    fi

    status="$(podman inspect -f '{{.State.Status}}' "${FLASK_CONTAINER}" 2>/dev/null || true)"

    if [ "${status}" != "running" ]; then
        warn "${FLASK_CONTAINER} ist aktuell im Status '${status:-unbekannt}'. Versuche direkten Start."
        podman start "${FLASK_CONTAINER}" >/dev/null 2>&1 || true
        sleep 3
        status="$(podman inspect -f '{{.State.Status}}' "${FLASK_CONTAINER}" 2>/dev/null || true)"
    fi

    if [ "${status}" != "running" ]; then
        warn "${FLASK_CONTAINER} läuft weiterhin nicht. Letzte Flask-Logs folgen."
        podman logs --tail=120 "${FLASK_CONTAINER}" || true
        fail "Flask-Container konnte nicht gestartet werden. Prüfe die obigen Logs."
    fi

    log "Flask-Container läuft."
}

show_status() {
    local flask_port=""
    local db_host_port=""
    local db_name=""
    local customer=""

    flask_port="$(get_env_value FLASK_PORT "${DEFAULT_FLASK_PORT}")"
    db_host_port="$(get_env_value DB_HOST_PORT "${DEFAULT_DB_HOST_PORT}")"
    db_name="$(get_env_value DB_NAME dguv3_db)"
    customer="$(get_env_value DEFAULT_CUSTOMER "${DEFAULT_CUSTOMER}")"

    log "Containerstatus"
    podman-compose ps || true

    cat <<EOF

Runtime gestartet.

Web-Anwendung:
  http://localhost:${flask_port}

Aktive Datenbank:
  Name: ${db_name}
  Host-Zugriff: localhost:${db_host_port}

Aktiver Standardkunde:
  ${customer}

Nützliche Befehle:
  podman-compose logs -f
  podman-compose ps
  podman-compose down
  podman exec -it ${MYSQL_CONTAINER} mysql -u\$(get_env_value DB_USER "${DEFAULT_DB_USER}") -p ${db_name}
EOF
}

configure_quick_database() {
    local quick_input="$1"

    # Falls durch Shell-Umleitung versehentlich Menütext mitgegeben wurde,
    # wird nur die letzte eingegebene Zeile als Schnelleingabe verwendet.
    quick_input="${quick_input##*$'\n'}"
    local customer_raw=""
    local db_name=""
    local db_user=""
    local db_host_port=""
    local flask_port=""
    local db_password=""
    local db_root_password=""
    local current_db_password=""
    local current_root_password=""
    local extra=""

    IFS=',' read -r customer_raw db_name db_user db_host_port flask_port extra <<< "${quick_input}"

    customer_raw="$(trim_value "${customer_raw:-}")"
    db_name="$(trim_value "${db_name:-}")"
    db_user="$(trim_value "${db_user:-}")"
    db_host_port="$(trim_value "${db_host_port:-}")"
    flask_port="$(trim_value "${flask_port:-}")"
    extra="$(trim_value "${extra:-}")"

    if [ -n "${extra}" ]; then
        fail "Schnelleingabe hat zu viele Felder. Erwartet: Kunde, Datenbank, DB-Benutzer, MySQL-Port, Flask-Port"
    fi

    [ -n "${customer_raw}" ] || fail "Schnelleingabe: Kunde fehlt."
    [ -n "${db_name}" ] || fail "Schnelleingabe: Datenbankname fehlt."
    [ -n "${db_user}" ] || fail "Schnelleingabe: DB-Benutzer fehlt."
    [ -n "${db_host_port}" ] || fail "Schnelleingabe: MySQL-Port fehlt."
    [ -n "${flask_port}" ] || fail "Schnelleingabe: Flask-Port fehlt."

    customer_raw="$(sanitize_customer_display "${customer_raw}")"
    validate_mysql_identifier "Datenbankname" "${db_name}"
    validate_mysql_identifier "Datenbankbenutzer" "${db_user}"
    validate_port "MySQL Host-Port" "${db_host_port}"
    validate_port "Flask/Web-Port" "${flask_port}"

    current_db_password="$(get_env_value DB_PASSWORD "")"
    current_root_password="$(get_env_value DB_ROOT_PASSWORD "")"
    db_password="$(read_secret_default "Passwort für Datenbankbenutzer ${db_user}" "${current_db_password}")"
    db_root_password="$(read_secret_default "Root-Passwort des MySQL-Containers" "${current_root_password}")"

    [ -n "${db_password}" ] || fail "Datenbankpasswort darf nicht leer sein."
    [ -n "${db_root_password}" ] || fail "Root-Passwort darf nicht leer sein."

    line
    printf 'Schnelleingabe erkannt\n'
    line
    printf 'Kunde:             %s\n' "${customer_raw}"
    printf 'Datenbank:         %s\n' "${db_name}"
    printf 'DB-Benutzer:       %s\n' "${db_user}"
    printf 'MySQL Host-Port:   %s\n' "${db_host_port}"
    printf 'Flask/Web-Port:    %s\n' "${flask_port}"
    line

    if ! confirm "Diese Schnelleingabe speichern und Datenbank vorbereiten?"; then
        warn "Schnelleingabe wurde nicht übernommen."
        return 1
    fi

    write_runtime_env "${db_name}" "${db_user}" "${db_password}" "${db_root_password}" "${db_host_port}" "${flask_port}" "${customer_raw}"
    return 0
}

configure_customer_database() {
    local customer_type=""
    local customer_input=""
    local customer=""
    local suggested_db_name=""
    local suggested_db_user=""
    local current_root_password=""
    local current_db_password=""
    local current_db_host_port=""
    local current_flask_port=""
    local db_name=""
    local db_user=""
    local db_password=""
    local db_root_password=""
    local db_host_port=""
    local flask_port=""

    line
    printf 'Eingabemaske: Kundendatenbank vorbereiten\n'
    line
    printf '1) Neuer Kunde mit neuer Datenbank\n'
    printf '2) Bestehender Kunde mit neuer oder vorhandener Datenbank\n'
    printf '3) Abbrechen und vorhandene .env unverändert starten\n'
    line
    read -r -p "Auswahl [1-3]: " customer_type

    case "${customer_type}" in
        1|2) ;;
        3) return 1 ;;
        *) warn "Ungültige Auswahl. Es wird die vorhandene Konfiguration gestartet."; return 1 ;;
    esac

    if [ "${customer_type}" = "1" ]; then
        customer_input="$(read_default "Name des neuen Kunden" "$(get_env_value DEFAULT_CUSTOMER "${DEFAULT_CUSTOMER}")")"
    else
        customer_input="$(read_default "Name des bestehenden Kunden" "$(get_env_value DEFAULT_CUSTOMER "${DEFAULT_CUSTOMER}")")"
    fi

    customer="$(sanitize_customer_display "${customer_input}")"
    suggested_db_name="$(sanitize_identifier "${customer}")_dguv3_db"
    suggested_db_user="$(sanitize_identifier "${customer}")_user"

    current_root_password="$(get_env_value DB_ROOT_PASSWORD "")"
    current_db_password="$(get_env_value DB_PASSWORD "")"
    current_db_host_port="$(get_env_value DB_HOST_PORT "${DEFAULT_DB_HOST_PORT}")"
    current_flask_port="$(get_env_value FLASK_PORT "${DEFAULT_FLASK_PORT}")"

    db_name="$(read_default "Datenbankname" "${suggested_db_name}")"
    db_user="$(read_default "Datenbankbenutzer" "${suggested_db_user}")"
    db_password="$(read_secret_default "Passwort für Datenbankbenutzer" "${current_db_password}")"
    db_root_password="$(read_secret_default "Root-Passwort des MySQL-Containers" "${current_root_password}")"
    db_host_port="$(read_default "MySQL Host-Port" "${current_db_host_port}")"
    flask_port="$(read_default "Flask/Web-Port" "${current_flask_port}")"

    [ -n "${db_name}" ] || fail "Datenbankname darf nicht leer sein."
    [ -n "${db_user}" ] || fail "Datenbankbenutzer darf nicht leer sein."
    [ -n "${db_password}" ] || fail "Datenbankpasswort darf nicht leer sein."
    [ -n "${db_root_password}" ] || fail "Root-Passwort darf nicht leer sein."

    validate_mysql_identifier "Datenbankname" "${db_name}"
    validate_mysql_identifier "Datenbankbenutzer" "${db_user}"

    line
    printf 'Zusammenfassung\n'
    line
    printf 'Kunde:             %s\n' "${customer}"
    printf 'Datenbank:         %s\n' "${db_name}"
    printf 'DB-Benutzer:       %s\n' "${db_user}"
    printf 'MySQL Host-Port:   %s\n' "${db_host_port}"
    printf 'Flask/Web-Port:    %s\n' "${flask_port}"
    line

    if ! confirm "Diese Konfiguration speichern und Datenbank vorbereiten?"; then
        warn "Konfiguration wurde nicht geändert."
        return 1
    fi

    write_runtime_env "${db_name}" "${db_user}" "${db_password}" "${db_root_password}" "${db_host_port}" "${flask_port}" "${customer}"
    return 0
}

main_menu() {
    local choice=""

    cat >&2 <<'EOF'

DGUV3 / Benning Device Manager - Runtime-Starter
================================================

Bitte wählen:

  1) Neue oder bestehende Kundendatenbank per Eingabemaske vorbereiten und starten
  2) Vorhandene .env unverändert starten
  3) Container neu bauen und vorhandene .env starten
  4) Status und aktuelle Konfiguration anzeigen
  5) Beenden

Schnelleingabe alternativ direkt hier möglich:
  Kunde, Datenbank, DB-Benutzer, MySQL-Port, Flask-Port
  Beispiel: TSS - Bierwagen, db_tss_bierwagen, admin, 3307, 5000
EOF

    printf 'Auswahl [1-5] oder Schnelleingabe: ' >&2
    read -r choice
    printf '%s' "${choice}"
}

main() {
    local choice=""
    local build_mode="normal"
    local root_password=""
    local db_name=""
    local db_user=""
    local db_password=""
    local configured_db="false"

    require_command podman
    require_command podman-compose
    ensure_project_files

    while true; do
        print_current_config
        choice="$(main_menu)"

        case "${choice}" in
            1)
                if configure_customer_database; then
                    configured_db="true"
                else
                    configured_db="false"
                fi
                build_mode="rebuild"
                break
                ;;
            2)
                configured_db="false"
                build_mode="normal"
                break
                ;;
            3)
                configured_db="false"
                build_mode="rebuild"
                break
                ;;
            4)
                print_current_config
                podman-compose ps || true
                ;;
            5)
                log "Beendet."
                exit 0
                ;;
            *,*)
                if configure_quick_database "${choice}"; then
                    configured_db="true"
                    build_mode="rebuild"
                    break
                else
                    configured_db="false"
                fi
                ;;
            *)
                warn "Ungültige Auswahl. Bitte 1 bis 5 eingeben oder die Schnelleingabe im Format Kunde, Datenbank, DB-Benutzer, MySQL-Port, Flask-Port verwenden."
                ;;
        esac
    done

    root_password="$(get_env_value DB_ROOT_PASSWORD "")"
    db_name="$(get_env_value DB_NAME dguv3_db)"
    db_user="$(get_env_value DB_USER "${DEFAULT_DB_USER}")"
    db_password="$(get_env_value DB_PASSWORD "")"

    if [ -z "${root_password}" ]; then
        root_password="$(read_secret_default "Root-Passwort des MySQL-Containers" "")"
        set_env_value DB_ROOT_PASSWORD "${root_password}"
    fi

    start_mysql
    wait_for_mysql "${root_password}"

    if [ "${configured_db}" = "true" ]; then
        create_or_update_database "${db_name}" "${db_user}" "${db_password}" "${root_password}"
    fi

    start_application "${build_mode}"
    ensure_flask_container_running
    show_status
}

main "$@"
