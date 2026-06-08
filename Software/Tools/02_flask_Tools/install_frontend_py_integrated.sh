#!/bin/bash

###############################################################################
# install_frontend_py.sh v2.0
# 
# Installiert Benning Device Manager Flask-Anwendung mit USB-C Erweiterung
# Zielverzeichnis: ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
###############################################################################

set -e  # Bei Fehler abbrechen

# Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Konfiguration
BASE_DIR="$HOME/Dokumente/vsCode/Benning-DGUV3/Software"
INSTALL_DIR="$BASE_DIR/PRG"
PYTHON_MIN_VERSION="3.8"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Benning Device Manager - Flask Installation v2.0         ║${NC}"
echo -e "${BLUE}║  + USB-C Kabel-Prüfung Erweiterung                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Prüfe Python-Installation
echo -e "${YELLOW}→ Prüfe Python-Installation...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python3 nicht gefunden!${NC}"
    echo "Bitte installieren Sie Python3:"
    echo "  sudo apt install python3 python3-pip python3-venv"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo -e "${GREEN}✓ Python ${PYTHON_VERSION} gefunden${NC}"

# Erstelle Verzeichnisstruktur
echo -e "${YELLOW}→ Erstelle Verzeichnisstruktur...${NC}"
mkdir -p "$INSTALL_DIR"/{static/css,static/js,static/uploads/usbc,templates}

# Erstelle Virtual Environment
echo -e "${YELLOW}→ Erstelle Virtual Environment...${NC}"
cd "$INSTALL_DIR"
python3 -m venv venv
source venv/bin/activate

# Installiere Dependencies
echo -e "${YELLOW}→ Installiere Python-Pakete...${NC}"
cat > requirements.txt << 'EOF'
Flask==3.0.0
mysql-connector-python==8.2.0
qrcode[pil]==7.4.2
reportlab==4.0.7
python-dotenv==1.0.0
Werkzeug==3.0.1
EOF

pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt

echo -e "${GREEN}✓ Pakete installiert${NC}"

# Erstelle app.py
echo -e "${YELLOW}→ Erstelle app.py...${NC}"
cat > app.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Benning Device Manager - Flask Application
Leichtgewichtige Web-Anwendung für Geräte-Management und DGUV3-Prüfungen
"""

from flask import Flask, render_template, request, jsonify, send_file, redirect, url_for
import mysql.connector
from mysql.connector import Error
import os
import json
from datetime import datetime, timedelta
import qrcode
from io import BytesIO
from dotenv import load_dotenv
from werkzeug.utils import secure_filename

# Lade Umgebungsvariablen
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['UPLOAD_FOLDER'] = 'static/uploads/usbc'
app.config['MAX_CONTENT_LENGTH'] = 10 * 1024 * 1024  # 10MB max

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Datenbank-Konfiguration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 3307)),
    'user': os.getenv('DB_USER', 'benning'),
    'password': os.getenv('DB_PASSWORD', 'benning'),
    'database': os.getenv('DB_NAME', 'benning_device_manager'),
    'charset': 'utf8mb4',
    'collation': 'utf8mb4_unicode_ci'
}

def get_db_connection():
    """Erstellt Datenbankverbindung"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        print(f"Datenbankfehler: {e}")
        return None

def get_next_device_id():
    """Generiert nächste Geräte-ID im Format BENNING-XXX"""
    conn = get_db_connection()
    if not conn:
        return "BENNING-001"
    
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM devices WHERE id LIKE 'BENNING-%' ORDER BY id DESC LIMIT 1")
        result = cursor.fetchone()
        
        if result:
            last_id = result[0]
            number = int(last_id.split('-')[1]) + 1
            return f"BENNING-{number:03d}"
        else:
            return "BENNING-001"
    except Error as e:
        print(f"Fehler bei ID-Generierung: {e}")
        return "BENNING-001"
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()

