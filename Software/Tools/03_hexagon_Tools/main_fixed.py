"""Benning Device Manager - Hexagonal Architecture Edition"""
import sys
import os

# Füge das Projektverzeichnis zum Python-Pfad hinzu
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from flask import Flask
from src.config.settings import get_config
from src.config.dependencies import container
from src.adapters.web.routes.device_routes import device_bp

def create_app():
    app = Flask(__name__)
    config = get_config()
    app.config.from_object(config)
    app.register_blueprint(device_bp)

    @app.route('/health', methods=['GET'])
    def health():
        return {'status': 'ok'}, 200

    @app.route('/', methods=['GET'])
    def index():
        return {
            'name': 'Benning Device Manager',
            'version': '2.0.0',
            'architecture': 'Hexagonal',
            'status': 'running'
        }, 200

    return app

if __name__ == '__main__':
    app = create_app()
    print("🚀 Benning Device Manager startet...")
    print("📍 http://localhost:5000")
    print("🔧 Debug-Modus: aktiviert")
    print("")
    app.run(host='0.0.0.0', port=5000, debug=True)
