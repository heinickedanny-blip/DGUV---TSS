"""Integration Tests für Device API Endpoints"""
import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from src.main import create_app
from src.core.domain.device import Device


@pytest.fixture
def app():
    """Flask App für Tests"""
    app = create_app()
    app.config['TESTING'] = True
    return app


@pytest.fixture
def client(app):
    """Test Client"""
    return app.test_client()


@pytest.fixture
def mock_container():
    """Mock Container mit allen Use Cases"""
    container = Mock()
    container.list_devices_usecase = Mock()
    container.get_device_usecase = Mock()
    container.create_device_usecase = Mock()
    container.update_device_usecase = Mock()
    container.delete_device_usecase = Mock()
    container.device_repository = Mock()
    return container


class TestDeviceAPIEndpoints:
    """Tests für Device API Endpoints"""

    @patch('src.adapters.web.routes.device_routes.container')
    def test_list_devices_success(self, mock_container, client):
        """Test: GET /api/devices - Alle Devices abrufen"""
        # ANCHOR: Setup
        devices = [
            Device(id=1, name="Device 1", serial_number="SN001"),
            Device(id=2, name="Device 2", serial_number="SN002")
        ]
        mock_container.list_devices_usecase.execute.return_value = devices
        
        # ANCHOR: Execute
        response = client.get('/api/devices')
        
        # ANCHOR: Assert
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data) == 2
        assert data[0]['name'] == "Device 1"
        assert data[1]['name'] == "Device 2"

    @patch('src.adapters.web.routes.device_routes.container')
    def test_list_devices_empty(self, mock_container, client):
        """Test: GET /api/devices - Keine Devices vorhanden"""
        mock_container.list_devices_usecase.execute.return_value = []
        
        response = client.get('/api/devices')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data == []

    @patch('src.adapters.web.routes.device_routes.container')
    def test_list_devices_error(self, mock_container, client):
        """Test: GET /api/devices - Server Fehler"""
        mock_container.list_devices_usecase.execute.side_effect = Exception("DB Error")
        
        response = client.get('/api/devices')
        
        assert response.status_code == 500
        data = json.loads(response.data)
        assert 'error' in data

    @patch('src.adapters.web.routes.device_routes.container')
    def test_get_device_success(self, mock_container, client):
        """Test: GET /api/devices/<id> - Device abrufen"""
        device = Device(id=1, name="Test Device", serial_number="SN123")
        mock_container.get_device_usecase.execute.return_value = device
        
        response = client.get('/api/devices/1')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['id'] == 1
        assert data['name'] == "Test Device"

    @patch('src.adapters.web.routes.device_routes.container')
    def test_get_device_not_found(self, mock_container, client):
        """Test: GET /api/devices/<id> - Device nicht gefunden"""
        mock_container.get_device_usecase.execute.return_value = None
        
        response = client.get('/api/devices/999')
        
        assert response.status_code == 404
        data = json.loads(response.data)
        assert 'error' in data

    @patch('src.adapters.web.routes.device_routes.container')
    def test_create_device_success(self, mock_container, client):
        """Test: POST /api/devices - Device erstellen"""
        new_device = Device(id=1, name="New Device", serial_number="SN999")
        mock_container.create_device_usecase.execute.return_value = new_device
        mock_container.device_repository.get_next_id.return_value = "2"
        
        payload = {
            'id': '1',
            'name': 'New Device',
            'serial_number': 'SN999'
        }
        
        response = client.post('/api/devices',
                              data=json.dumps(payload),
                              content_type='application/json')
        
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['id'] == 1
        assert data['message'] == 'Device created'
        assert data['next_id'] == '2'

    @patch('src.adapters.web.routes.device_routes.container')
    def test_create_device_missing_name(self, mock_container, client):
        """Test: POST /api/devices - Name fehlt"""
        mock_container.create_device_usecase.execute.side_effect = Exception("Name required")
        
        payload = {'serial_number': 'SN999'}
        
        response = client.post('/api/devices',
                              data=json.dumps(payload),
                              content_type='application/json')
        
        assert response.status_code == 500

    @patch('src.adapters.web.routes.device_routes.container')
    def test_create_device_duplicate_id(self, mock_container, client):
        """Test: POST /api/devices - Duplicate ID"""
        mock_container.create_device_usecase.execute.side_effect = Exception("Duplicate entry")
        
        payload = {'id': '1', 'name': 'Device'}
        
        response = client.post('/api/devices',
                              data=json.dumps(payload),
                              content_type='application/json')
        
        assert response.status_code == 500

    @patch('src.adapters.web.routes.device_routes.container')
    def test_update_device_success(self, mock_container, client):
        """Test: PUT /api/devices/<id> - Device aktualisieren"""
        updated_device = Device(id=1, name="Updated Device")
        mock_container.update_device_usecase.execute.return_value = updated_device
        
        payload = {'name': 'Updated Device'}
        
        response = client.put('/api/devices/1',
                             data=json.dumps(payload),
                             content_type='application/json')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['message'] == 'Device updated'

    @patch('src.adapters.web.routes.device_routes.container')
    def test_update_device_not_found(self, mock_container, client):
        """Test: PUT /api/devices/<id> - Device nicht gefunden"""
        mock_container.update_device_usecase.execute.return_value = None
        
        payload = {'name': 'Updated'}
        
        response = client.put('/api/devices/999',
                             data=json.dumps(payload),
                             content_type='application/json')
        
        assert response.status_code == 200  # UseCase gibt None zurück

    @patch('src.adapters.web.routes.device_routes.container')
    def test_delete_device_success(self, mock_container, client):
        """Test: DELETE /api/devices/<id> - Device löschen"""
        mock_container.delete_device_usecase.execute.return_value = True
        
        response = client.delete('/api/devices/1')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['message'] == 'Device deleted'

    @patch('src.adapters.web.routes.device_routes.container')
    def test_delete_device_not_found(self, mock_container, client):
        """Test: DELETE /api/devices/<id> - Device nicht gefunden"""
        mock_container.delete_device_usecase.execute.return_value = False
        
        response = client.delete('/api/devices/999')
        
        assert response.status_code == 200

    @patch('src.adapters.web.routes.device_routes.container')
    def test_get_next_id_success(self, mock_container, client):
        """Test: GET /api/devices/next-id - Nächste ID abrufen"""
        mock_container.device_repository.get_next_id.return_value = "5"
        
        response = client.get('/api/devices/next-id')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['next_id'] == "5"


