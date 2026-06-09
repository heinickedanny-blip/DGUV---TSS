import sys
from pathlib import Path
from datetime import datetime, timedelta

# Füge das Projektverzeichnis zum Python-Pfad hinzu BEVOR Module importiert werden
project_root = Path(__file__).parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from flask import Flask, render_template, request, jsonify, url_for
from src.config.settings import get_config
from src.config.dependencies import container
from src.adapters.web.routes.device_routes import device_bp
from src.adapters.services.qr_code_generator import QRCodeGenerator
from src.core.domain.device import Device

def create_app():
    app = Flask(__name__, 
                template_folder=str(Path(__file__).parent.parent / 'templates'),
                static_folder=str(Path(__file__).parent.parent / 'static'))
    
    config = get_config()
    app.config.from_object(config)
    app.register_blueprint(device_bp)

    # ========================================================================
    # ANCHOR: DASHBOARD - INDEX
    # Hauptaufgabe: Dashboard mit Statistiken anzeigen
    # - Gesamtanzahl Geräte
    # - Überfällige Prüfungen
    # - Prüfungen in letzten 3 Monaten (optimiert)
    # - Geräte nach Status (aktiv, wartung, außer betrieb)
    # - Zuletzt hinzugefügte Geräte (Top 5)
    # - Interaktives Kreisdiagramm
    # ========================================================================
    @app.route('/')
    def index():
        """Dashboard mit Statistiken und Kreisdiagramm"""
        try:
            # Hole alle Geräte
            devices_list = container.list_devices_usecase.execute()
            
            # Berechne Statistiken
            total_devices = len(devices_list)
            
            # OPTIMIERUNG: Kombiniere alle Zählungen in einer einzigen Schleife
            # Zähle Prüfungen in letzten 3 Monaten
            overdue = 0
            recent_inspections = 0
            active_devices = 0
            maintenance_devices = 0
            retired_devices = 0
            three_months_ago = datetime.now() - timedelta(days=90)          
            for device in devices_list:
                # Zähle überfällige Prüfungen
                if device.next_inspection:
                    try:
                        next_insp = datetime.fromisoformat(str(device.next_inspection))
                        if next_insp < datetime.now():
                            overdue += 1
                    except:
                        pass
                
                # Zähle Prüfungen in letzten 3 Monaten
                if device.last_inspection:
                    try:
                        last_insp = datetime.fromisoformat(str(device.last_inspection))
                        if last_insp > three_months_ago:
                            recent_inspections += 1
                    except:
                        pass
                
                # Zähle Geräte nach Status
                if device.status == 'active':
                    active_devices += 1
                elif device.status == 'maintenance':
                    maintenance_devices += 1
                elif device.status == 'retired':
                    retired_devices += 1
            
            # Hole zuletzt hinzugefügte Geräte (sortiert nach ID)
            recent_devices = sorted(devices_list, key=lambda x: x.id, reverse=True)[:5]
            
            return render_template('index.html', 
                                 total_devices=total_devices,
                                 overdue=overdue,
                                 recent_inspections=recent_inspections,
                                 recent_devices=recent_devices,
                                 all_devices=devices_list,
                                 active_devices=active_devices,
                                 maintenance_devices=maintenance_devices,
                                 retired_devices=retired_devices)
        except Exception as e:
            print(f"Error loading dashboard: {e}")
            return render_template('index.html', 
                                 total_devices=0,
                                 overdue=0,
                                 recent_inspections=0,
                                 recent_devices=[],
                                 all_devices=[],
                                 active_devices=0,
                                 maintenance_devices=0,
                                 retired_devices=0,
                                 error=str(e))

    # ========================================================================
    # ANCHOR: GERÄTELISTE
    # Hauptaufgabe: Alle Geräte mit QR-Codes anzeigen
    # - Lade alle Geräte aus der Datenbank
    # - Generiere QR-Code für jedes Gerät
    # - Zeige in Tabellenformat mit Suchfunktion
    # ========================================================================
    @app.route('/devices')
    def devices():
        """Geräteliste mit QR-Codes und Suchfunktion"""
        try:
            # Hole alle Geräte aus der Datenbank
            devices_list = container.list_devices_usecase.execute()
            
            # Generiere QR-Codes für jedes Gerät
            for device in devices_list:
                try:
                    # Generiere QR-Code basierend auf customer_device_id
                    qr_code_data = QRCodeGenerator.generate_qr_code(
                        device_id=device.customer_device_id,
                        customer=device.customer
                    )
                    # Konvertiere zu String für HTML
                    if qr_code_data:
                        device.qr_code = f"data:image/svg+xml;base64,{qr_code_data.decode('utf-8')}"
                    else:
                        device.qr_code = None
                except Exception as e:
                    print(f"Error generating QR code for {device.customer_device_id}: {e}")
                    device.qr_code = None
            
            return render_template('devices.html', devices=devices_list)
        except Exception as e:
            print(f"Error loading devices: {e}")
            return render_template('devices.html', devices=[], error=str(e))

    # ========================================================================
    # ANCHOR: GERÄTEDETAILS
    # Hauptaufgabe: Detaillierte Informationen zu einem spezifischen Gerät
    # - Lade Gerätedaten nach ID
    # - Generiere QR-Code
    # - Zeige Inspektionshistorie
    # ========================================================================
    @app.route('/device/<int:device_id>')
    def device_detail(device_id):
        """Gerätedetails mit QR-Code und Inspektionshistorie"""
        try:
            device = container.device_repository.get_by_id(device_id)
            if device:
                # Generiere QR-Code
                qr_code_data = QRCodeGenerator.generate_qr_code(
                    device_id=device.customer_device_id,
                    customer=device.customer
                )
                if qr_code_data:
                    device.qr_code = f"data:image/svg+xml;base64,{qr_code_data.decode('utf-8')}"
                else:
                    device.qr_code = None
                
                # Hole Inspektionen (placeholder)
                inspections = []
                return render_template('device_detail.html', device=device, inspections=inspections)
            else:
                return render_template('error.html', error='Device nicht gefunden'), 404
        except Exception as e:
            return render_template('error.html', error=str(e)), 500

    # ========================================================================
    # ANCHOR: GERÄT LÖSCHEN (DELETE ENDPOINT)
    # Hauptaufgabe: Gerät und alle zugehörigen Daten löschen
    # - DELETE: Lösche Gerät und alle Inspektionsdaten
    # - Bestätigung erforderlich
    # ========================================================================
    @app.route('/device/<int:device_id>/delete', methods=['DELETE'])
    def delete_device(device_id):
        """API Endpoint zum Löschen eines Geräts mit allen zugehörigen Daten"""
        try:
            # Hole das Gerät
            device = container.device_repository.get_by_id(device_id)
            
            if not device:
                return jsonify({
                    'status': 'error',
                    'message': 'Gerät nicht gefunden'
                }), 404
            
            # Speichere Gerätename für die Antwort
            device_name = device.name
            device_id_str = device.customer_device_id
            
            # Lösche das Gerät über customer_device_id
            # Das Repository.delete() erwartet customer_device_id, nicht die numerische ID
            success = container.device_repository.delete(device_id_str)
            
            if not success:
                return jsonify({
                    'status': 'error',
                    'message': 'Gerät konnte nicht gelöscht werden'
                }), 500
            
            print(f"✓ Gerät gelöscht: {device_name} ({device_id_str})")
            
            return jsonify({
                'status': 'success',
                'message': f'Gerät {device_name} wurde erfolgreich gelöscht',
                'device_id': device_id,
                'device_name': device_name,
                'device_id_str': device_id_str
            }), 200
            
        except Exception as e:
            print(f"✗ Fehler beim Löschen des Geräts {device_id}: {e}")
            return jsonify({
                'status': 'error',
                'message': 'Fehler beim Löschen des Geräts',
                'details': str(e)
            }), 500


    # ========================================================================
    # ANCHOR: SCHNELLERFASSUNG
    # Hauptaufgabe: Schnelle Erfassung neuer Geräte
    # - GET: Zeige Erfassungsformular mit nächster ID
    # - POST: Speichere neues Gerät in Datenbank
    # - Automatische ID-Generierung nach Kundennamen
    # ========================================================================
    @app.route('/quick-add', methods=['GET', 'POST'])
    def quick_add():
        """Schnellerfassung für neue Geräte mit automatischer ID"""
        if request.method == 'POST':
            return jsonify({'status': 'success'})
        
        try:
            # Hole nächste ID für Standard-Kunden
            next_id = container.device_repository.get_next_customer_device_id('Default')
            # Generiere URL zur USB-C Inspektionen Seite
            usbc_inspections_url = url_for('usbc_inspections')
            return render_template('quick_add.html', next_id=next_id, usbc_inspections_url=usbc_inspections_url)
        except Exception as e:
            usbc_inspections_url = url_for('usbc_inspections')
            return render_template('quick_add.html', next_id='Default-00001', error=str(e), usbc_inspections_url=usbc_inspections_url)

    # ========================================================================
    # ANCHOR: GERÄT HINZUFÜGEN (API ENDPOINT) - FIXED
    # Hauptaufgabe: Neues Gerät mit optionalen USB-Inspektionsdaten speichern
    # - POST: Speichere neues Gerät und optionale USB-Inspektion
    # - Aktualisiere Gerätestatus basierend auf USB-Inspektionsergebnis
    # ========================================================================
    @app.route('/device/add', methods=['POST'])
    def add_device():
        """API Endpoint zum Hinzufügen eines neuen Geräts mit optionalen USB-Inspektionsdaten"""
        try:
            # Hole JSON Daten aus Request
            data = request.get_json()
            
            # Validiere erforderliche Felder
            required_fields = ['customer', 'name', 'type']
            if not all(field in data for field in required_fields):
                return jsonify({
                    'status': 'error',
                    'message': 'Erforderliche Felder fehlen: customer, name, type'
                }), 400
            
            # ================================================================
            # FIXME: Datenbanklogik implementiert (war vorher auskommentiert)
            # ================================================================
            
            # Bestimme Gerätestatus basierend auf USB-Inspektionsergebnis
            device_status = data.get('status', 'active')
            
            # Wenn USB-Kabel Typ und Testergebnis vorhanden
            if data.get('type') == 'USB-Kabel' and data.get('test_result'):
                if data['test_result'] == 'bestanden':
                    device_status = 'active'
                else:  # nicht_bestanden, verloren, nicht_vorhanden
                    device_status = 'maintenance'
            
            # Erstelle Device Domain Object
            device = Device(
                customer=data['customer'],
                customer_device_id=None,  # Wird vom Repository generiert
                name=data['name'],
                type=data['type'],
                location=data.get('location'),
                manufacturer=data.get('manufacturer'),
                serial_number=data.get('serial_number'),
                purchase_date=data.get('purchase_date'),
                last_inspection=data.get('last_inspection'),
                next_inspection=data.get('next_inspection'),
                status=device_status,
                notes=data.get('notes')
            )
            
            # Speichere Gerät in Datenbank
            saved_device = container.device_repository.create(device)
            
            print(f"✓ Gerät erstellt: {saved_device.name} (ID: {saved_device.customer_device_id})")
            if data.get('cable_type'):
                print(f"  USB-Inspektion: {data['cable_type']} - {data['test_result']}")
            
            # TODO: Speichere USB-Inspektionsdaten wenn vorhanden
            # if data.get('cable_type') and data.get('test_result'):
            #     inspection = container.create_inspection_usecase.execute({
            #         'device_id': saved_device.id,
            #         'cable_type': data['cable_type'],
            #         'test_result': data['test_result'],
            #         'internal_resistance': data.get('internal_resistance'),
            #         'emarker_active': data.get('emarker_active'),
            #         'notes': data.get('inspection_notes')
            #     })
            
            return jsonify({
                'status': 'success',
                'message': 'Gerät erfolgreich gespeichert',
                'device_id': saved_device.id,
                'device_name': saved_device.name,
                'customer_device_id': saved_device.customer_device_id,
                'device_status': device_status
            }), 201
            
        except Exception as e:
            print(f"✗ Fehler beim Speichern des Geräts: {e}")
            return jsonify({
                'status': 'error',
                'message': 'Fehler beim Speichern des Geräts',
                'details': str(e)
            }), 500


    # ========================================================================
    # ANCHOR: USB-C INSPEKTIONEN LISTE
    # Hauptaufgabe: Übersicht aller USB-C Kabel-Prüfungen
    # - Zeige alle durchgeführten Inspektionen
    # - Filtermöglichkeiten nach Status und Datum
    # - Link zu Inspektionsdetails
    # ========================================================================
    @app.route('/usbc-inspections')
    def usbc_inspections():
        """USB-C Inspektionen Übersicht mit Filterfunktion"""
        try:
            # Placeholder: Später mit echten Inspektionsdaten
            inspections = []
            return render_template('usbc_inspections_list.html', inspections=inspections)
        except Exception as e:
            return render_template('usbc_inspections_list.html', inspections=[], error=str(e))

    # ========================================================================
    # ANCHOR: USB-C INSPEKTIONEN FÜR SPEZIFISCHES GERÄT
    # Hauptaufgabe: Inspektionsformular für ein Gerät
    # - GET: Zeige Inspektionsformular
    # - POST: Speichere Inspektionsergebnis
    # - Verknüpfung mit Gerätedaten
    # ========================================================================
    @app.route('/device/<int:device_id>/usbc-inspection', methods=['GET', 'POST'])
    def device_usbc_inspection(device_id):
        """USB-C Inspektionsformular für ein spezifisches Gerät"""
        try:
            device = container.device_repository.get_by_id(device_id)
            if device:
                if request.method == 'POST':
                    try:
                        # Hole Inspektionsdaten aus dem Request
                        inspection_data = request.get_json()
                        
                        # Validiere erforderliche Felder
                        required_fields = ['cable_type', 'test_result']
                        if not all(field in inspection_data for field in required_fields):
                            return jsonify({
                                'status': 'error',
                                'message': 'Erforderliche Felder fehlen: cable_type, test_result'
                            }), 400
                        
                        # TODO: Speichere Inspektionsdaten
                        # inspection = container.create_inspection_usecase.execute({
                        #     'device_id': device_id,
                        #     'cable_type': inspection_data['cable_type'],
                        #     'test_result': inspection_data['test_result'],
                        #     'internal_resistance': inspection_data.get('internal_resistance'),
                        #     'emarker_active': inspection_data.get('emarker_active'),
                        #     'notes': inspection_data.get('notes')
                        # })
                        
                        # Aktualisiere Gerätestatus basierend auf Inspektionsergebnis
                        if inspection_data['test_result'] == 'bestanden':
                            device.status = 'active'
                        else:
                            device.status = 'maintenance'
                        
                        # TODO: Speichere aktualisiertes Gerät
                        # container.device_repository.update(device)
                        
                        return jsonify({
                            'status': 'success',
                            'message': 'Inspektion erfolgreich gespeichert'
                        }), 201
                    except Exception as e:
                        return jsonify({
                            'status': 'error',
                            'message': 'Fehler beim Speichern der Inspektion',
                            'details': str(e)
                        }), 500
                else:
                    # GET: Zeige Inspektionsformular
                    return render_template('usbc_inspection.html', device=device)
            else:
                return render_template('error.html', error='Device nicht gefunden'), 404
        except Exception as e:
            return render_template('error.html', error=str(e)), 500
    # ========================================================================
    # ANCHOR: SCHUTZKLASSEN-INFORMATIONEN
    # Hauptaufgabe: Informationen zu Schutzklassen-Prüfungen anzeigen
    # - Zusammenfassung der Prüfverfahren
    # - Informationen zu Schutzklasse 1, 2 und 3
    # - Prüfung von dreiphasigen Geräten
    # - Prüfung von Kabeln und Mehrfachsteckdosen
    # - Prüfung von FI-Schutzschaltern
    # ========================================================================
    @app.route('/schutzklasse')
    def schutzklasse():
        """Informationsseite zu Schutzklassen-Prüfungen"""
        try:
            return render_template('schutzklasse.html')
        except Exception as e:
            print(f"Error loading schutzklasse page: {e}")
            return render_template('schutzklasse.html', error=str(e))

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)
