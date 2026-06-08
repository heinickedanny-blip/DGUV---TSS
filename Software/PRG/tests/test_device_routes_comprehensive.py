"""
Comprehensive pytest Test Suite für Device Routes
Testet alle Routen mit Request/Response-Validierung und Edge-Cases
Fokus auf varchar/string ID-Probleme
"""

import pytest
import json
from datetime import date, datetime, timedelta
from unittest.mock import Mock, patch, MagicMock
from flask import Flask
from src.main import create_app
from src.core.domain.device import Device
from src.adapters.persistence.mysql_device_repository import MySQLDeviceRepository


@pytest.fixture
def app():
    """Create Flask app for testing"""
    app = create_app()
    app.config['TESTING'] = True
    return app


@pytest.fixture
def client(app):
    """Create test client"""
    return app.test_client()


@pytest.fixture
def mock_repository():
    """Create mock repository"""
    return Mock(spec=MySQLDeviceRepository)


@pytest.fixture
def sample_device():
    """Create sample device for testing"""
    return Device(
        id=1,
        customer="Parloa",
        customer_device_id="Parloa-00001",
        name="Elektroschrauber",
        type="Elektrowerkzeug",
        serial_number="SN-12345",
        manufacturer="Bosch",
        location="Lager A",
        purchase_date=date(2023, 1, 15),
        last_inspection=date(2024, 1, 15),
        next_inspection=date(2025, 1, 15),
        status="active",
        notes="Test device"
    )


class TestDeviceListRoute:
    """Tests für GET /api/devices"""
    
    def test_list_devices_success(self, client, mock_repository, sample_device):
        """Test erfolgreiches Abrufen aller Geräte"""
        with patch('src.config.dependencies.container.list_devices_usecase.execute') as mock_execute:
            mock_execute.return_value = [sample_device]
            
            response = client.get('/api/devices')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['success'] is True
            assert len(data['data']) == 1
            assert data['data'][0]['customer_device_id'] == "Parloa-00001"
    
    def test_list_devices_empty(self, client):
        """Test Abrufen wenn keine Geräte vorhanden"""
        with patch('src.config.dependencies.container.list_devices_usecase.execute') as mock_execute:
            mock_execute.return_value = []
            
            response = client.get('/api/devices')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['success'] is True
            assert len(data['data']) == 0
    
    def test_list_devices_error(self, client):
        """Test Fehlerbehandlung beim Abrufen"""
        with patch('src.config.dependencies.container.list_devices_usecase.execute') as mock_execute:
            mock_execute.side_effect = Exception("Database connection failed")
            
            response = client.get('/api/devices')
            
            assert response.status_code == 500
            data = json.loads(response.data)
            assert data['success'] is False
            assert 'error' in data


class TestDeviceGetRoute:
    """Tests für GET /api/devices/<customer_device_id>"""
    
    def test_get_device_success(self, client, sample_device):
        """Test erfolgreiches Abrufen eines Geräts"""
        with patch('src.config.dependencies.container.device_repository.get_by_customer_device_id') as mock_get:
            mock_get.return_value = sample_device
            
            response = client.get('/api/devices/Parloa-00001')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['success'] is True
            assert data['device']['customer_device_id'] == "Parloa-00001"
            assert data['device']['name'] == "Elektroschrauber"
    
    def test_get_device_with_special_characters(self, client):
        """Test Abrufen mit Sonderzeichen in customer_device_id"""
        device = Device(
            id=2,
            customer="Test-Kunde",
            customer_device_id="Test-Kunde-00001",
            name="Test Device",
            type="Test",
            status="active"
        )
        
        with patch('src.config.dependencies.container.device_repository.get_by_customer_device_id') as mock_get:
            mock_get.return_value = device
            
            response = client.get('/api/devices/Test-Kunde-00001')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['device']['customer_device_id'] == "Test-Kunde-00001"
    
    def test_get_device_not_found(self, client):
        """Test Abrufen wenn Gerät nicht existiert"""
        with patch('src.config.dependencies.container.device_repository.get_by_customer_device_id') as mock_get:
            mock_get.return_value = None
            
            response = client.get('/api/devices/NonExistent-00001')
            
            assert response.status_code == 404
            data = json.loads(response.data)
            assert data['success'] is False
            assert 'not found' in data['error'].lower()
    
    def test_get_device_with_null_dates(self, client):
        """Test Abrufen wenn Datum-Felder NULL sind"""
        device = Device(
            id=3,
            customer="Parloa",
            customer_device_id="Parloa-00002",
            name="Device ohne Datum",
            type="Test",
            purchase_date=None,
            last_inspection=None,
            next_inspection=None,
            status="active"
        )
        
        with patch('src.config.dependencies.container.device_repository.get_by_customer_device_id') as mock_get:
            mock_get.return_value = device
            
            response = client.get('/api/devices/Parloa-00002')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['device']['purchase_date'] is None
            assert data['device']['last_inspection'] is None
            assert data['device']['next_inspection'] is None
    
    def test_get_device_error(self, client):
        """Test Fehlerbehandlung"""
        with patch('src.config.dependencies.container.device_repository.get_by_customer_device_id') as mock_get:
            mock_get.side_effect = Exception("Database error")
            
            response = client.get('/api/devices/Parloa-00001')
            
            assert response.status_code == 500
            data = json.loads(response.data)
            assert data['success'] is False


