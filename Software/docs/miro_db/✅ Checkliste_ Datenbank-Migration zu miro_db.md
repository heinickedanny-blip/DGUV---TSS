# ✅ Checkliste: Datenbank-Migration zu miro_db

## Vor dem Start

- [ ] `.env` Datei ist aktualisiert mit:
  ```
  DB_USER=miro
  DB_PASSWORD=miro
  DB_NAME=miro_db
  ```
- [ ] Container `benning-flask` läuft
- [ ] MySQL Root-Passwort ist bekannt
- [ ] Backup der alten Datenbank erstellt (optional)

## Datenbank erstellen

- [ ] Neue Datenbank `miro_db` erstellt
- [ ] Benutzer `miro` erstellt (für '%' und 'localhost')
- [ ] Berechtigungen vergeben
- [ ] Verbindung getestet

## Anwendung aktualisieren

- [ ] Container `benning-flask` GESTOPPT (mit `podman stop`)
- [ ] Container `benning-flask` NEU GESTARTET (mit `podman start`)
- [ ] Logs überprüft (keine Fehler)
- [ ] Anwendung erreichbar unter http://localhost:5000

## Funktionstest

- [ ] Health-Check funktioniert: `curl http://localhost:5000/health`
- [ ] Login funktioniert
- [ ] Geräte können hinzugefügt werden
- [ ] Daten werden gespeichert

## Aufräumen (Optional)

- [ ] Alte Datenbank `benning_device_manager` gesichert
- [ ] Alte Datenbank gelöscht (wenn nicht mehr benötigt)
- [ ] Alter Benutzer `benning` gelöscht (wenn nicht mehr benötigt)

## Bei Problemen

- [ ] Logs geprüft: `podman logs benning-flask`
- [ ] Verbindung manuell getestet: `mysql -h localhost -P 3307 -u miro -p miro_db`
- [ ] `.env` Datei nochmal überprüft
- [ ] Container neu gestartet (STOP dann START, nicht restart!)

---

## Schnellbefehle für Problembehebung

```fish
# Container-Status
podman ps -a | grep benning

# Logs anzeigen
podman logs benning-flask
podman logs --tail 50 benning-flask

# Container neu starten (WICHTIG: stop dann start!)
podman stop benning-flask
podman start benning-flask

# Datenbank-Verbindung testen
podman exec -it benning-flask mysql -u miro -p miro_db

# Benutzer und Datenbanken anzeigen
podman exec -it benning-flask mysql -u root -p -e "SHOW DATABASES; SELECT User, Host FROM mysql.user WHERE User='miro';"

# Berechtigungen prüfen
podman exec -it benning-flask mysql -u root -p -e "SHOW GRANTS FOR 'miro'@'%';"
```

---

## Wichtige Hinweise

⚠️ **Container STOPPEN und NEU STARTEN** (nicht nur restart!)
```fish
podman stop benning-flask
podman start benning-flask
```

⚠️ **Benutzer für beide Hosts erstellen**
- `'miro'@'%'` für externe Verbindungen
- `'miro'@'localhost'` für interne Verbindungen

⚠️ **Character Set prüfen**
- Datenbank muss `utf8mb4` verwenden
- Collation: `utf8mb4_unicode_ci`

---

**Status**: ⬜ Nicht gestartet | 🔄 In Arbeit | ✅ Abgeschlossen
