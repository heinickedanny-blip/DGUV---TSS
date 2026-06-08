"""Tests für MySQL Device Repository"""
import pytest
from unittest.mock import Mock, patch, MagicMock, call
from datetime import datetime, date
from src.core.domain.device import Device
from src.adapters.persistence.mysql_device_repository import MySQLDeviceRepository


@pytest.fixture
def mock_connection():
    """Mock MySQL Connection"""
    return Mock()


@pytest.fixture
def mock_cursor():
    """Mock MySQL Cursor"""
    return Mock()


@pytest.fixture
def repository():
    """Repository Instanz"""
    with patch.dict('os.environ', {
        'DB_HOST': 'localhost',
        'DB_PORT': '3307',
        'DB_USER': 'test',
        'DB_PASSWORD': 'test',
        'DB_NAME': 'test_db'
    }):
        return MySQLDeviceRepository()


class TestMySQLDeviceRepositoryConnection:
    """Tests für Datenbankverbindung"""

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_connection_success(self, mock_connect, repository):
        """Test: Erfolgreiche Datenbankverbindung"""
        mock_conn = Mock()
        mock_connect.return_value = mock_conn
        
        conn = repository._get_connection()
        
        assert conn == mock_conn
        mock_connect.assert_called_once()

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_connection_with_correct_config(self, mock_connect, repository):
        """Test: Verbindung mit korrekten Konfigurationswerten"""
        mock_conn = Mock()
        mock_connect.return_value = mock_conn
        
        repository._get_connection()
        
        call_kwargs = mock_connect.call_args[1]
        assert call_kwargs['host'] == 'localhost'
        assert call_kwargs['port'] == 3307
        assert call_kwargs['user'] == 'test'
        assert call_kwargs['password'] == 'test'
        assert call_kwargs['database'] == 'test_db'


class TestMySQLDeviceRepositoryCreate:
    """Tests für Device Erstellung"""

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_create_device_success(self, mock_connect, repository):
        """Test: Device erfolgreich erstellen"""
        # ANCHOR: Setup
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        device = Device(
            id=1,
            name="Test Device",
            device_type="USB-C",
            serial_number="SN123",
            manufacturer="TestMfg"
        )
        
        # ANCHOR: Execute
        result = repository.create(device)
        
        # ANCHOR: Assert
        assert result == device
        mock_cursor.execute.assert_called_once()
        mock_conn.commit.assert_called_once()
        mock_cursor.close.assert_called_once()
        mock_conn.close.assert_called_once()

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_create_device_with_null_fields(self, mock_connect, repository):
        """Test: Device mit NULL Feldern erstellen"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        device = Device(id=1, name="Device")
        
        result = repository.create(device)
        
        assert result == device
        # Überprüfe dass NULL Werte übergeben werden
        call_args = mock_cursor.execute.call_args[0]
        assert call_args[1][2] is None  # device_type sollte None sein

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_create_device_database_error(self, mock_connect, repository):
        """Test: Datenbankfehler beim Erstellen"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.execute.side_effect = Exception("Duplicate entry")
        mock_connect.return_value = mock_conn
        
        device = Device(id=1, name="Device")
        
        with pytest.raises(Exception):
            repository.create(device)


class TestMySQLDeviceRepositoryRead:
    """Tests für Device Abrufen"""

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_get_by_id_success(self, mock_connect, repository):
        """Test: Device nach ID abrufen"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        row_data = {
            'id': 1,
            'name': 'Test Device',
            'device_type': 'USB-C',
            'serial_number': 'SN123',
            'manufacturer': 'TestMfg',
            'model': 'Model-X',
            'description': 'Test',
            'created_at': datetime.now(),
            'updated_at': datetime.now()
        }
        mock_cursor.fetchone.return_value = row_data
        
        result = repository.get_by_id(1)
        
        assert result is not None
        assert result.id == 1
        assert result.name == 'Test Device'
        mock_cursor.execute.assert_called_once()

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_get_by_id_not_found(self, mock_connect, repository):
        """Test: Device nicht gefunden"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = None
        mock_connect.return_value = mock_conn
        
        result = repository.get_by_id(999)
        
        assert result is None

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_get_all_success(self, mock_connect, repository):
        """Test: Alle Devices abrufen"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        rows_data = [
            {'id': 1, 'name': 'Device 1', 'device_type': 'Type1', 'serial_number': 'SN1', 'manufacturer': 'Mfg1', 'model': 'M1', 'description': 'D1', 'created_at': None, 'updated_at': None},
            {'id': 2, 'name': 'Device 2', 'device_type': 'Type2', 'serial_number': 'SN2', 'manufacturer': 'Mfg2', 'model': 'M2', 'description': 'D2', 'created_at': None, 'updated_at': None}
        ]
        mock_cursor.fetchall.return_value = rows_data
        
        result = repository.get_all()
        
        assert len(result) == 2
        assert result[0].id == 1
        assert result[1].id == 2

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_get_all_empty(self, mock_connect, repository):
        """Test: Keine Devices vorhanden"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchall.return_value = []
        mock_connect.return_value = mock_conn
        
        result = repository.get_all()
        
        assert result == []


