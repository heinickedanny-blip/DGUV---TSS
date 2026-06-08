# 🐟 Benning Device Manager - Fish Shell Guide

Dieses Dokument enthält spezialisierte Anweisungen für die Verwendung des Benning Device Manager Projekts mit **Fish Shell** auf CachyOS.

> **Fish Shell** ist eine benutzerfreundliche Shell mit besserer Syntax-Hervorhebung und Auto-Completion. Diese Anleitung ist speziell für Fish optimiert.

---

## 📋 Fish Shell Installation

Falls Fish noch nicht installiert ist:

```fish
sudo pacman -S fish
# Oder als Standard-Shell setzen
chsh -s /usr/bin/fish
```

---

## 🚀 Quick Start mit Fish

```fish
# 1. Zum Projektverzeichnis navigieren
cd ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG

# 2. Aktivierungsskript für Fish
source activate_cachyos.fish

# 3. Virtual Environment aktivieren (falls nicht bereits aktiv)
source venv/bin/activate.fish

# 4. Anwendung starten
python src/main.py
```

Öffnen Sie dann: **http://localhost:5000**

---

## 🐟 Fish Shell Spezifische Befehle

### Virtual Environment aktivieren

```fish
# Automatisch mit Fish-Skript
source activate_cachyos.fish

# Oder manuell
source venv/bin/activate.fish
```

### PYTHONPATH setzen (Fish Syntax)

```fish
# In Fish Shell
set -x PYTHONPATH (pwd):$PYTHONPATH

# Oder persistent in ~/.config/fish/config.fish
set -Ux PYTHONPATH /home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG:$PYTHONPATH
```

### Umgebungsvariablen in Fish

```fish
# Temporär (nur diese Session)
set -x FLASK_ENV development
set -x FLASK_DEBUG True

# Permanent (in ~/.config/fish/config.fish)
set -Ux FLASK_ENV development
set -Ux FLASK_DEBUG True
```

---

## 🗄️ Docker MySQL Verbindung (Port 3307)

Ihre MySQL-Datenbank läuft bereits in Docker auf **Port 3307**:

```fish
# Container-Status überprüfen
docker ps | grep benning-flask-mysql

# Container-Logs anzeigen
docker logs benning-flask-mysql

# Container neu starten (falls nötig)
docker restart benning-flask-mysql
```

### .env Konfiguration für Docker MySQL

```fish
# .env Datei mit Docker-Einstellungen erstellen
cat > .env << 'EOF'
# Flask Konfiguration
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=dev-secret-key-change-in-production

# Datenbank (Docker MySQL auf Port 3307)
DB_HOST=localhost
DB_PORT=3307
DB_USER=benning
DB_PASSWORD=benning
DB_NAME=benning_device_manager

# Upload Folder
UPLOAD_FOLDER=static/uploads
MAX_CONTENT_LENGTH=10485760

# Logging
LOG_LEVEL=DEBUG

# Fish Shell Spezifisch
set -x PYTHONOPTIMIZE 2
set -x PYTHONHASHSEED 0
EOF
```

### MySQL Container testen

```fish
# Verbindung testen
mysql -h localhost -P 3307 -u benning -p benning_device_manager

# Oder mit Docker exec
docker exec -it benning-flask-mysql mysql -u benning -p benning_device_manager
```

---

## 🎨 Fish Shell Funktionen für Benning

Fügen Sie diese Funktionen zu `~/.config/fish/config.fish` hinzu:

```fish
# Benning-Projekt öffnen
function benning
    cd ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
    source activate_cachyos.fish
    echo "✓ Benning-Projekt aktiviert"
end

# Benning starten
function benning-start
    benning
    python src/main.py
end

# Benning Tests
function benning-test
    benning
    pytest -v
end

# Benning Code formatieren
function benning-format
    benning
    black src/
    flake8 src/
    mypy src/
    isort src/
    echo "✓ Code formatiert"
end

# Benning Logs anzeigen
function benning-logs
    docker logs -f benning-flask-mysql
end

# Benning Status
function benning-status
    echo "=== Docker Container ==="
    docker ps | grep benning
    echo ""
    echo "=== Aktive Ports ==="
    ss -tlnp | grep -E '3307|5000'
end

# Benning Database verbinden
function benning-db
    docker exec -it benning-flask-mysql mysql -u benning -p benning_device_manager
end
```

