# Anleitung: Neue Datenbank "miro_db" einrichten

## Übersicht

Diese Anleitung hilft dir, die neue Datenbank **miro_db** mit dem Benutzer **miro** für deine Benning Flask-Anwendung einzurichten.

## Voraussetzungen

- ✅ `.env` Datei ist bereits aktualisiert
- ✅ Container `benning-flask` läuft (enthält MySQL auf Port 3307)
- ✅ Du hast das MySQL Root-Passwort

## Methode 1: Automatisches Skript (Empfohlen)

### Fish Shell

```fish
# Skript ausführbar machen
chmod +x setup_miro_db.fish

# Skript ausführen
./setup_miro_db.fish
```

### Bash

```bash
# Skript ausführbar machen
chmod +x setup_miro_db.sh

# Skript ausführen
./setup_miro_db.sh
```

Das Skript wird:
1. Container-Status prüfen
2. Nach dem Root-Passwort fragen
3. Neue Datenbank und Benutzer erstellen
4. Verbindung testen
5. Optional: Alte Datenbank sichern
6. Optional: Container neu starten

## Methode 2: Manuell mit SQL-Datei

### Schritt 1: SQL-Datei ausführen

```fish
# Mit Podman
podman exec -i benning-flask mysql -u root -p < create_miro_db.sql

# Oder interaktiv
podman exec -it benning-flask mysql -u root -p
```

### Schritt 2: Im MySQL-Prompt

```sql
SOURCE /path/to/create_miro_db.sql;
```

Oder kopiere den Inhalt von `create_miro_db.sql` und füge ihn ein.

## Methode 3: Manuelle Befehle

### Schritt 1: In MySQL einloggen

```fish
podman exec -it benning-flask mysql -u root -p
```

### Schritt 2: Datenbank erstellen

```sql
-- Neue Datenbank erstellen
CREATE DATABASE IF NOT EXISTS miro_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Neuen Benutzer erstellen
CREATE USER IF NOT EXISTS 'miro'@'%' IDENTIFIED BY 'miro';
CREATE USER IF NOT EXISTS 'miro'@'localhost' IDENTIFIED BY 'miro';

-- Rechte vergeben
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'%';
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'localhost';

-- Rechte aktualisieren
FLUSH PRIVILEGES;

-- Prüfen
SHOW DATABASES LIKE 'miro_db';
SELECT User, Host FROM mysql.user WHERE User='miro';

-- Verlassen
EXIT;
```

## Nach dem Setup: Container neu starten

**WICHTIG**: Container STOPPEN und NEU STARTEN (nicht nur restart!)

```fish
# Container stoppen
podman stop benning-flask

# Container starten
podman start benning-flask

# Logs verfolgen
podman logs -f benning-flask
```

## Verbindung testen

### Von außerhalb des Containers

```fish
# Mit mysql client
mysql -h localhost -P 3307 -u miro -p miro_db

# Passwort: miro
```

### Innerhalb des Containers

```fish
podman exec -it benning-flask mysql -u miro -p miro_db
```

## Anwendung testen

```fish
# Health Check
curl http://localhost:5000/health

# API Info
curl http://localhost:5000/
```

## Alte Datenbank sichern (Optional)

Falls du die alte Datenbank `benning_device_manager` sichern möchtest:

```fish
# Backup erstellen
podman exec benning-flask mysqldump -u root -p benning_device_manager > backup_benning_$(date +%Y%m%d_%H%M%S).sql
```

## Alte Datenbank löschen (Optional)

**Achtung**: Nur ausführen, wenn du sicher bist!

```fish
podman exec -it benning-flask mysql -u root -p
```

```sql
-- Alte Datenbank löschen
DROP DATABASE IF EXISTS benning_device_manager;

-- Alten Benutzer löschen (falls gewünscht)
DROP USER IF EXISTS 'benning'@'%';
DROP USER IF EXISTS 'benning'@'localhost';

FLUSH PRIVILEGES;
EXIT;
```

## Problembehandlung

### Problem: "Access denied for user 'miro'@'localhost'"

**Lösung**: Stelle sicher, dass der Benutzer für beide Hosts erstellt wurde:

```sql
CREATE USER IF NOT EXISTS 'miro'@'%' IDENTIFIED BY 'miro';
CREATE USER IF NOT EXISTS 'miro'@'localhost' IDENTIFIED BY 'miro';
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'%';
GRANT ALL PRIVILEGES ON miro_db.* TO 'miro'@'localhost';
FLUSH PRIVILEGES;
```

### Problem: "Unknown database 'miro_db'"

**Lösung**: Datenbank wurde nicht erstellt. Führe aus:

```sql
CREATE DATABASE miro_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### Problem: Container startet nicht

**Lösung**: Logs prüfen:

```fish
podman logs benning-flask
```

### Problem: Port 3307 bereits belegt

**Lösung**: Prüfe, welcher Prozess den Port verwendet:

```fish
ss -tlnp | grep 3307
# Oder
lsof -i :3307
```

## Aktuelle Konfiguration

Deine `.env` Datei sollte folgende Werte haben:

```
DB_HOST=localhost
DB_PORT=3307
DB_USER=miro
DB_PASSWORD=miro
DB_NAME=miro_db
```

## Zusammenfassung

✅ Neue Datenbank: **miro_db**  
✅ Neuer Benutzer: **miro**  
✅ Passwort: **miro**  
✅ Container: **benning-flask**  
✅ Port: **3307**  
✅ Character Set: **utf8mb4**  
✅ Collation: **utf8mb4_unicode_ci**

---

**Viel Erfolg! 🚀**

Bei Fragen oder Problemen, überprüfe die Logs:
```fish
podman logs -f benning-flask
```
