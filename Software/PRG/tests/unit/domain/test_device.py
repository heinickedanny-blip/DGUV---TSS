"""Device Model Tests"""
import pytest
from src.core.domain.device import Device

def test_device_creation():
    device = Device(name="Test Device", serial_number="SN123")
    assert device.name == "Test Device"
    assert device.serial_number == "SN123"
    assert device.created_at is not None

def test_device_update():
    device = Device(name="Old Name")
    device.update(name="New Name")
    assert device.name == "New Name"
    assert device.updated_at is not None

def test_device_repr():
    device = Device(id=1, name="Test", serial_number="SN123")
    assert "Device" in repr(device)
    assert "SN123" in repr(device)