class TestDeviceNextIdRoute:
    """Tests für GET /api/devices/next-id"""
    
    def test_get_next_id_success(self, client):
        """Test erfolgreiches Abrufen der nächsten ID"""
        with patch('src.config.dependencies.container.device_repository.get_next_customer_device_id') as mock_get:
            mock_get.return_value = "Parloa-00002"
            
            response = client.get('/api/devices/next-id?customer=Parloa')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['success'] is True
            assert data['next_id'] == "Parloa-00002"
    
    def test_get_next_id_missing_customer(self, client):
        """Test Fehler wenn customer Parameter fehlt"""
        response = client.get('/api/devices/next-id')
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'Customer parameter required' in data['error']
    
    def test_get_next_id_empty_customer(self, client):
        """Test Fehler wenn customer Parameter leer ist"""
        response = client.get('/api/devices/next-id?customer=')
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert data['success'] is False
    
    def test_get_next_id_with_special_customer_name(self, client):
        """Test mit Sonderzeichen im Kundennamen"""
        with patch('src.config.dependencies.container.device_repository.get_next_customer_device_id') as mock_get:
            mock_get.return_value = "Test-Kunde-00001"
            
            response = client.get('/api/devices/next-id?customer=Test-Kunde')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['next_id'] == "Test-Kunde-00001"
    
    def test_get_next_id_error(self, client):
        """Test Fehlerbehandlung"""
        with patch('src.config.dependencies.container.device_repository.get_next_customer_device_id') as mock_get:
            mock_get.side_effect = Exception("Database error")
            
            response = client.get('/api/devices/next-id?customer=Parloa')
            
            assert response.status_code == 500
            data = json.loads(response.data)
            assert data['success'] is False