@app.route('/')
def index():
    """Dashboard mit Statistiken"""
    conn = get_db_connection()
    if not conn:
        return render_template('error.html', message="Datenbankverbindung fehlgeschlagen")
    
    try:
        cursor = conn.cursor(dictionary=True)
        
        # Statistiken abrufen
        cursor.execute("SELECT COUNT(*) as total FROM devices WHERE status = 'active'")
        total_devices = cursor.fetchone()['total']
        
        cursor.execute("SELECT COUNT(*) as total FROM devices WHERE next_inspection < CURDATE() AND status = 'active'")
        overdue = cursor.fetchone()['total']
        
        cursor.execute("SELECT COUNT(*) as total FROM inspections WHERE inspection_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)")
        recent_inspections = cursor.fetchone()['total']
        
        # Letzte Geräte
        cursor.execute("""
            SELECT id, name, type, location, status, next_inspection 
            FROM devices 
            ORDER BY created_at DESC 
            LIMIT 5
        """)
        recent_devices = cursor.fetchall()
        
        return render_template('index.html',
                             total_devices=total_devices,
                             overdue=overdue,
                             recent_inspections=recent_inspections,
                             recent_devices=recent_devices)
    except Error as e:
        return render_template('error.html', message=f"Datenbankfehler: {e}")
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()

@app.route('/devices')
def devices():
    """Geräteliste"""
    conn = get_db_connection()
    if not conn:
        return render_template('error.html', message="Datenbankverbindung fehlgeschlagen")
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, name, type, location, manufacturer, serial_number, 
                   last_inspection, next_inspection, status 
            FROM devices 
            ORDER BY id
        """)
        devices = cursor.fetchall()
        
        return render_template('devices.html', devices=devices)
    except Error as e:
        return render_template('error.html', message=f"Datenbankfehler: {e}")
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()

@app.route('/quick-add')
def quick_add():
    """Schnellerfassung"""
    next_id = get_next_device_id()
    return render_template('quick_add.html', next_id=next_id)

@app.route('/api/devices', methods=['POST'])
def add_device():
    """Gerät hinzufügen"""
    data = request.json
    conn = get_db_connection()
    
    if not conn:
        return jsonify({'success': False, 'error': 'Datenbankverbindung fehlgeschlagen'}), 500
    
    try:
        cursor = conn.cursor()
        
        # Berechne next_inspection (12 Monate ab heute)
        next_inspection = (datetime.now() + timedelta(days=365)).strftime('%Y-%m-%d')
        
        cursor.execute("""
            INSERT INTO devices 
            (id, name, type, location, manufacturer, serial_number, 
             purchase_date, last_inspection, next_inspection, status, notes)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            data.get('id'),
            data.get('name'),
            data.get('type'),
            data.get('location'),
            data.get('manufacturer'),
            data.get('serial_number'),
            data.get('purchase_date'),
            datetime.now().strftime('%Y-%m-%d'),
            next_inspection,
            'active',
            data.get('notes', '')
        ))
        
        conn.commit()
        
        # Nächste ID generieren
        next_id = get_next_device_id()
        
        return jsonify({'success': True, 'next_id': next_id})
    except Error as e:
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()

@app.route('/device/<device_id>')
def device_detail(device_id):
    """Gerätedetails"""
    conn = get_db_connection()
    if not conn:
        return render_template('error.html', message="Datenbankverbindung fehlgeschlagen")
    
    try:
        cursor = conn.cursor(dictionary=True)
        
        # Gerät abrufen
        cursor.execute("SELECT * FROM devices WHERE id = %s", (device_id,))
        device = cursor.fetchone()
        
        if not device:
            return render_template('error.html', message="Gerät nicht gefunden"), 404
        
        # Prüfungen abrufen
        cursor.execute("""
            SELECT * FROM inspections 
            WHERE device_id = %s 
            ORDER BY inspection_date DESC
        """, (device_id,))
        inspections = cursor.fetchall()
        
        return render_template('device_detail.html', device=device, inspections=inspections)
    except Error as e:
        return render_template('error.html', message=f"Datenbankfehler: {e}")
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()

