"""Unit Tests für Device Domain Model"""
import pytest
from datetime import datetime
from src.core.domain.device import Device


class TestDeviceCreation:
    """Tests für Device Erstellung"""

    def test_device_creation_with_all_fields(self):
        """Test: Device mit allen Feldern erstellen"""
        device = Device(
            id=1,
            name="Test Device",
            device_type="USB-C Cable",
            serial_number="SN123456",
            manufacturer="TestMfg",
            model="Model-X",
            description="Test Description"
        )
        
        assert device.id == 1
        assert device.name == "Test Device"
        assert device.device_type == "USB-C Cable"
        assert device.serial_number == "SN123456"
        assert device.manufacturer == "TestMfg"
        assert device.model == "Model-X"
        assert device.description == "Test Description"

    def test_device_creation_with_minimal_fields(self):
        """Test: Device mit minimalen Feldern erstellen"""
        device = Device(name="Minimal Device")
        
        assert device.name == "Minimal Device"
        assert device.device_type == ""
        assert device.serial_number == ""
        assert device.created_at is not None
        assert device.updated_at is not None

    def test_device_default_values(self):
        """Test: Device hat richtige Default-Werte"""
        device = Device()
        
        assert device.id is None
        assert device.name == ""
        assert device.device_type == ""
        assert device.serial_number == ""
        assert device.manufacturer == ""
        assert device.model == ""
        assert device.description == ""

    def test_device_timestamps_set_automatically(self):
        """Test: Timestamps werden automatisch gesetzt"""
        before = datetime.now()
        device = Device(name="Test")
        after = datetime.now()
        
        assert device.created_at is not None
        assert device.updated_at is not None
        assert before <= device.created_at <= after
        assert before <= device.updated_at <= after


class TestDeviceUpdate:
    """Tests für Device Update Methode"""

    def test_device_update_single_field(self):
        """Test: Ein Feld aktualisieren"""
        device = Device(id=1, name="Old Name")
        old_updated_at = device.updated_at
        
        device.update(name="New Name")
        
        assert device.name == "New Name"
        assert device.updated_at > old_updated_at

    def test_device_update_multiple_fields(self):
        """Test: Mehrere Felder aktualisieren"""
        device = Device(id=1, name="Old", device_type="Old Type")
        
        device.update(name="New", device_type="New Type", serial_number="SN999")
        
        assert device.name == "New"
        assert device.device_type == "New Type"
        assert device.serial_number == "SN999"

    def test_device_update_nonexistent_field(self):
        """Test: Update mit nicht existierendem Feld ignoriert es"""
        device = Device(id=1, name="Test")
        
        # Sollte keinen Fehler werfen
        device.update(nonexistent_field="value")
        
        assert device.name == "Test"

    def test_device_update_timestamp_changes(self):
        """Test: updated_at ändert sich bei Update"""
        device = Device(id=1, name="Test")
        original_updated_at = device.updated_at
        
        device.update(name="Updated")
        
        assert device.updated_at > original_updated_at


class TestDeviceRepresentation:
    """Tests für Device String Repräsentation"""

    def test_device_repr(self):
        """Test: Device __repr__ Ausgabe"""
        device = Device(id=1, name="Test Device", serial_number="SN123")
        repr_str = repr(device)
        
        assert "Device" in repr_str
        assert "id=1" in repr_str
        assert "name=Test Device" in repr_str
        assert "serial=SN123" in repr_str

    def test_device_repr_with_none_id(self):
        """Test: Device __repr__ mit None ID"""
        device = Device(name="Test", serial_number="SN456")
        repr_str = repr(device)
        
        assert "Device" in repr_str
        assert "id=None" in repr_str


class TestDeviceValidation:
    """Tests für Device Validierung"""

    def test_device_with_empty_name(self):
        """Test: Device mit leerem Namen"""
        device = Device(name="")
        assert device.name == ""

    def test_device_with_special_characters(self):
        """Test: Device mit Sonderzeichen"""
        device = Device(
            name="Device-123_ABC",
            serial_number="SN/2024/001"
        )
        
        assert device.name == "Device-123_ABC"
        assert device.serial_number == "SN/2024/001"

    def test_device_with_long_description(self):
        """Test: Device mit langer Beschreibung"""
        long_desc = "A" * 1000
        device = Device(description=long_desc)
        
        assert device.description == long_desc
        assert len(device.description) == 1000


class TestDeviceEquality:
    """Tests für Device Gleichheit"""

    def test_two_devices_with_same_data(self):
        """Test: Zwei Devices mit gleichen Daten"""
        device1 = Device(id=1, name="Test", serial_number="SN123")
        device2 = Device(id=1, name="Test", serial_number="SN123")
        
        # Dataclass Gleichheit
        assert device1 == device2

    def test_two_devices_with_different_data(self):
        """Test: Zwei Devices mit unterschiedlichen Daten"""
        device1 = Device(id=1, name="Test1")
        device2 = Device(id=2, name="Test2")
        
        assert device1 != device2
