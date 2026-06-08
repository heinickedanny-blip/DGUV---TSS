#!/bin/bash

###############################################################################
# patch_app_usbc.sh
# 
# Fügt USB-C Routen zu bestehender app.py hinzu
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_FILE="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/PRG/app.py"
BACKUP_FILE="${APP_FILE}.backup"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  USB-C Routen zu app.py hinzufügen                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Prüfe ob app.py existiert
if [ ! -f "$APP_FILE" ]; then
    echo -e "${RED}✗ app.py nicht gefunden: $APP_FILE${NC}"
    exit 1
fi

# Backup erstellen
echo -e "${YELLOW}→ Erstelle Backup...${NC}"
cp "$APP_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup erstellt: $BACKUP_FILE${NC}"

# Prüfe ob USB-C Routen bereits vorhanden sind
if grep -q "usbc-inspection" "$APP_FILE"; then
    echo -e "${YELLOW}⚠ USB-C Routen bereits vorhanden${NC}"
    echo "Möchten Sie trotzdem fortfahren? (j/n)"
    read -r response
    if [[ ! "$response" =~ ^[jJ]$ ]]; then
        echo "Abgebrochen."
        exit 0
    fi
fi

# Erstelle temporäre Datei mit USB-C Routen
cat > /tmp/usbc_routes.py << 'EOFROUTES'

# ============================================================================
# USB-C KABEL-PRÜFUNG ERWEITERUNG
# ============================================================================

@app.route('/device/<device_id>/usbc-inspection', methods=['GET'])
def usbc_inspection(device_id):
    """Zeige USB-C Prüfungsformular"""
    conn = get_db_connection()
    if not conn:
        return render_template('error.html', message="Datenbankverbindung fehlgeschlagen")
    
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM devices WHERE id = %s", (device_id,))
    device = cursor.fetchone()
    
    if not device:
        cursor.close()
        conn.close()
        return "Gerät nicht gefunden", 404
    
    cursor.close()
    conn.close()
    return render_template('usbc_inspection.html', device=device)