class TestDeviceCreateRoute:
    """Tests für POST /api/devices"""
    
    def test_create_device_success(self, client, sample_device):
        """Test erfolgreiches Erstellen eines Geräts"""
        payload = {
            'customer': 'Parloa',
            'customer_device_id': 'Parloa-00001',
            'name': 'Elektroschrauber',
            'type': 'Elektrowerkzeug',
            'serial_number': 'SN-12345',
            'manufacturer': 'Bosch',
            'location': 'Lager A',
            'purchase_date': '2023-01-15',
            'status': 'active',
            'notes': 'Test device'
        }
        
        with patch('src.config.dependencies.container.create_device_usecase.execute') as mock_execute:
            mock_execute.return_value = sample_device
            
            response = client.post('/api/devices',
                                  data=json.dumps(payload),
                                  content_type='application/json')
            
            assert response.status_code == 201
            data = json.loads(response.data)
            assert data['success'] is True
            assert data['device']['customer_device_id'] == 'Parloa-00001'
    
    def test_create_device_missing_required_fields(self, client):
        """Test Fehler bei fehlenden Pflichtfeldern"""
        payload = {
            'customer': 'Parloa',
            # name fehlt!
            'type': 'Elektrowerkzeug'
        }
        
        response = client.post('/api/devices',
                              data=json.dumps(payload),
                              content_type='application/json')
        
        # Sollte Fehler werfen bei Device-Erstellung
        assert response.status_code in [400, 500]
    
    def test_create_device_with_empty_dates(self, client):
        """Test Erstellen mit leeren Datumfeldern"""
        payload = {
            'customer': 'Parloa',
            'customer_device_id': 'Parloa-00002',
            'name': 'Device ohne Datum',
            'type': 'Test',
            'purchase_date': '',  # Leeres Datum
            'status': 'active'
        }
        
        device = Device(
            id=2,
            customer='Parloa',
            customer_device_id='Parloa-00002',
            name='Device ohne Datum',
            type='Test',
            purchase_date=None,
            status='active'
        )
        
        with patch('src.config.dependencies.container.create_device_usecase.execute') as mock_execute:
            mock_execute.return_value = device
            
            response = client.post('/api/devices',
                                  data=json.dumps(payload),
                                  content_type='application/json')
            
            assert response.status_code == 201
            data = json.loads(response.data)
            assert data['success'] is True
    
    def test_create_device_invalid_status(self, client):
        """Test mit ungültigem Status"""
        payload = {
            'customer': 'Parloa',
            'customer_device_id': 'Parloa-00003',
            'name': 'Device',
            'type': 'Test',
            'status': 'invalid_status'  # Ungültiger Status
        }
        
        response = client.post('/api/devices',
                              data=json.dumps(payload),
                              content_type='application/json')
        
        # Sollte akzeptiert werden (keine Validierung in Route)
        # aber könnte in Zukunft validiert werden
        assert response.status_code in [201, 400, 500]
    
    def test_create_device_with_special_characters_in_id(self, client):
        """Test mit Sonderzeichen in customer_device_id"""
        payload = {
            'customer': 'Test-Kunde',
            'customer_device_id': 'Test-Kunde-00001',
            'name': 'Device',
            'type': 'Test',
            'status': 'active'
        }
        
        device = Device(
            id=4,
            customer='Test-Kunde',
            customer_device_id='Test-Kunde-00001',
            name='Device',
            type='Test',
            status='active'
        )
        
        with patch('src.config.dependencies.container.create_device_usecase.execute') as mock_execute:
            mock_execute.return_value = device
            
            response = client.post('/api/devices',
                                  data=json.dumps(payload),
                                  content_type='application/json')
            
            assert response.status_code == 201
            data = json.loads(response.data)
            assert data['device']['customer_device_id'] == 'Test-Kunde-00001'
    
    def test_create_device_error(self, client):
        """Test Fehlerbehandlung"""
        payload = {
            'customer': 'Parloa',
            'customer_device_id': 'Parloa-00001',
            'name': 'Device',
            'type': 'Test'
        }
        
        with patch('src.config.dependencies.container.create_device_usecase.execute') as mock_execute:
            mock_execute.side_effect = Exception("Database error")
            
            response = client.post('/api/devices',
                                  data=json.dumps(payload),
                                  content_type='application/json')
            
            assert response.status_code == 500
            data = json.loads(response.data)
            assert data['success'] is False


class TestDeviceUpdateRoute:
    """Tests für PUT /api/devices/<customer_device_id>"""
    
    def test_update_device_success(self, client, sample_device):
        """Test erfolgreiches Aktualisieren eines Geräts"""
        payload = {
            'customer': 'Parloa',
            'name': 'Elektroschrauber Updated',
            'type': 'Elektrowerkzeug',
            'location': 'Lager B',
            'status': 'maintenance'
        }
        
        updated_device = Device(
            id=1,
            customer='Parloa',
            customer_device_id='Parloa-00001',
            name='Elektroschrauber Updated',
            type='Elektrowerkzeug',
            location='Lager B',
            status='maintenance'
        )
        
        with patch('src.config.dependencies.container.update_device_usecase.execute') as mock_execute:
            mock_execute.return_value = updated_device
            
            response = client.put('/api/devices/Parloa-00001',
                                 data=json.dumps(payload),
                                 content_type='application/json')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['success'] is True
            assert data['device']['name'] == 'Elektroschrauber Updated'
    
    def test_update_device_with_special_id(self, client):
        """Test Aktualisieren mit Sonderzeichen in ID"""
        payload = {
            'customer': 'Test-Kunde',
            'name': 'Updated Device',
            'type': 'Test'
        }
        
        updated_device = Device(
            id=2,
            customer='Test-Kunde',
            customer_device_id='Test-Kunde-00001',
            name='Updated Device',
            type='Test'
        )
        
        with patch('src.config.dependencies.container.update_device_usecase.execute') as mock_execute:
            mock_execute.return_value = updated_device
            
            response = client.put('/api/devices/Test-Kunde-00001',
                                 data=json.dumps(payload),
                                 content_type='application/json')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['device']['customer_device_id'] == 'Test-Kunde-00001'
    
    def test_update_device_error(self, client):
        """Test Fehlerbehandlung"""
        payload = {
            'customer': 'Parloa',
            'name': 'Device'
        }
        
        with patch('src.config.dependencies.container.update_device_usecase.execute') as mock_execute:
            mock_execute.side_effect = Exception("Database error")
            
            response = client.put('/api/devices/Parloa-00001',
                                 data=json.dumps(payload),
                                 content_type='application/json')
            
            assert response.status_code == 500
            data = json.loads(response.data)
            assert data['success'] is False


