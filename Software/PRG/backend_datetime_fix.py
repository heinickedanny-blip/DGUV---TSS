#!/usr/bin/env python3
"""
Backend-Anpassung für Datum + Uhrzeit Speicherung
Prüft und zeigt, wie das Backend angepasst werden muss
"""

print("""
================================================================================
Backend-Anpassung: Datum + Uhrzeit für last_inspection
================================================================================

PROBLEM:
--------
Das Frontend sendet jetzt zwei Felder:
- last_inspection_date (z.B. "2026-02-20")
- last_inspection_time (z.B. "14:35")

Diese müssen im Backend zu einem DATETIME kombiniert werden.

LÖSUNG:
-------
In der Route, die das Formular verarbeitet (z.B. /quick_add oder /devices/add):

# Vorher (nur Datum):
last_inspection = request.form.get('last_inspection')
device.last_inspection = datetime.strptime(last_inspection, '%Y-%m-%d')

# Nachher (Datum + Uhrzeit):
from datetime import datetime

last_inspection_date = request.form.get('last_inspection_date')
last_inspection_time = request.form.get('last_inspection_time')

# Kombiniere Datum und Uhrzeit
datetime_str = f"{last_inspection_date} {last_inspection_time}"
device.last_inspection = datetime.strptime(datetime_str, '%Y-%m-%d %H:%M')

BEISPIEL:
---------
Input:
  last_inspection_date = "2026-02-20"
  last_inspection_time = "14:35"

Output:
  device.last_inspection = datetime(2026, 2, 20, 14, 35, 0)
  
In Datenbank gespeichert als:
  2026-02-20 14:35:00

DATEIEN ZU PRÜFEN:
------------------
1. /home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG/src/adapters/web/routes.py
   oder
2. /home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG/routes.py

Suche nach:
- @app.route('/quick_add')
- request.form.get('last_inspection')
- strptime

VOLLSTÄNDIGER CODE-BLOCK:
--------------------------
""")

print("""
from datetime import datetime
from flask import request

@app.route('/quick_add', methods=['POST'])
def quick_add():
    # ... andere Felder ...
    
    # Datum und Uhrzeit kombinieren
    last_inspection_date = request.form.get('last_inspection_date')
    last_inspection_time = request.form.get('last_inspection_time')
    
    if last_inspection_date and last_inspection_time:
        datetime_str = f"{last_inspection_date} {last_inspection_time}"
        last_inspection = datetime.strptime(datetime_str, '%Y-%m-%d %H:%M')
    elif last_inspection_date:
        # Fallback: nur Datum (setzt Uhrzeit auf 00:00)
        last_inspection = datetime.strptime(last_inspection_date, '%Y-%m-%d')
    else:
        last_inspection = datetime.now()
    
    device.last_inspection = last_inspection
    
    # ... Rest des Codes ...
""")

print("""
================================================================================
WICHTIG: Datenbank-Spalte prüfen!
================================================================================

Die Spalte 'last_inspection' muss DATETIME sein (nicht DATE):

ALTER TABLE devices MODIFY COLUMN last_inspection DATETIME;

Prüfen mit:
podman exec -it benning-mysql mysql -u miro -pmiro miro_db -e "DESCRIBE devices;" | grep last_inspection

Erwartet: last_inspection | datetime | YES | | NULL |
================================================================================
""")