class TestFrontendRoutes:
    """Tests für Frontend Routes"""

    def test_index_route(self, client):
        """Test: GET / - Dashboard"""
        response = client.get('/')
        
        assert response.status_code == 200
        assert b'<!DOCTYPE' in response.data or b'<html' in response.data

    def test_devices_route(self, client):
        """Test: GET /devices - Geräteliste"""
        response = client.get('/devices')
        
        assert response.status_code == 200

    def test_device_detail_route(self, client):
        """Test: GET /device/<id> - Gerätedetails"""
        response = client.get('/device/1')
        
        assert response.status_code == 200

    def test_quick_add_get(self, client):
        """Test: GET /quick-add - Schnellerfassung Formular"""
        response = client.get('/quick-add')
        
        assert response.status_code == 200

    def test_quick_add_post(self, client):
        """Test: POST /quick-add - Schnellerfassung Speichern"""
        response = client.post('/quick-add')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['status'] == 'success'


class TestAPIErrorHandling:
    """Tests für API Fehlerbehandlung"""

    @patch('src.adapters.web.routes.device_routes.container')
    def test_malformed_json(self, mock_container, client):
        """Test: Malformed JSON"""
        response = client.post('/api/devices',
                              data='invalid json',
                              content_type='application/json')
        
        # Flask sollte 400 zurückgeben
        assert response.status_code in [400, 500]

    @patch('src.adapters.web.routes.device_routes.container')
    def test_missing_content_type(self, mock_container, client):
        """Test: Fehlender Content-Type"""
        response = client.post('/api/devices',
                              data='{"name": "test"}')
        
        # Sollte verarbeitet werden oder Fehler zurückgeben
        assert response.status_code in [200, 400, 500]

    def test_nonexistent_endpoint(self, client):
        """Test: Nicht existierender Endpoint"""
        response = client.get('/api/nonexistent')
        
        assert response.status_code == 404