@app.route('/device/<device_id>/usbc-inspection', methods=['POST'])
def save_usbc_inspection(device_id):
    """Speichere USB-C Prüfungsergebnisse"""
    conn = get_db_connection()
    if not conn:
        return "Datenbankverbindung fehlgeschlagen", 500
    
    cursor = conn.cursor(dictionary=True)
    
    try:
        # 1. Basis-Prüfung erstellen
        inspection_date = datetime.now().date()
        inspector_name = request.form.get('inspector_name')
        test_result = request.form.get('test_result', 'passed')
        notes = request.form.get('notes', '')
        
        cursor.execute("""
            INSERT INTO inspections (device_id, inspection_date, inspector_name, result, notes, next_inspection_date)
            VALUES (%s, %s, %s, %s, %s, DATE_ADD(%s, INTERVAL 1 YEAR))
        """, (device_id, inspection_date, inspector_name, test_result, notes, inspection_date))
        
        conn.commit()
        inspection_id = cursor.lastrowid
        
        # 2. USB-C spezifische Daten
        device_functional = 1 if request.form.get('device_functional') else 0
        battery_checked = 1 if request.form.get('battery_checked') else 0
        cable_visual_ok = 1 if request.form.get('cable_visual_ok') else 0
        cable_id = request.form.get('cable_id', device_id)
        
        cable_connected = 1 if request.form.get('cable_connected') else 0
        basic_functions_ok = 1 if request.form.get('basic_functions_ok') else 0
        
        # Protokolle als JSON
        protocols = request.form.getlist('protocols')
        protocols_json = json.dumps(protocols)
        
        resistance_test_done = 1 if request.form.get('resistance_test_done') else 0
        emarker_present = 1 if request.form.get('emarker_present') else 0
        
        # eMarker Daten als JSON
        emarker_data = None
        if emarker_present:
            emarker_data = json.dumps({
                'vendor': request.form.get('emarker_vendor', ''),
                'product': request.form.get('emarker_product', ''),
                'max_current': request.form.get('emarker_current', ''),
                'max_voltage': request.form.get('emarker_voltage', '')
            })
        
        # Foto-Upload
        pinout_photo_path = None
        if 'pinout_photo' in request.files:
            file = request.files['pinout_photo']
            if file and file.filename and allowed_file(file.filename):
                import os
                os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
                
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                filename = secure_filename(f"{device_id}_{timestamp}_{file.filename}")
                filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                
                file.save(filepath)
                pinout_photo_path = filepath
        
        all_tests_passed = (
            device_functional and battery_checked and cable_visual_ok and
            cable_connected and basic_functions_ok
        )
        
        cursor.execute("""
            INSERT INTO usbc_inspections (
                inspection_id, device_functional, battery_checked, cable_visual_ok, cable_id,
                cable_connected, basic_functions_ok, protocols_detected,
                pinout_photo_path, resistance_test_done, emarker_present, emarker_data,
                all_tests_passed, test_result, test_date, inspector_name, notes
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            inspection_id, device_functional, battery_checked, cable_visual_ok, cable_id,
            cable_connected, basic_functions_ok, protocols_json,
            pinout_photo_path, resistance_test_done, emarker_present, emarker_data,
            all_tests_passed, test_result, inspection_date, inspector_name, notes
        ))
        
        conn.commit()
        usbc_inspection_id = cursor.lastrowid
        
        # 3. Widerstandsmessungen speichern
        if resistance_test_done:
            pin_measurements = [
                ('VBUS', request.form.get('pin_vbus'), 0.0, 0.5),
                ('GND', request.form.get('pin_gnd'), 0.0, 0.3),
                ('CC1', request.form.get('pin_cc1'), 0.8, 1.2),
                ('CC2', request.form.get('pin_cc2'), 0.8, 1.2),
                ('TX1+', request.form.get('pin_tx1p'), 0.0, 0.3),
                ('TX1-', request.form.get('pin_tx1n'), 0.0, 0.3),
                ('RX1+', request.form.get('pin_rx1p'), 0.0, 0.3),
                ('RX1-', request.form.get('pin_rx1n'), 0.0, 0.3),
            ]
            
            for pin_name, value_str, min_val, max_val in pin_measurements:
                if value_str:
                    try:
                        value = float(value_str)
                        passed = min_val <= value <= max_val
                        
                        cursor.execute("""
                            INSERT INTO usbc_resistance_tests 
                            (usbc_inspection_id, pin_name, resistance_value, expected_min, expected_max, passed)
                            VALUES (%s, %s, %s, %s, %s, %s)
                        """, (usbc_inspection_id, pin_name, value, min_val, max_val, passed))
                    except ValueError:
                        pass
        
        # 4. Protokoll-Tests speichern
        protocol_details = {
            'USB 2.0': (480, False, None),
            'USB 3.2 Gen 2': (10000, False, None),
            'DisplayPort Alt Mode': (None, False, None),
            'Power Delivery 3.0': (None, True, 100),
            'Thunderbolt 4': (40000, True, 100),
        }
        
        for protocol in protocols:
            if protocol in protocol_details:
                speed, pd, power = protocol_details[protocol]
                cursor.execute("""
                    INSERT INTO usbc_protocol_tests 
                    (usbc_inspection_id, protocol_name, supported, speed_mbps, power_delivery, max_power_w)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (usbc_inspection_id, protocol, True, speed, pd, power))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return redirect(url_for('device_detail', device_id=device_id))
        
    except Exception as e:
        conn.rollback()
        cursor.close()
        conn.close()
        return f"Fehler beim Speichern: {str(e)}", 500

