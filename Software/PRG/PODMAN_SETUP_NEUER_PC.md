# Podman-Setup für neuen PC: Benning / DGUV3 Device Manager

**Autor:** Manus AI  
**Stand:** 2026-06-09

## Ziel der Anpassung

Dieses Projekt ist als **Podman-Container-Umgebung** vorbereitet. Auf einem neuen PC müssen deshalb nicht alle Python-Frameworks manuell in einer lokalen virtuellen Umgebung installiert werden. Die Anwendung läuft im Flask-Container, die Datenbank läuft im MySQL-Container, und die wichtigsten Werte werden über die Datei `.env` gesetzt. Podman stellt Container ohne klassischen Docker-Daemon bereit; `podman-compose` liest die Compose-Datei und startet daraus mehrere zusammenhängende Services.[^1] [^2]

| Bereich | Umsetzung im Projekt |
|---|---|
| Web-Anwendung | Flask/Python im Container `benning-flask` |
| Datenbank | MySQL 8 im Container `benning-mysql` |
| Datenbank-Initialisierung | Automatischer Import aus `init-db/01_schema.sql` beim ersten Start des leeren Datenbankvolumes |
| Konfiguration | `.env`, erzeugt aus `env.template` beziehungsweise `.env.example` |
| Kundendaten | `DEFAULT_CUSTOMER`, z. B. `TSS`, erzeugt Geräte-IDs wie `TSS-00001` |

## Was auf dem neuen PC installiert werden muss

Auf dem Host-PC brauchst du im Kern **Git**, **Podman** und **podman-compose**. Die Python-Pakete aus `requirements_hexagon.txt` werden beim Container-Build im Image installiert; sie müssen also nicht manuell auf dem Host eingerichtet werden.

| Komponente | Zweck | Installation auf CachyOS/Arch-artigen Systemen |
|---|---|---|
| Git | Repository klonen | `sudo pacman -S git` |
| Podman | Container-Runtime | `sudo pacman -S podman` |
| podman-compose | Compose-Start mehrerer Container | `sudo pacman -S podman-compose` |
| Python/Pip auf Host | Normalerweise nicht nötig | Wird im Container über `Dockerfile.benning` behandelt |

Im Repository liegt bereits ein Host-Installer unter `Software/Tools/05_db_Tools/install_podman_cachyos.sh`. Dieser ist für CachyOS/Arch-Umgebungen gedacht und installiert Podman, podman-compose sowie Hilfswerkzeuge.

## Empfohlener Ablauf auf dem neuen PC

Klonen Sie zunächst das Repository und wechseln Sie in das Projektverzeichnis:

```bash
git clone https://github.com/ydh-embedded/Benning---DGUV3.git
cd Benning---DGUV3
```

Falls Podman noch nicht installiert ist, kann auf CachyOS/Arch-artigen Systemen das vorhandene Installationsskript verwendet werden:

```bash
bash Software/Tools/05_db_Tools/install_podman_cachyos.sh
```

Danach wird das Projekt mit dem neuen parametrierten Installer gestartet:

```bash
bash Software/Tools/05_db_Tools/install_dguv3_podman_project.sh Software/PRG
```

Der Installer legt bei Bedarf `Software/PRG/.env` aus `env.template` an, erstellt `init-db/01_schema.sql`, baut das Flask-Image und startet MySQL sowie Flask mit `podman-compose`.

## Datenbank und Kundendaten anpassen

Die neue Datenbank wird über `.env` gesteuert. Öffnen Sie nach dem ersten Erstellen der Datei:

```bash
nano Software/PRG/.env
```

Die wichtigsten Werte sind:

| Variable | Beispiel | Bedeutung |
|---|---|---|
| `DB_NAME` | `tss_dguv3_db` | Name der neu anzulegenden MySQL-Datenbank |
| `DB_USER` | `tss` | Benutzer der Anwendung für MySQL |
| `DB_PASSWORD` | `bitte_aendern` | Passwort des DB-Benutzers |
| `DB_ROOT_PASSWORD` | `bitte_aendern_root` | Root-Passwort des MySQL-Containers |
| `DB_HOST_PORT` | `3307` | Port, über den MySQL vom Host erreichbar ist |
| `DEFAULT_CUSTOMER` | `TSS` | Standardkunde im Schnellerfassungsformular |
| `FLASK_PORT` | `5000` | Port der Web-Anwendung |

> Wichtig: Wenn MySQL bereits einmal gestartet wurde, bleiben Daten im benannten Volume `mysql_data` erhalten. Eine Änderung von `DB_NAME` erzeugt nicht automatisch eine komplett neue Datenbank, solange das alte Volume weiterverwendet wird. Für eine wirklich frische Datenbank muss das alte Volume bewusst entfernt oder ein neues Volume in `podman-compose.yml` verwendet werden.

Für eine komplette Neuinitialisierung auf einem Testsystem kann folgender Ablauf verwendet werden. Dabei werden alle bisherigen MySQL-Daten des Projektvolumes gelöscht:

```bash
cd Software/PRG
podman-compose down
podman volume rm prg_mysql_data 2>/dev/null || podman volume rm software_prg_mysql_data 2>/dev/null || true
podman-compose up -d --build
```

Prüfen Sie vor dem Löschen unbedingt, ob keine produktiven Daten im Volume liegen.

## Welche Projektdateien angepasst wurden

| Datei | Änderung |
|---|---|
| `podman-compose.yml` | Datenbank-, Benutzer- und Kundenwerte wurden parametrisierbar gemacht; MySQL-Host-Port läuft über `DB_HOST_PORT`. |
| `env.template` | Neue, klare Vorlage für Podman inklusive `DEFAULT_CUSTOMER`. |
| `.env.example` | Kopie der Vorlage für sichere Weitergabe ohne echte Passwörter. |
| `schema.sql` | Vollständiges MySQL-Schema inklusive DGUV3-Werten und USB-Kabel-Feldern. |
| `init-db/01_schema.sql` | Automatisches Initialisierungsschema für den MySQL-Container. |
| `src/config/dependencies.py` | Container-kompatible Standardwerte für die DB-Verbindung. |
| `src/main.py` | Standardkunde wird aus `DEFAULT_CUSTOMER` gelesen. |
| `templates/quick_add.html` | Schnellerfassung zeigt Standardkunde und echte nächste Geräte-ID aus der API an. |
| `Software/Tools/05_db_Tools/install_dguv3_podman_project.sh` | Neuer Projektinstaller für den Podman-Stack. |

## Nützliche Befehle

| Aufgabe | Befehl |
|---|---|
| Stack starten | `cd Software/PRG && podman-compose up -d` |
| Stack mit Build starten | `cd Software/PRG && podman-compose up -d --build` |
| Logs anzeigen | `cd Software/PRG && podman-compose logs -f` |
| Containerstatus prüfen | `cd Software/PRG && podman-compose ps` |
| Stack stoppen | `cd Software/PRG && podman-compose down` |
| MySQL-Shell öffnen | `podman exec -it benning-mysql mysql -u$DB_USER -p $DB_NAME` |

## Ergebnis

Nach erfolgreichem Start ist die Anwendung standardmäßig unter folgendem Link erreichbar:

```text
http://localhost:5000
```

Wenn `DEFAULT_CUSTOMER=TSS` gesetzt ist, zeigt die Schnellerfassung direkt den Kunden **TSS** an und erzeugt Geräte-IDs im Format **TSS-00001**, **TSS-00002** und so weiter.

## References

[^1]: [Podman Documentation](https://docs.podman.io/)  
[^2]: [podman-compose project](https://github.com/containers/podman-compose)
