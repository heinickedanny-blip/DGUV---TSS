#!/usr/bin/env bash

# ============================================================================
# DGUV3 / Benning Device Manager - Container Tools Installer für CachyOS
# ============================================================================
# Zweck:
#   Installiert die benötigten Container-Werkzeuge für die Podman-basierte
#   Projektumgebung auf CachyOS beziehungsweise Arch-basierten Systemen.
#
# Installiert standardmäßig:
#   - podman
#   - podman-compose
#   - netavark / aardvark-dns für Podman-Netzwerke
#   - slirp4netns und fuse-overlayfs für rootless Container
#   - crun als OCI Runtime
#   - Git und typische Diagnosewerkzeuge
#
# Nutzung:
#   chmod +x install_container_tools.sh
#   ./install_container_tools.sh
#
# Optional:
#   ./install_container_tools.sh --docker-compat
#
# Hinweis:
#   Die Option --docker-compat installiert zusätzlich podman-docker, damit
#   einfache docker-Kommandos auf Podman umgeleitet werden können. Diese Option
#   sollte nicht verwendet werden, wenn parallel eine echte Docker-Installation
#   aktiv genutzt wird.
# ============================================================================

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
INSTALL_DOCKER_COMPAT="false"
CURRENT_USER="${SUDO_USER:-$(whoami)}"

if [ "${EUID}" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

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

usage() {
    cat <<EOF
${SCRIPT_NAME} - Container Tools Installer für CachyOS/Arch

Nutzung:
  ./${SCRIPT_NAME} [Optionen]

Optionen:
  --docker-compat     Installiert podman-docker für einfache Docker-CLI-Kompatibilität.
  -h, --help          Zeigt diese Hilfe.

Beispiele:
  ./${SCRIPT_NAME}
  ./${SCRIPT_NAME} --docker-compat
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --docker-compat)
            INSTALL_DOCKER_COMPAT="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "Unbekannte Option: $1"
            ;;
    esac
done

log "DGUV3 / Benning Device Manager - Container Tools Installer"
printf '===========================================================\n'

if [ ! -r /etc/os-release ]; then
    fail "/etc/os-release konnte nicht gelesen werden. Das System wird nicht erkannt."
fi

# shellcheck disable=SC1091
. /etc/os-release

log "Erkanntes System: ${PRETTY_NAME:-unbekannt}"

if ! command -v pacman >/dev/null 2>&1; then
    fail "Dieses Skript ist für CachyOS/Arch-basierte Systeme mit pacman gedacht."
fi

if ! grep -qiE 'cachyos|arch' /etc/os-release; then
    warn "Dieses System scheint nicht CachyOS/Arch-basiert zu sein. Fortsetzung auf eigene Verantwortung."
fi

if ! command -v sudo >/dev/null 2>&1 && [ "${EUID}" -ne 0 ]; then
    fail "sudo ist nicht installiert. Bitte als root ausführen oder sudo installieren."
fi

if [ "${EUID}" -ne 0 ]; then
    log "Prüfe sudo-Berechtigung. Möglicherweise wird dein Passwort abgefragt."
    sudo -v
fi

log "Synchronisiere Paketdatenbank."
${SUDO} pacman -Sy --noconfirm

PACKAGES=(
    podman
    podman-compose
    netavark
    aardvark-dns
    slirp4netns
    fuse-overlayfs
    crun
    git
    curl
    wget
    jq
    nano
    less
    lsof
    htop
)

if [ "${INSTALL_DOCKER_COMPAT}" = "true" ]; then
    PACKAGES+=(podman-docker)
fi

log "Installiere Container- und Diagnosewerkzeuge."
${SUDO} pacman -S --needed --noconfirm "${PACKAGES[@]}"

log "Konfiguriere rootless Podman-Voraussetzungen für Benutzer: ${CURRENT_USER}"

if ! getent passwd "${CURRENT_USER}" >/dev/null 2>&1; then
    fail "Benutzer ${CURRENT_USER} wurde nicht gefunden."
fi

if ! grep -q "^${CURRENT_USER}:" /etc/subuid 2>/dev/null; then
    ${SUDO} usermod --add-subuids 100000-165535 "${CURRENT_USER}"
else
    log "subuid-Eintrag für ${CURRENT_USER} existiert bereits."
fi

if ! grep -q "^${CURRENT_USER}:" /etc/subgid 2>/dev/null; then
    ${SUDO} usermod --add-subgids 100000-165535 "${CURRENT_USER}"
else
    log "subgid-Eintrag für ${CURRENT_USER} existiert bereits."
fi

log "Aktiviere Podman User Socket, sofern eine systemd-User-Session verfügbar ist."
if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user status >/dev/null 2>&1; then
        systemctl --user enable --now podman.socket || warn "podman.socket konnte in der User-Session nicht aktiviert werden."
    else
        warn "Keine aktive systemd-User-Session erkannt. podman.socket kann nach erneutem Login mit folgendem Befehl aktiviert werden: systemctl --user enable --now podman.socket"
    fi
else
    warn "systemctl ist nicht verfügbar. Überspringe Socket-Aktivierung."
fi

log "Prüfe installierte Versionen."
podman --version || fail "podman konnte nicht ausgeführt werden."
podman-compose --version || fail "podman-compose konnte nicht ausgeführt werden."

if [ "${INSTALL_DOCKER_COMPAT}" = "true" ]; then
    if command -v docker >/dev/null 2>&1; then
        docker --version || warn "docker-Kompatibilitätskommando ist vorhanden, konnte aber nicht sauber ausgeführt werden."
    else
        warn "podman-docker wurde angefordert, aber kein docker-Kommando gefunden. Bitte Paketinstallation prüfen."
    fi
fi

log "Führe kurzen Podman-Funktionstest aus."
if podman info >/tmp/podman_info_check.log 2>&1; then
    log "podman info erfolgreich."
else
    warn "podman info meldet ein Problem. Details:"
    sed -n '1,120p' /tmp/podman_info_check.log >&2
    warn "Falls gerade subuid/subgid neu gesetzt wurden, bitte einmal abmelden und wieder anmelden."
fi

cat <<'EOF'

Installation abgeschlossen.

Empfohlene nächsten Schritte für das DGUV3-Projekt:

  git clone https://github.com/ydh-embedded/Benning---DGUV3.git
  cd Benning---DGUV3
  bash Software/Tools/05_db_Tools/install_dguv3_podman_project.sh Software/PRG

Wichtige Projektbefehle:

  cd Software/PRG
  podman-compose up -d --build
  podman-compose logs -f
  podman-compose ps
  podman-compose down

Falls rootless Podman nach dieser Installation noch nicht funktioniert,
melde dich einmal vollständig ab und wieder an. Dadurch werden neue
subuid/subgid-Zuordnungen zuverlässig in der Benutzersitzung wirksam.
EOF
