"""Unit Tests für Device Use Cases"""
import pytest
from unittest.mock import Mock, MagicMock
from src.core.domain.device import Device
from src.core.usecases.device_usecases import (
    GetDeviceUseCase,
    ListDevicesUseCase,
    CreateDeviceUseCase,
    UpdateDeviceUseCase,
    DeleteDeviceUseCase
)


class TestGetDeviceUseCase:
    """Tests für GetDeviceUseCase"""

    def test_get_device_success(self):
        """Test: Device erfolgreich abrufen"""
        # ANCHOR: Setup
        mock_repo = Mock()
        device = Device(id=1, name="Test Device")
        mock_repo.get_by_id.return_value = device
        
        usecase = GetDeviceUseCase(mock_repo)
        
        # ANCHOR: Execute
        result = usecase.execute(1)
        
        # ANCHOR: Assert
        assert result == device
        mock_repo.get_by_id.assert_called_once_with(1)

    def test_get_device_not_found(self):
        """Test: Device nicht gefunden"""
        mock_repo = Mock()
        mock_repo.get_by_id.return_value = None
        
        usecase = GetDeviceUseCase(mock_repo)
        result = usecase.execute(999)
        
        assert result is None
        mock_repo.get_by_id.assert_called_once_with(999)

    def test_get_device_repository_error(self):
        """Test: Repository Fehler"""
        mock_repo = Mock()
        mock_repo.get_by_id.side_effect = Exception("DB Error")
        
        usecase = GetDeviceUseCase(mock_repo)
        
        with pytest.raises(Exception):
            usecase.execute(1)


class TestListDevicesUseCase:
    """Tests für ListDevicesUseCase"""

    def test_list_devices_success(self):
        """Test: Alle Devices erfolgreich abrufen"""
        mock_repo = Mock()
        devices = [
            Device(id=1, name="Device 1"),
            Device(id=2, name="Device 2"),
            Device(id=3, name="Device 3")
        ]
        mock_repo.get_all.return_value = devices
        
        usecase = ListDevicesUseCase(mock_repo)
        result = usecase.execute()
        
        assert result == devices
        assert len(result) == 3
        mock_repo.get_all.assert_called_once()

    def test_list_devices_empty(self):
        """Test: Keine Devices vorhanden"""
        mock_repo = Mock()
        mock_repo.get_all.return_value = []
        
        usecase = ListDevicesUseCase(mock_repo)
        result = usecase.execute()
        
        assert result == []
        assert len(result) == 0

    def test_list_devices_repository_error(self):
        """Test: Repository Fehler"""
        mock_repo = Mock()
        mock_repo.get_all.side_effect = Exception("DB Error")
        
        usecase = ListDevicesUseCase(mock_repo)
        
        with pytest.raises(Exception):
            usecase.execute()


class TestCreateDeviceUseCase:
    """Tests für CreateDeviceUseCase"""

    def test_create_device_success(self):
        """Test: Device erfolgreich erstellen"""
        mock_repo = Mock()
        device = Device(id=1, name="New Device", serial_number="SN123")
        mock_repo.create.return_value = device
        
        usecase = CreateDeviceUseCase(mock_repo)
        result = usecase.execute(device)
        
        assert result == device
        assert result.id == 1
        mock_repo.create.assert_called_once_with(device)

    def test_create_device_with_minimal_data(self):
        """Test: Device mit minimalen Daten erstellen"""
        mock_repo = Mock()
        device = Device(name="Minimal")
        mock_repo.create.return_value = device
        
        usecase = CreateDeviceUseCase(mock_repo)
        result = usecase.execute(device)
        
        assert result.name == "Minimal"
        mock_repo.create.assert_called_once()

    def test_create_device_repository_error(self):
        """Test: Repository Fehler beim Erstellen"""
        mock_repo = Mock()
        device = Device(name="Test")
        mock_repo.create.side_effect = Exception("DB Error")
        
        usecase = CreateDeviceUseCase(mock_repo)
        
        with pytest.raises(Exception):
            usecase.execute(device)

    def test_create_device_duplicate_id(self):
        """Test: Duplicate ID Fehler"""
        mock_repo = Mock()
        device = Device(id=1, name="Duplicate")
        mock_repo.create.side_effect = Exception("Duplicate entry")
        
        usecase = CreateDeviceUseCase(mock_repo)
        
        with pytest.raises(Exception):
            usecase.execute(device)


class TestUpdateDeviceUseCase:
    """Tests für UpdateDeviceUseCase"""

    def test_update_device_success(self):
        """Test: Device erfolgreich aktualisieren"""
        mock_repo = Mock()
        device = Device(id=1, name="Updated Device")
        mock_repo.update.return_value = device
        
        usecase = UpdateDeviceUseCase(mock_repo)
        result = usecase.execute(device)
        
        assert result == device
        assert result.name == "Updated Device"
        mock_repo.update.assert_called_once_with(device)

    def test_update_device_not_found(self):
        """Test: Device nicht gefunden"""
        mock_repo = Mock()
        device = Device(id=999, name="Not Found")
        mock_repo.update.return_value = None
        
        usecase = UpdateDeviceUseCase(mock_repo)
        result = usecase.execute(device)
        
        assert result is None

    def test_update_device_repository_error(self):
        """Test: Repository Fehler"""
        mock_repo = Mock()
        device = Device(id=1, name="Test")
        mock_repo.update.side_effect = Exception("DB Error")
        
        usecase = UpdateDeviceUseCase(mock_repo)
        
        with pytest.raises(Exception):
            usecase.execute(device)

    def test_update_device_partial_fields(self):
        """Test: Nur einige Felder aktualisieren"""
        mock_repo = Mock()
        device = Device(id=1, name="Updated")
        mock_repo.update.return_value = device
        
        usecase = UpdateDeviceUseCase(mock_repo)
        result = usecase.execute(device)
        
        assert result.id == 1
        mock_repo.update.assert_called_once()


class TestDeleteDeviceUseCase:
    """Tests für DeleteDeviceUseCase"""

    def test_delete_device_success(self):
        """Test: Device erfolgreich löschen"""
        mock_repo = Mock()
        mock_repo.delete.return_value = True
        
        usecase = DeleteDeviceUseCase(mock_repo)
        result = usecase.execute(1)
        
        assert result is True
        mock_repo.delete.assert_called_once_with(1)

    def test_delete_device_not_found(self):
        """Test: Device nicht gefunden"""
        mock_repo = Mock()
        mock_repo.delete.return_value = False
        
        usecase = DeleteDeviceUseCase(mock_repo)
        result = usecase.execute(999)
        
        assert result is False

    def test_delete_device_repository_error(self):
        """Test: Repository Fehler"""
        mock_repo = Mock()
        mock_repo.delete.side_effect = Exception("DB Error")
        
        usecase = DeleteDeviceUseCase(mock_repo)
        
        with pytest.raises(Exception):
            usecase.execute(1)

    def test_delete_multiple_devices(self):
        """Test: Mehrere Devices löschen"""
        mock_repo = Mock()
        mock_repo.delete.return_value = True
        
        usecase = DeleteDeviceUseCase(mock_repo)
        
        for device_id in [1, 2, 3]:
            result = usecase.execute(device_id)
            assert result is True
        
        assert mock_repo.delete.call_count == 3