@app.route('/qr/<device_id>')
def generate_qr(device_id):
    """QR-Code generieren"""
    # URL zum Gerät
    device_url = request.host_url + f'device/{device_id}'
    
    # QR-Code erstellen
    qr = qrcode.QRCode(version=1, box_size=10, border=4)
    qr.add_data(device_url)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    
    # In BytesIO speichern
    img_io = BytesIO()
    img.save(img_io, 'PNG')
    img_io.seek(0)
    
    return send_file(img_io, mimetype='image/png')

@app.route('/health')
def health():
    """Health-Check Endpoint"""
    conn = get_db_connection()
    if conn:
        conn.close()
        return jsonify({'status': 'healthy', 'database': 'connected'})
    else:
        return jsonify({'status': 'unhealthy', 'database': 'disconnected'}), 503


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

@app.route('/usbc-inspections')
def usbc_inspections_list():
    """Liste aller USB-C Prüfungen"""
    conn = get_db_connection()
    if not conn:
        return render_template('error.html', message="Datenbankverbindung fehlgeschlagen")
    
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("""
        SELECT 
            u.id,
            u.test_date,
            u.inspector_name,
            u.test_result,
            u.all_tests_passed,
            d.id as device_id,
            d.name as device_name,
            COUNT(DISTINCT r.id) as resistance_count,
            COUNT(DISTINCT p.id) as protocol_count
        FROM usbc_inspections u
        JOIN inspections i ON u.inspection_id = i.id
        JOIN devices d ON i.device_id = d.id
        LEFT JOIN usbc_resistance_tests r ON u.id = r.usbc_inspection_id
        LEFT JOIN usbc_protocol_tests p ON u.id = p.usbc_inspection_id
        GROUP BY u.id
        ORDER BY u.test_date DESC
    """)
    
    inspections = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return render_template('usbc_inspections_list.html', inspections=inspections)

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


if __name__ == '__main__':
    print("\n" + "="*60)
    print("🚀 Benning Device Manager läuft auf http://0.0.0.0:5000")
    print("   + USB-C Kabel-Prüfung aktiviert 🔌")
    print("="*60 + "\n")
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

chmod +x app.py

# Erstelle Templates
echo -e "${YELLOW}→ Erstelle Templates...${NC}"

# base.html
cat > templates/base.html << 'EOF'
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Benning Device Manager{% endblock %}</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <nav class="navbar">
        <div class="nav-brand">
            <h1>🔧 Benning Device Manager</h1>
        </div>
        <ul class="nav-menu">
            <li><a href="{{ url_for('index') }}">Dashboard</a></li>
            <li><a href="{{ url_for('quick_add') }}">Schnellerfassung</a></li>
            <li><a href="{{ url_for('devices') }}">Geräteliste</a></li>
        </ul>
    </nav>
    
    <main class="container">
        {% block content %}{% endblock %}
    </main>
    
    <footer>
        <p>&copy; 2024 Benning Device Manager | DGUV3-konform</p>
    </footer>
    
    {% block scripts %}{% endblock %}
</body>
</html>
EOF

# index.html
cat > templates/index.html << 'EOF'
{% extends "base.html" %}

{% block title %}Dashboard - Benning Device Manager{% endblock %}

