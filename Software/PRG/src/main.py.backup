"""Benning Device Manager - Hexagonal Architecture Edition"""
import sys
from pathlib import Path

# Füge das Projektverzeichnis zum Python-Pfad hinzu BEVOR Module importiert werden
project_root = Path(__file__).parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from flask import Flask, render_template, request, jsonify
from src.config.settings import get_config
from src.config.dependencies import container
from src.adapters.web.routes.device_routes import device_bp

def create_app():
    app = Flask(__name__, 
                template_folder=str(Path(__file__).parent.parent / 'templates'),
                static_folder=str(Path(__file__).parent.parent / 'static'))
    
    config = get_config()
    app.config.from_object(config)
    app.register_blueprint(device_bp)

    # Frontend Routes
    @app.route('/')
    def index():
        """Dashboard"""
        return render_template('index.html', 
                             total_devices=0,
                             overdue=0,
                             recent_inspections=0,
                             recent_devices=[])

    @app.route('/devices')
    def devices():
        """Geräteliste"""
        return render_template('devices.html', devices=[])

    @app.route('/device/<int:device_id>')
    def device_detail(device_id):
        """Gerätedetails"""
        return render_template('device_detail.html', device={}, inspections=[])

    @app.route('/quick-add', methods=['GET', 'POST'])
    def quick_add():
        """Schnellerfassung"""
        if request.method == 'POST':
            return jsonify({'status': 'success'})
        return render_template('quick_add.html', next_id='1')

    @app.route('/usbc-inspections')
    def usbc_inspections():
        """USB-C Inspektionen"""
        return render_template('usbc_inspections_list.html', inspections=[])

    @app.route('/usbc-inspection/<int:inspection_id>')
    def usbc_inspection_detail(inspection_id):
        """USB-C Inspektionsdetails"""
        return render_template('usbc_inspection.html', inspection={}, device={})

    # API Routes
    @app.route('/health', methods=['GET'])
    def health():
        return {'status': 'ok'}, 200

    @app.route('/api/health', methods=['GET'])
    def api_health():
        return {'status': 'ok'}, 200

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000, debug=True)
