"""Unit Tests für Device Domain Model - Saubere Version"""
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
            type="USB-C",
            serial_number="SN123456",
            manufacturer="Benning",
            model="Model-X",
            location="Lager A",
            status="active",
            notes="Test Device"
        )
        
        assert device.id == 1
        assert device.name == "Test Device"
        assert device.type == "USB-C"
        assert device.serial_number == "SN123456"
        assert device.manufacturer == "Benning"
        assert device.model == "Model-X"
        assert device.location == "Lager A"
        assert device.status == "active"

    def test_device_creation_with_minimal_fields(self):
        """Test: Device mit minimalen Feldern erstellen"""
        device = Device(name="Minimal Device")
        
        assert device.name == "Minimal Device"
        assert device.id is None
        assert device.type is None
        assert device.serial_number is None
        assert device.status == "active"

    def test_device_default_values(self):
        """Test: Default Werte prüfen"""
        device = Device()
        
        assert device.id is None
        assert device.name == ""
        assert device.type is None
        assert device.status == "active"
        assert device.notes is None

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
    """Tests für Device Update"""

    def test_device_update_single_field(self):
        """Test: Ein Feld aktualisieren"""
        device = Device(id=1, name="Old Name")
        old_updated_at = device.updated_at
        
        device.update(name="New Name")
        
        assert device.name == "New Name"
        assert device.updated_at > old_updated_at

    def test_device_update_multiple_fields(self):
        """Test: Mehrere Felder aktualisieren"""
        device = Device(id=1, name="Old", type="USB-A")
        
        device.update(name="New", type="USB-C", serial_number="SN999")
        
        assert device.name == "New"
        assert device.type == "USB-C"
        assert device.serial_number == "SN999"

    def test_device_update_nonexistent_field(self):
        """Test: Nicht existierendes Feld aktualisieren"""
        device = Device(id=1, name="Test")
        
        # update() ignoriert nicht existierende Felder
        device.update(nonexistent_field="value")
        
        assert not hasattr(device, 'nonexistent_field')

    def test_device_update_timestamp_changes(self):
        """Test: Timestamp ändert sich bei Update"""
        device = Device(id=1, name="Test")
        original_created_at = device.created_at
        original_updated_at = device.updated_at
        
        device.update(name="Updated")
        
        assert device.created_at == original_created_at
        assert device.updated_at > original_updated_at


class TestDeviceRepresentation:
    """Tests für Device Repräsentation"""

    def test_device_repr(self):
        """Test: Device __repr__"""
        device = Device(id=1, name="Test Device", serial_number="SN123", type="USB-C")
        
        repr_str = repr(device)
        
        assert "Device" in repr_str
        assert "id=1" in repr_str
        assert "name='Test Device'" in repr_str
        assert "serial=SN123" in repr_str

    def test_device_repr_with_none_id(self):
        """Test: Device __repr__ mit None ID"""
        device = Device(name="Test Device")
        
        repr_str = repr(device)
        
        assert "Device" in repr_str
        assert "id=None" in repr_str
        assert "Test Device" in repr_str


class TestDeviceValidation:
    """Tests für Device Validierung"""

    def test_device_with_empty_name(self):
        """Test: Device mit leerem Namen"""
        device = Device(id=1, name="")
        
        assert device.name == ""
        assert device.id == 1

    def test_device_with_special_characters(self):
        """Test: Device mit Sonderzeichen"""
        device = Device(
            id=1,
            name="Test-Device_123",
            serial_number="SN-123/456"
        )
        
        assert device.name == "Test-Device_123"
        assert device.serial_number == "SN-123/456"

    def test_device_with_long_notes(self):
        """Test: Device mit langen Notizen"""
        long_notes = "A" * 1000
        device = Device(id=1, name="Test", notes=long_notes)
        
        assert device.notes == long_notes
        assert len(device.notes) == 1000


class TestDeviceEquality:
    """Tests für Device Gleichheit"""

    def test_two_devices_with_same_data(self):
        """Test: Zwei Devices mit gleichen Daten"""
        device1 = Device(id=1, name="Test", serial_number="SN123")
        device2 = Device(id=1, name="Test", serial_number="SN123")
        
        assert device1 == device2

    def test_two_devices_with_different_data(self):
        """Test: Zwei Devices mit unterschiedlichen Daten"""
        device1 = Device(id=1, name="Device 1")
        device2 = Device(id=2, name="Device 2")
        
        assert device1 != device2


class TestDeviceConversion:
    """Tests für Device Konvertierung"""

    def test_device_to_dict(self):
        """Test: Device zu Dictionary konvertieren"""
        device = Device(
            id=1,
            name="Test",
            type="USB-C",
            serial_number="SN123",
            status="active"
        )
        
        device_dict = device.to_dict()
        
        assert device_dict['id'] == 1
        assert device_dict['name'] == "Test"
        assert device_dict['type'] == "USB-C"
        assert device_dict['serial_number'] == "SN123"
        assert device_dict['status'] == "active"

    def test_device_from_dict(self):
        """Test: Device aus Dictionary erstellen"""
        data = {
            'id': 1,
            'name': 'Test',
            'type': 'USB-C',
            'serial_number': 'SN123',
            'status': 'active'
        }
        
        device = Device.from_dict(data)
        
        assert device.id == 1
        assert device.name == 'Test'
        assert device.type == 'USB-C'


class TestDeviceEdgeCases:
    """Tests für Edge Cases"""

    def test_device_with_none_values(self):
        """Test: Device mit None Werten"""
        device = Device(
            id=None,
            name="Test",
            serial_number=None
        )
        
        assert device.id is None
        assert device.name == "Test"
        assert device.serial_number is None

    def test_device_update_with_none(self):
        """Test: Update mit None Wert"""
        device = Device(id=1, name="Test", serial_number="SN123")
        
        device.update(serial_number=None)
        
        assert device.serial_number is None

    def test_device_status_values(self):
        """Test: Verschiedene Status Werte"""
        statuses = ["active", "inactive", "maintenance", "retired"]
        
        for status in statuses:
            device = Device(id=1, name="Test", status=status)
            assert device.status == status

    def test_device_with_numeric_strings(self):
        """Test: Device mit numerischen Strings"""
        device = Device(
            id=1,
            name="123",
            serial_number="456",
            model="789"
        )
        
        assert device.name == "123"
        assert device.serial_number == "456"
        assert device.model == "789"

    def test_device_timestamps_independent(self):
        """Test: created_at und updated_at sind unabhängig"""
        device = Device(id=1, name="Test")
        original_created = device.created_at
        
        device.update(name="Updated")
        
        assert device.created_at == original_created
        assert device.updated_at > original_created