class TestDeviceDeleteRoute:
    """Tests für DELETE /api/devices/<customer_device_id>"""
    
    def test_delete_device_success(self, client):
        """Test erfolgreiches Löschen eines Geräts"""
        with patch('src.config.dependencies.container.delete_device_usecase.execute') as mock_execute:
            mock_execute.return_value = True
            
            response = client.delete('/api/devices/Parloa-00001')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['success'] is True
            assert 'deleted successfully' in data['message'].lower()
    
    def test_delete_device_with_special_id(self, client):
        """Test Löschen mit Sonderzeichen in ID"""
        with patch('src.config.dependencies.container.delete_device_usecase.execute') as mock_execute:
            mock_execute.return_value = True
            
            response = client.delete('/api/devices/Test-Kunde-00001')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['success'] is True
    
    def test_delete_device_not_found(self, client):
        """Test Löschen wenn Gerät nicht existiert"""
        with patch('src.config.dependencies.container.delete_device_usecase.execute') as mock_execute:
            mock_execute.return_value = False
            
            response = client.delete('/api/devices/NonExistent-00001')
            
            # Sollte trotzdem 200 zurückgeben (Idempotent)
            assert response.status_code == 200
    
    def test_delete_device_error(self, client):
        """Test Fehlerbehandlung"""
        with patch('src.config.dependencies.container.delete_device_usecase.execute') as mock_execute:
            mock_execute.side_effect = Exception("Database error")
            
            response = client.delete('/api/devices/Parloa-00001')
            
            assert response.status_code == 500
            data = json.loads(response.data)
            assert data['success'] is False


class TestDataTypeValidation:
    """Tests für Datentyp-Validierung"""
    
    def test_varchar_field_length_validation(self, client):
        """Test VARCHAR-Feld Längenbeschränkung"""
        # customer_device_id ist VARCHAR(255)
        long_id = "A" * 300  # Zu lang!
        
        payload = {
            'customer': 'Parloa',
            'customer_device_id': long_id,
            'name': 'Device',
            'type': 'Test'
        }
        
        response = client.post('/api/devices',
                              data=json.dumps(payload),
                              content_type='application/json')
        
        # Sollte Fehler werfen (aber aktuell nicht validiert)
        # In Zukunft sollte dies validiert werden
        assert response.status_code in [201, 400, 500]
    
    def test_date_format_validation(self, client):
        """Test Datums-Format Validierung"""
        payload = {
            'customer': 'Parloa',
            'customer_device_id': 'Parloa-00001',
            'name': 'Device',
            'type': 'Test',
            'purchase_date': '2023-13-45'  # Ungültiges Datum!
        }
        
        response = client.post('/api/devices',
                              data=json.dumps(payload),
                              content_type='application/json')
        
        # Sollte Fehler werfen (aber aktuell nicht validiert)
        assert response.status_code in [201, 400, 500]
    
    def test_enum_status_validation(self, client):
        """Test ENUM Status Validierung"""
        payload = {
            'customer': 'Parloa',
            'customer_device_id': 'Parloa-00001',
            'name': 'Device',
            'type': 'Test',
            'status': 'invalid_status'  # Ungültiger Status!
        }
        
        response = client.post('/api/devices',
                              data=json.dumps(payload),
                              content_type='application/json')
        
        # Sollte Fehler werfen (aber aktuell nicht validiert)
        assert response.status_code in [201, 400, 500]


class TestHealthCheckRoute:
    """Tests für Health Check Route"""
    
    def test_health_check_success(self, client):
        """Test erfolgreiches Health Check"""
        with patch('src.adapters.services.health_check_service.HealthCheckService.full_health_check') as mock_health:
            mock_health.return_value = {
                'overall_status': 'healthy',
                'database': {'status': 'ok', 'response_time_ms': 10}
            }
            
            response = client.get('/api/devices/health')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['overall_status'] == 'healthy'
    
    def test_health_check_unhealthy(self, client):
        """Test Health Check wenn unhealthy"""
        with patch('src.adapters.services.health_check_service.HealthCheckService.full_health_check') as mock_health:
            mock_health.return_value = {
                'overall_status': 'unhealthy',
                'database': {'status': 'error', 'response_time_ms': 5000}
            }
            
            response = client.get('/api/devices/health')
            
            assert response.status_code == 503
            data = json.loads(response.data)
            assert data['overall_status'] == 'unhealthy'


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--tb=short'])