class TestMySQLDeviceRepositoryUpdate:
    """Tests für Device Update"""

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_update_device_success(self, mock_connect, repository):
        """Test: Device erfolgreich aktualisieren"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        # Mock get_by_id für den Return
        with patch.object(repository, 'get_by_id') as mock_get:
            updated_device = Device(id=1, name="Updated")
            mock_get.return_value = updated_device
            
            device = Device(id=1, name="Updated")
            result = repository.update(device)
            
            assert result == updated_device
            mock_cursor.execute.assert_called_once()
            mock_conn.commit.assert_called_once()

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_update_device_with_null_fields(self, mock_connect, repository):
        """Test: Update mit NULL Feldern"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        with patch.object(repository, 'get_by_id') as mock_get:
            mock_get.return_value = Device(id=1, name="Test")
            
            device = Device(id=1, name="Test", device_type="")
            repository.update(device)
            
            # Überprüfe dass leere Strings zu None werden
            call_args = mock_cursor.execute.call_args[0]
            assert call_args[1][1] is None  # device_type sollte None sein


class TestMySQLDeviceRepositoryDelete:
    """Tests für Device Löschen"""

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_delete_device_success(self, mock_connect, repository):
        """Test: Device erfolgreich löschen"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        result = repository.delete(1)
        
        assert result is True
        mock_cursor.execute.assert_called_once()
        mock_conn.commit.assert_called_once()

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_delete_device_error(self, mock_connect, repository):
        """Test: Fehler beim Löschen"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_cursor.execute.side_effect = Exception("DB Error")
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        result = repository.delete(1)
        
        assert result is False


class TestMySQLDeviceRepositoryHelpers:
    """Tests für Helper Methoden"""

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_get_recent_success(self, mock_connect, repository):
        """Test: Letzte Devices abrufen"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        rows_data = [
            {'id': 1, 'name': 'Device 1', 'device_type': 'Type1', 'serial_number': 'SN1', 'manufacturer': 'Mfg1', 'model': 'M1', 'description': 'D1', 'created_at': None, 'updated_at': None}
        ]
        mock_cursor.fetchall.return_value = rows_data
        
        result = repository.get_recent(limit=10)
        
        assert len(result) == 1
        mock_cursor.execute.assert_called_once()

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_get_by_status_success(self, mock_connect, repository):
        """Test: Devices nach Status abrufen"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        rows_data = [
            {'id': 1, 'name': 'Device 1', 'device_type': 'Type1', 'serial_number': 'SN1', 'manufacturer': 'Mfg1', 'model': 'M1', 'description': 'D1', 'created_at': None, 'updated_at': None}
        ]
        mock_cursor.fetchall.return_value = rows_data
        
        result = repository.get_by_status('active')
        
        assert len(result) == 1

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_get_next_id_success(self, mock_connect, repository):
        """Test: Nächste ID abrufen"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = {'max_id': 5}
        mock_connect.return_value = mock_conn
        
        result = repository.get_next_id()
        
        assert result == "6"

    @patch('src.adapters.persistence.mysql_device_repository.mysql.connector.connect')
    def test_get_next_id_empty_table(self, mock_connect, repository):
        """Test: Nächste ID bei leerer Tabelle"""
        mock_conn = Mock()
        mock_cursor = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_cursor.fetchone.return_value = {'max_id': None}
        mock_connect.return_value = mock_conn
        
        result = repository.get_next_id()
        
        assert result == "1"
