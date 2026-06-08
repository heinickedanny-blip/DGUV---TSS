# 🚀 Schnellstart: Neue Datenbank einrichten

## Für eilige Benutzer - 3 Befehle

### Option 1: Automatisches Skript (Fish Shell)

```fish
chmod +x setup_miro_db.fish && ./setup_miro_db.fish
```

### Option 2: Automatisches Skript (Bash)

```bash
chmod +x setup_miro_db.sh && ./setup_miro_db.sh
```

### Option 3: Manuell (Copy & Paste)

```fish
# 1. In MySQL einloggen (im Container benning-flask)
podman exec -it benning-flask mysql -u root -p

# 2. Diese SQL-Befehle ausführen:
CREATE DATABASE IF NOT EXISTS miro_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'miro'@'%' IDENTIFIED BY 'miro';
CREATE USER IF NOT EXISTS 'miro'@'localhost' IDENTIFIED BY 'miro';
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'%';
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# 3. Container STOPPEN und NEU STARTEN (nicht nur restart!)
podman stop benning-flask
podman start benning-flask

# 4. Logs prüfen
podman logs -f benning-flask
```

## Danach testen

```fish
# Verbindung testen
podman exec -it benning-flask mysql -u miro -p miro_db

# Anwendung testen
curl http://localhost:5000/health
```

---

**Das war's! 🎉**

Für detaillierte Informationen siehe `ANLEITUNG_MIRO_DB.md`