{% block content %}
<div class="dashboard">
    <h2>📊 Dashboard</h2>
    
    <div class="stats-grid">
        <div class="stat-card">
            <h3>{{ total_devices }}</h3>
            <p>Aktive Geräte</p>
        </div>
        <div class="stat-card warning">
            <h3>{{ overdue }}</h3>
            <p>Überfällige Prüfungen</p>
        </div>
        <div class="stat-card">
            <h3>{{ recent_inspections }}</h3>
            <p>Prüfungen (30 Tage)</p>
        </div>
    </div>
    
    <div class="recent-section">
        <h3>📋 Zuletzt hinzugefügt</h3>
        <table class="device-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Typ</th>
                    <th>Standort</th>
                    <th>Nächste Prüfung</th>
                </tr>
            </thead>
            <tbody>
                {% for device in recent_devices %}
                <tr>
                    <td><a href="{{ url_for('device_detail', device_id=device.id) }}">{{ device.id }}</a></td>
                    <td>{{ device.name }}</td>
                    <td>{{ device.type }}</td>
                    <td>{{ device.location }}</td>
                    <td>{{ device.next_inspection }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
    </div>
</div>
{% endblock %}
EOF

# quick_add.html
cat > templates/quick_add.html << 'EOF'
{% extends "base.html" %}

{% block title %}Schnellerfassung - Benning Device Manager{% endblock %}

{% block content %}
<div class="quick-add">
    <h2>⚡ Schnellerfassung</h2>
    
    <form id="quickAddForm">
        <div class="form-group">
            <label>Geräte-ID:</label>
            <input type="text" id="deviceId" name="id" value="{{ next_id }}" readonly>
        </div>
        
        <div class="form-group">
            <label>Gerätename: *</label>
            <input type="text" name="name" required autofocus>
        </div>
        
        <div class="form-group">
            <label>Typ:</label>
            <select name="type">
                <option value="Elektrowerkzeug">Elektrowerkzeug</option>
                <option value="Kabel">Kabel</option>
                <option value="Verlängerung">Verlängerung</option>
                <option value="Reinigungsgerät">Reinigungsgerät</option>
                <option value="Sonstiges">Sonstiges</option>
            </select>
        </div>
        
        <div class="form-group">
            <label>Standort:</label>
            <input type="text" name="location">
        </div>
        
        <div class="form-group">
            <label>Hersteller:</label>
            <input type="text" name="manufacturer">
        </div>
        
        <div class="form-group">
            <label>Seriennummer:</label>
            <input type="text" name="serial_number">
        </div>
        
        <div class="form-group">
            <label>Kaufdatum:</label>
            <input type="date" name="purchase_date">
        </div>
        
        <div class="form-group">
            <label>Notizen:</label>
            <textarea name="notes" rows="3"></textarea>
        </div>
        
        <div class="button-group">
            <button type="submit" class="btn-primary">💾 Speichern & Weiter</button>
            <button type="button" onclick="location.href='{{ url_for('devices') }}'" class="btn-secondary">📋 Zur Liste</button>
        </div>
    </form>
    
    <div id="message" class="message"></div>
</div>
{% endblock %}

{% block scripts %}
<script>
document.getElementById('quickAddForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = Object.fromEntries(formData.entries());
    
    try {
        const response = await fetch('/api/devices', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(data)
        });
        
        const result = await response.json();
        
        if (result.success) {
            document.getElementById('message').innerHTML = '✅ Gerät erfolgreich gespeichert!';
            document.getElementById('message').className = 'message success';
            
            // Formular zurücksetzen und neue ID setzen
            e.target.reset();
            document.getElementById('deviceId').value = result.next_id;
            
            // Fokus auf Name-Feld
            document.querySelector('input[name="name"]').focus();
            
            setTimeout(() => {
                document.getElementById('message').innerHTML = '';
            }, 3000);
        } else {
            throw new Error(result.error);
        }
    } catch (error) {
        document.getElementById('message').innerHTML = '❌ Fehler: ' + error.message;
        document.getElementById('message').className = 'message error';
    }
});
</script>
{% endblock %}
EOF

# devices.html
cat > templates/devices.html << 'EOF'
{% extends "base.html" %}

{% block title %}Geräteliste - Benning Device Manager{% endblock %}

{% block content %}
<div class="devices-list">
    <h2>📋 Geräteliste</h2>
    
    <div class="toolbar">
        <button onclick="location.href='{{ url_for('quick_add') }}'" class="btn-primary">➕ Neues Gerät</button>
    </div>
    
    <table class="device-table">
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Typ</th>
                <th>Standort</th>
                <th>Hersteller</th>
                <th>Letzte Prüfung</th>
                <th>Nächste Prüfung</th>
                <th>Status</th>
                <th>Aktionen</th>
            </tr>
        </thead>
        <tbody>
            {% for device in devices %}
            <tr>
                <td><strong>{{ device.id }}</strong></td>
                <td>{{ device.name }}</td>
                <td>{{ device.type }}</td>
                <td>{{ device.location }}</td>
                <td>{{ device.manufacturer }}</td>
                <td>{{ device.last_inspection }}</td>
                <td>{{ device.next_inspection }}</td>
                <td><span class="badge badge-{{ device.status }}">{{ device.status }}</span></td>
                <td>
                    <a href="{{ url_for('device_detail', device_id=device.id) }}" class="btn-small">Details</a>
                    <a href="{{ url_for('generate_qr', device_id=device.id) }}" class="btn-small" target="_blank">QR</a>
                </td>
            </tr>
            {% endfor %}
        </tbody>
    </table>