Dann können Sie einfach folgende Befehle verwenden:

```fish
benning              # Projekt öffnen
benning-start        # Anwendung starten
benning-test         # Tests ausführen
benning-format       # Code formatieren
benning-logs         # Datenbank-Logs
benning-status       # Status überprüfen
benning-db           # Datenbank verbinden
```

---

## 🧪 Tests mit Fish

```fish
# Alle Tests
pytest

# Mit Verbose Output
pytest -v

# Mit Coverage
pytest --cov=src --cov-report=html

# Spezifische Tests
pytest tests/unit/ -v
pytest tests/integration/ -v

# Tests mit Farben
pytest --color=yes
```

---

## 🎨 Code Quality mit Fish

```fish
# Formatierung
black src/

# Linting
flake8 src/

# Type Checking
mypy src/

# Import Sorting
isort src/

# Alle zusammen
black src/; flake8 src/; mypy src/; isort src/
```

---

## 🐳 Docker MySQL Management mit Fish

```fish
# Container starten
docker start benning-flask-mysql

# Container stoppen
docker stop benning-flask-mysql

# Container neu starten
docker restart benning-flask-mysql

# Container Logs (Echtzeit)
docker logs -f benning-flask-mysql

# Container Shell öffnen
docker exec -it benning-flask-mysql bash

# MySQL in Container verbinden
docker exec -it benning-flask-mysql mysql -u benning -p benning_device_manager

# Container Ressourcen anzeigen
docker stats benning-flask-mysql
```

---

## 📊 Nützliche Fish Shell Aliases

Fügen Sie zu `~/.config/fish/config.fish` hinzu:

```fish
# Projekt-Navigation
alias bprj='cd ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG'
alias bvenv='source venv/bin/activate.fish'

# Datenbank
alias bmysql='docker exec -it benning-flask-mysql mysql -u benning -p benning_device_manager'
alias bdocker='docker ps | grep benning'

# Python
alias bp='python'
alias bpy='python src/main.py'
alias btest='pytest -v'
alias bfmt='black src/ && flake8 src/'

# Logs
alias blogs='docker logs -f benning-flask-mysql'
alias bstatus='docker ps | grep benning && ss -tlnp | grep 3307'
```

Dann können Sie schnell folgende Befehle nutzen:

```fish
bprj          # Zum Projekt navigieren
bvenv         # Virtual Environment aktivieren
bmysql        # Datenbank verbinden
bdocker       # Docker Container anzeigen
bpy           # Anwendung starten
btest         # Tests ausführen
bfmt          # Code formatieren
blogs         # Logs anzeigen
bstatus       # Status überprüfen
```

---

## 🔧 Fish Shell Konfiguration

### config.fish Datei

Bearbeiten Sie `~/.config/fish/config.fish`:

```fish
# Benning-Projekt Variablen
set -Ux BENNING_HOME ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
set -Ux BENNING_VENV $BENNING_HOME/venv

# Python-Optimierungen
set -Ux PYTHONOPTIMIZE 2
set -Ux PYTHONHASHSEED 0

# Flask-Einstellungen
set -Ux FLASK_ENV development
set -Ux FLASK_DEBUG True

# Farben für Fish
set fish_color_command green
set fish_color_param blue
set fish_color_operator red
```

---

## 🚀 Startup-Skript für Fish

Erstellen Sie `~/.config/fish/conf.d/benning.fish`:

```fish
#!/usr/bin/env fish

# Benning Device Manager - Fish Shell Konfiguration

# Funktion zum Aktivieren von Benning
function benning-activate
    set -l BENNING_DIR ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
    
    if test -d $BENNING_DIR
        cd $BENNING_DIR
        
        # Virtual Environment aktivieren
        if test -f venv/bin/activate.fish
            source venv/bin/activate.fish
            echo "✓ Benning Virtual Environment aktiviert"
        end
        
        # Umgebungsvariablen setzen
        set -x PYTHONPATH (pwd):$PYTHONPATH
        set -x PYTHONOPTIMIZE 2
        
        echo "✓ PYTHONPATH gesetzt"
        echo "✓ Bereit zum Starten: python src/main.py"
    else
        echo "✗ Benning-Verzeichnis nicht gefunden: $BENNING_DIR"
    end
end

# Automatisch beim Start ausführen (optional)
# benning-activate
```

---

## 📡 API Testen mit Fish

```fish
# Health Check
curl http://localhost:5000/health

# API Info
curl http://localhost:5000/

# Mit Pretty-Print
curl http://localhost:5000/ | jq .

# POST Request
curl -X POST http://localhost:5000/api/devices \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Device", "model": "XYZ"}'
```

---

## 🐛 Häufige Fish Shell Fehler

| Fehler | Lösung |
|--------|--------|
| `command not found: activate_cachyos.fish` | `source activate_cachyos.fish` (mit voller Pfad) |
| `PYTHONPATH not set` | `set -x PYTHONPATH (pwd):$PYTHONPATH` |
| `Port already in use` | `ss -tlnp \| grep 5000` |
| `Docker container not running` | `docker start benning-flask-mysql` |
| `MySQL connection refused` | `docker logs benning-flask-mysql` |

---

## 💡 Fish Shell Best Practices

1. **Variablen mit `set -x` exportieren:**
   ```fish
   set -x VARIABLE_NAME value
   ```

2. **Funktionen für häufige Aufgaben:**
   ```fish
   function my-function
       echo "Doing something..."
   end
   ```

3. **Conditional Statements:**
   ```fish
   if test -f file.txt
       echo "File exists"
   end
   ```

4. **Loops:**
   ```fish
   for item in (ls)
       echo $item
   end
   ```

5. **Pipes und Redirection:**
   ```fish
   cat file.txt | grep pattern > output.txt
   ```

---

## 🔐 Sicherheit in Fish

### Sichere Passwörter

```fish
# Passwort-Eingabe (wird nicht angezeigt)
read -s -p "Enter password: " password

# Passwort in Variable speichern
set -x DB_PASSWORD $password
```

### Sichere Secrets

Verwenden Sie niemals Passwörter in der Konfiguration:

```fish
# ✗ NICHT MACHEN
set -x DB_PASSWORD "benning"

# ✓ BESSER: In .env Datei
# Dann mit: source .env
```

---

## 📚 Fish Shell Ressourcen

- **Fish Shell Dokumentation:** https://fishshell.com/docs/current/
- **Fish Shell GitHub:** https://github.com/fish-shell/fish-shell
- **Fish Shell Cookbook:** https://fishshell.com/docs/current/tutorial.html

---

## 🚀 Vollständiger Workflow mit Fish

```fish
# 1. Projekt öffnen
cd ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG

# 2. Fish Aktivierungsskript laden
source activate_cachyos.fish

# 3. Virtual Environment aktivieren
source venv/bin/activate.fish

# 4. Umgebungsvariablen setzen
set -x PYTHONPATH (pwd):$PYTHONPATH
set -x FLASK_ENV development

# 5. Datenbank überprüfen
docker ps | grep benning

# 6. Tests ausführen
pytest -v

# 7. Code formatieren
black src/ && flake8 src/

# 8. Anwendung starten
python src/main.py

# 9. In anderem Terminal: API testen
curl http://localhost:5000/health | jq .
```

---

## 🎯 Schnelle Befehle für Fish

```fish
# Projekt-Navigation
bprj && bvenv

# Starten
python src/main.py

# Tests
pytest --cov=src

# Formatierung
black src/ && flake8 src/

# Datenbank-Status
docker ps | grep benning

# Logs
docker logs -f benning-flask-mysql
```

---

**Version:** 2.0.0 (Fish Shell Edition)  
**Status:** ✅ Optimiert für Fish Shell  
**Letzte Aktualisierung:** Januar 2026

**Viel Erfolg mit Fish! 🐟**
