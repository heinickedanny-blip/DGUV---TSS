"""Pytest Konfiguration und globale Fixtures"""
import pytest
import os
from datetime import datetime
from unittest.mock import Mock
from src.core.domain.device import Device


# ANCHOR: Environment Setup
@pytest.fixture(scope="session", autouse=True)
def setup_test_environment():
    """Setup Test Environment"""
    os.environ['FLASK_ENV'] = 'testing'
    os.environ['DB_HOST'] = 'localhost'
    os.environ['DB_PORT'] = '3307'
    os.environ['DB_USER'] = 'test'
    os.environ['DB_PASSWORD'] = 'test'
    os.environ['DB_NAME'] = 'test_db'


# ANCHOR: Device Fixtures
@pytest.fixture
def sample_device():
    """Beispiel Device"""
    return Device(
        id=1,
        name="Test Device",
        device_type="USB-C Cable",
        serial_number="SN123456",
        manufacturer="TestMfg",
        model="Model-X",
        description="Test Description"
    )


@pytest.fixture
def sample_devices():
    """Liste mit Beispiel Devices"""
    return [
        Device(
            id=1,
            name="Device 1",
            device_type="USB-C",
            serial_number="SN001",
            manufacturer="Mfg1"
        ),
        Device(
            id=2,
            name="Device 2",
            device_type="USB-A",
            serial_number="SN002",
            manufacturer="Mfg2"
        ),
        Device(
            id=3,
            name="Device 3",
            device_type="HDMI",
            serial_number="SN003",
            manufacturer="Mfg3"
        )
    ]


@pytest.fixture
def minimal_device():
    """Minimales Device"""
    return Device(name="Minimal Device")


@pytest.fixture
def device_with_all_fields():
    """Device mit allen Feldern"""
    return Device(
        id=1,
        name="Complete Device",
        device_type="USB-C",
        serial_number="SN123",
        manufacturer="TestMfg",
        model="Model-X",
        description="Full description",
        created_at=datetime.now(),
        updated_at=datetime.now()
    )


# ANCHOR: Mock Fixtures
@pytest.fixture
def mock_repository():
    """Mock Device Repository"""
    repo = Mock()
    repo.get_by_id = Mock()
    repo.get_all = Mock()
    repo.create = Mock()
    repo.update = Mock()
    repo.delete = Mock()
    repo.get_recent = Mock()
    repo.get_by_status = Mock()
    repo.get_next_id = Mock()
    return repo


@pytest.fixture
def mock_container():
    """Mock DI Container"""
    container = Mock()
    container.device_repository = Mock()
    container.list_devices_usecase = Mock()
    container.get_device_usecase = Mock()
    container.create_device_usecase = Mock()
    container.update_device_usecase = Mock()
    container.delete_device_usecase = Mock()
    return container


@pytest.fixture
def mock_db_connection():
    """Mock Datenbankverbindung"""
    conn = Mock()
    cursor = Mock()
    conn.cursor.return_value = cursor
    return conn


# ANCHOR: API Payload Fixtures
@pytest.fixture
def create_device_payload():
    """Payload für Device Erstellung"""
    return {
        'id': '1',
        'name': 'New Device',
        'device_type': 'USB-C',
        'serial_number': 'SN999',
        'manufacturer': 'TestMfg',
        'model': 'Model-X',
        'description': 'Test Device'
    }


@pytest.fixture
def update_device_payload():
    """Payload für Device Update"""
    return {
        'name': 'Updated Device',
        'device_type': 'USB-A',
        'serial_number': 'SN888',
        'manufacturer': 'UpdatedMfg'
    }


@pytest.fixture
def invalid_payload():
    """Ungültiges Payload"""
    return {
        'name': '',  # Leerer Name
        'serial_number': None
    }


# ANCHOR: Pytest Hooks
def pytest_configure(config):
    """Pytest Konfiguration"""
    config.addinivalue_line(
        "markers", "unit: Unit Tests"
    )
    config.addinivalue_line(
        "markers", "integration: Integration Tests"
    )
    config.addinivalue_line(
        "markers", "slow: Langsame Tests"
    )


def pytest_collection_modifyitems(config, items):
    """Modifiziere Test Collection"""
    for item in items:
        # Markiere Tests basierend auf Pfad
        if "test_device_domain" in str(item.fspath):
            item.add_marker(pytest.mark.unit)
        elif "test_device_usecases" in str(item.fspath):
            item.add_marker(pytest.mark.unit)
        elif "test_mysql" in str(item.fspath):
            item.add_marker(pytest.mark.unit)
        elif "test_device_api" in str(item.fspath):
            item.add_marker(pytest.mark.integration)


# ANCHOR: Custom Assertions
class DeviceAssertions:
    """Custom Assertions für Devices"""
    
    @staticmethod
    def assert_device_valid(device):
        """Überprüfe ob Device gültig ist"""
        assert device is not None
        assert hasattr(device, 'id')
        assert hasattr(device, 'name')
        assert hasattr(device, 'created_at')
        assert hasattr(device, 'updated_at')
    
    @staticmethod
    def assert_device_equal(device1, device2):
        """Überprüfe ob zwei Devices gleich sind"""
        assert device1.id == device2.id
        assert device1.name == device2.name
        assert device1.serial_number == device2.serial_number


@pytest.fixture
def device_assertions():
    """Device Assertions Fixture"""
    return DeviceAssertions()