</div>
{% endblock %}
EOF

# device_detail.html
cat > templates/device_detail.html << 'EOF'
{% extends "base.html" %}

{% block title %}{{ device.name }} - Benning Device Manager{% endblock %}

{% block content %}
<div class="device-detail">
    <div class="detail-header">
        <h2>🔧 {{ device.name }}</h2>
        <span class="badge badge-{{ device.status }}">{{ device.status }}</span>
    </div>
    
    <div class="detail-grid">
        <div class="detail-card">
            <h3>Geräteinformationen</h3>
            <dl>
                <dt>ID:</dt><dd>{{ device.id }}</dd>
                <dt>Typ:</dt><dd>{{ device.type }}</dd>
                <dt>Standort:</dt><dd>{{ device.location }}</dd>
                <dt>Hersteller:</dt><dd>{{ device.manufacturer }}</dd>
                <dt>Seriennummer:</dt><dd>{{ device.serial_number }}</dd>
                <dt>Kaufdatum:</dt><dd>{{ device.purchase_date }}</dd>
            </dl>
        </div>
        
        <div class="detail-card">
            <h3>Prüfstatus</h3>
            <dl>
                <dt>Letzte Prüfung:</dt><dd>{{ device.last_inspection }}</dd>
                <dt>Nächste Prüfung:</dt><dd>{{ device.next_inspection }}</dd>
                <dt>Status:</dt><dd>{{ device.status }}</dd>
            </dl>
            <div class="qr-section">
                <img src="{{ url_for('generate_qr', device_id=device.id) }}" alt="QR Code" style="width: 150px;">
            </div>
        </div>
    </div>
    
    <div class="inspections-section">
        <h3>📝 Prüfhistorie</h3>
        {% if inspections %}
        <table class="device-table">
            <thead>
                <tr>
                    <th>Datum</th>
                    <th>Prüfer</th>
                    <th>Ergebnis</th>
                    <th>Notizen</th>
                </tr>
            </thead>
            <tbody>
                {% for inspection in inspections %}
                <tr>
                    <td>{{ inspection.inspection_date }}</td>
                    <td>{{ inspection.inspector_name }}</td>
                    <td><span class="badge badge-{{ inspection.result }}">{{ inspection.result }}</span></td>
                    <td>{{ inspection.notes }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
        {% else %}
        <p>Keine Prüfungen vorhanden.</p>
        {% endif %}
    </div>
    
    <div class="button-group">
        <button onclick="history.back()" class="btn-secondary">← Zurück</button>
    </div>
</div>
{% endblock %}
EOF

# error.html
cat > templates/error.html << 'EOF'
{% extends "base.html" %}

{% block title %}Fehler - Benning Device Manager{% endblock %}

{% block content %}
<div class="error-page">
    <h2>❌ Fehler</h2>
    <p>{{ message }}</p>
    <button onclick="history.back()" class="btn-primary">← Zurück</button>
</div>
{% endblock %}
EOF

# Erstelle CSS
echo -e "${YELLOW}→ Erstelle Stylesheet...${NC}"
cat > static/css/style.css << 'EOF'
/* Benning Device Manager - Dark Rose-Gold Theme */

:root {
    --bg-primary: #1a1625;
    --bg-secondary: #251d32;
    --bg-card: rgba(255, 255, 255, 0.05);
    --text-primary: #e8d4d0;
    --text-secondary: #b8a8a4;
    --accent-rose: #d4a5a5;
    --accent-gold: #d4af37;
    --gradient-primary: linear-gradient(135deg, #d4a5a5 0%, #d4af37 100%);
    --shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    --border-radius: 12px;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: var(--bg-primary);
    color: var(--text-primary);
    line-height: 1.6;
    min-height: 100vh;
}

/* Navigation */
.navbar {
    background: var(--bg-secondary);
    padding: 1rem 2rem;
    box-shadow: var(--shadow);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.nav-brand h1 {
    background: var(--gradient-primary);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    font-size: 1.5rem;
}

.nav-menu {
    display: flex;
    list-style: none;
    gap: 2rem;
}

.nav-menu a {
    color: var(--text-primary);
    text-decoration: none;
    transition: color 0.3s;
}

.nav-menu a:hover {
    color: var(--accent-rose);
}

/* Container */
.container {
    max-width: 1400px;
    margin: 2rem auto;
    padding: 0 2rem;
}

/* Cards */
.stat-card, .detail-card {
    background: var(--bg-card);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(212, 165, 165, 0.2);
    border-radius: var(--border-radius);
    padding: 2rem;
    box-shadow: var(--shadow);
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
}

.stat-card h3 {
    font-size: 3rem;
    background: var(--gradient-primary);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}

.stat-card.warning h3 {
    color: #ff6b6b;
}

/* Tables */
.device-table {
    width: 100%;
    background: var(--bg-card);
    backdrop-filter: blur(10px);
    border-radius: var(--border-radius);
    overflow: hidden;
    box-shadow: var(--shadow);
}

.device-table thead {
    background: var(--gradient-primary);
}

.device-table th {
    padding: 1rem;
    text-align: left;
    color: var(--bg-primary);
    font-weight: 600;
}

.device-table td {
    padding: 1rem;
    border-bottom: 1px solid rgba(212, 165, 165, 0.1);
}

.device-table tbody tr:hover {
    background: rgba(212, 165, 165, 0.1);
}

/* Forms */
.form-group {
    margin-bottom: 1.5rem;
}

.form-group label {
    display: block;
    margin-bottom: 0.5rem;
    color: var(--accent-rose);
    font-weight: 500;
}

.form-group input,
.form-group select,
.form-group textarea {
    width: 100%;
    padding: 0.75rem;
    background: var(--bg-card);
    border: 1px solid rgba(212, 165, 165, 0.3);
    border-radius: 8px;
    color: var(--text-primary);
    font-size: 1rem;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
    outline: none;
    border-color: var(--accent-rose);
    box-shadow: 0 0 0 3px rgba(212, 165, 165, 0.1);
}

/* Buttons */
.btn-primary, .btn-secondary, .btn-small {
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 8px;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.3s;
    text-decoration: none;
    display: inline-block;
}

.btn-primary {
    background: var(--gradient-primary);
    color: var(--bg-primary);
    font-weight: 600;
}

.btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(212, 165, 165, 0.4);
}

.btn-secondary {
    background: var(--bg-secondary);
    color: var(--text-primary);
    border: 1px solid var(--accent-rose);
}

.btn-small {
    padding: 0.5rem 1rem;
    font-size: 0.875rem;
    background: var(--bg-secondary);
    color: var(--text-primary);
}

.button-group {
    display: flex;
    gap: 1rem;
    margin-top: 2rem;
}

/* Badges */
.badge {
    padding: 0.25rem 0.75rem;
    border-radius: 20px;
    font-size: 0.875rem;
    font-weight: 500;
}

.badge-active {
    background: rgba(76, 175, 80, 0.2);
    color: #4caf50;
}

.badge-passed {
    background: rgba(76, 175, 80, 0.2);
    color: #4caf50;
}

.badge-failed {
    background: rgba(244, 67, 54, 0.2);
    color: #f44336;
}

/* Messages */
.message {
    padding: 1rem;
    border-radius: 8px;
    margin-top: 1rem;
}

.message.success {
    background: rgba(76, 175, 80, 0.2);
    color: #4caf50;
    border: 1px solid #4caf50;
}

.message.error {
    background: rgba(244, 67, 54, 0.2);
    color: #f44336;
    border: 1px solid #f44336;
}

/* Footer */
footer {
    text-align: center;
    padding: 2rem;
    color: var(--text-secondary);
    margin-top: 4rem;
}

/* Detail Grid */
.detail-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 2rem;
    margin: 2rem 0;
}

.detail-card dl {
    display: grid;
    grid-template-columns: 140px 1fr;
    gap: 0.5rem;
}

.detail-card dt {
    color: var(--accent-rose);
    font-weight: 500;
}

.detail-card dd {
    color: var(--text-primary);
}

/* QR Section */
.qr-section {
    margin-top: 1rem;
    text-align: center;
}

.qr-section img {
    border: 2px solid var(--accent-rose);
    border-radius: 8px;
    padding: 0.5rem;
    background: white;
}

/* Toolbar */
.toolbar {
    margin-bottom: 1.5rem;
}

/* Responsive */
@media (max-width: 768px) {
    .navbar {
        flex-direction: column;
        gap: 1rem;
    }
    
    .nav-menu {
        flex-direction: column;
        gap: 0.5rem;
        text-align: center;
    }
    
    .container {
        padding: 0 1rem;
    }
    
    .device-table {
        font-size: 0.875rem;
    }
    
    .device-table th,
    .device-table td {
        padding: 0.5rem;
    }
}
EOF

# Erstelle .env
echo -e "${YELLOW}→ Erstelle .env-Datei...${NC}"
cat > .env << EOF
# Benning Flask - Konfiguration
DB_HOST=localhost
DB_PORT=3307
DB_USER=benning
DB_PASSWORD=benning
DB_NAME=benning_device_manager

FLASK_ENV=development
FLASK_DEBUG=1
SECRET_KEY=$(openssl rand -hex 32 2>/dev/null || echo "change-this-secret-key-in-production")
EOF

# Erstelle .gitignore
cat > .gitignore << 'EOF'
venv/
__pycache__/
*.pyc
.env
*.db
*.log
.DS_Store
EOF

# Erstelle README
cat > README.md << 'EOF'
# Benning Device Manager - Flask Edition

Leichtgewichtige Web-Anwendung für Geräte-Management und DGUV3-Prüfungen.

## Features

- ✅ Dashboard mit Statistiken
- ✅ Schnellerfassung für neue Geräte
- ✅ Geräteliste mit Details
- ✅ QR-Code-Generierung
- ✅ Dark Rose-Gold Theme
- ✅ MySQL-Datenbank

## Installation

```bash
cd ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG
source venv/bin/activate  # oder venv/bin/activate.fish für Fish Shell
python app.py
```

## Datenbank

Verwenden Sie `install_py_db.sh` zur Einrichtung der MySQL-Datenbank.

## Technologie

- Python 3.8+
- Flask 3.0
- MySQL 8.0
- QRCode
- ReportLab

## Dateien

- `app.py` - Haupt-Anwendung
- `templates/` - HTML-Templates
- `static/css/` - Stylesheets
- `.env` - Konfiguration (nicht in Git)

## Lizenz

Proprietär - Benning Device Manager
EOF

deactivate 2>/dev/null || true

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ Installation erfolgreich abgeschlossen!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Installationsverzeichnis:${NC}"
echo "  $INSTALL_DIR"
echo ""
echo -e "${BLUE}Dateien erstellt:${NC}"
echo "  ✓ app.py (Haupt-Anwendung)"
echo "  ✓ 5 HTML-Templates"
echo "  ✓ CSS-Stylesheet (Dark Rose-Gold)"
echo "  ✓ requirements.txt"
echo "  ✓ .env (Konfiguration)"
echo "  ✓ README.md"
echo ""
echo -e "${BLUE}Nächste Schritte:${NC}"
echo ""
echo "1. Datenbank einrichten:"
echo "   cd ~/Dokumente/vsCode/Benning-DGUV3"
echo "   bash install_py_db.sh"
echo ""
echo "2. Flask-App starten:"
echo "   cd $INSTALL_DIR"
echo "   source venv/bin/activate.fish  # für Fish Shell"
echo "   # ODER"
echo "   ./venv/bin/python app.py       # direkt ohne Aktivierung"
echo ""
echo "3. Browser öffnen:"
echo "   http://localhost:5000"
echo ""
echo -e "${GREEN}Viel Erfolg! 🚀${NC}"