@app.route('/api/usbc-stats')
def usbc_stats():
    """API-Endpoint für USB-C Statistiken"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': 'Datenbankverbindung fehlgeschlagen'}), 500
    
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT COUNT(*) as count FROM devices WHERE type LIKE '%USB-C%'")
    total_devices = cursor.fetchone()['count']
    
    cursor.execute("SELECT COUNT(*) as count FROM usbc_inspections")
    total_inspections = cursor.fetchone()['count']
    
    cursor.execute("""
        SELECT test_result, COUNT(*) as count 
        FROM usbc_inspections 
        GROUP BY test_result
    """)
    results = cursor.fetchall()
    
    cursor.execute("""
        SELECT protocol_name, COUNT(*) as count 
        FROM usbc_protocol_tests 
        WHERE supported = 1
        GROUP BY protocol_name 
        ORDER BY count DESC
    """)
    protocols = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return jsonify({
        'total_devices': total_devices,
        'total_inspections': total_inspections,
        'results': results,
        'protocols': protocols
    })

EOFROUTES

# Füge USB-C Routen vor if __name__ == '__main__' ein
echo -e "${YELLOW}→ Füge USB-C Routen hinzu...${NC}"

python3 << EOFPYTHON
import sys

# Lese app.py
with open('$APP_FILE', 'r') as f:
    content = f.read()

# Lese USB-C Routen
with open('/tmp/usbc_routes.py', 'r') as f:
    usbc_routes = f.read()

# Finde Position vor if __name__
marker = "if __name__ == '__main__':"
pos = content.find(marker)

if pos == -1:
    print("✗ Marker 'if __name__' nicht gefunden")
    sys.exit(1)

# Füge USB-C Routen ein
new_content = content[:pos] + usbc_routes + '\n' + content[pos:]

# Schreibe zurück
with open('$APP_FILE', 'w') as f:
    f.write(new_content)

print("✓ USB-C Routen eingefügt")
EOFPYTHON

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ USB-C Routen erfolgreich hinzugefügt${NC}"
else
    echo -e "${RED}✗ Fehler beim Hinzufügen${NC}"
    echo -e "${YELLOW}→ Stelle Backup wieder her...${NC}"
    cp "$BACKUP_FILE" "$APP_FILE"
    exit 1
fi

# Prüfe ob Imports vorhanden sind
echo -e "${YELLOW}→ Prüfe Imports...${NC}"

if ! grep -q "import json" "$APP_FILE"; then
    echo -e "${YELLOW}  Füge 'import json' hinzu...${NC}"
    sed -i '/^import os$/a import json' "$APP_FILE"
fi

if ! grep -q "from werkzeug.utils import secure_filename" "$APP_FILE"; then
    echo -e "${YELLOW}  Füge 'from werkzeug.utils import secure_filename' hinzu...${NC}"
    sed -i '/from dotenv import load_dotenv$/a from werkzeug.utils import secure_filename' "$APP_FILE"
fi

# Prüfe ob Flask-Config vorhanden ist
if ! grep -q "UPLOAD_FOLDER" "$APP_FILE"; then
    echo -e "${YELLOW}  Füge Flask-Config hinzu...${NC}"
    sed -i "/app.config\['SECRET_KEY'\]/a app.config['UPLOAD_FOLDER'] = 'static/uploads/usbc'\napp.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024  # 10MB\n\nALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}\n\ndef allowed_file(filename):\n    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS\n" "$APP_FILE"
fi

echo -e "${GREEN}✓ Imports und Config geprüft${NC}"

# Erstelle Upload-Verzeichnis
UPLOAD_DIR="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/PRG/static/uploads/usbc"
if [ ! -d "$UPLOAD_DIR" ]; then
    echo -e "${YELLOW}→ Erstelle Upload-Verzeichnis...${NC}"
    mkdir -p "$UPLOAD_DIR"
    echo -e "${GREEN}✓ Upload-Verzeichnis erstellt${NC}"
fi

# Kopiere USB-C Template
TEMPLATE_SRC="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/usbc_inspection.html"
TEMPLATE_DST="$HOME/Dokumente/vsCode/Benning-DGUV3/Software/PRG/templates/usbc_inspection.html"

if [ -f "$TEMPLATE_SRC" ]; then
    echo -e "${YELLOW}→ Kopiere USB-C Template...${NC}"
    cp "$TEMPLATE_SRC" "$TEMPLATE_DST"
    echo -e "${GREEN}✓ Template kopiert${NC}"
else
    echo -e "${YELLOW}⚠ USB-C Template nicht gefunden: $TEMPLATE_SRC${NC}"
    echo "  Bitte kopieren Sie usbc_inspection.html manuell nach:"
    echo "  $TEMPLATE_DST"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ✓ Patch erfolgreich angewendet!                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Nächste Schritte:${NC}"
echo "1. USB-C Datenbank-Schema importieren:"
echo "   bash update_usbc.sh"
echo ""
echo "2. Flask-App neu starten:"
echo "   cd $HOME/Dokumente/vsCode/Benning-DGUV3/Software/PRG"
echo "   ./venv/bin/python app.py"
echo ""
echo "3. USB-C Prüfung testen:"
echo "   http://localhost:5000/device/USBC-001/usbc-inspection"
echo ""
echo -e "${YELLOW}Backup gespeichert unter:${NC}"
echo "   $BACKUP_FILE"
echo ""
