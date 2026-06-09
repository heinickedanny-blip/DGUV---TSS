"""Device Use Cases - Hexagonal Architecture mit customer_device_id"""
from src.core.domain.device import Device
from src.core.ports.device_repository import DeviceRepository
from src.adapters.services.qr_code_generator import QRCodeGenerator
from src.adapters.services.logger_service import LoggerService
from typing import List, Optional


class ListDevicesUseCase:
    """List all devices"""
    def __init__(self, repository: DeviceRepository):
        self.repository = repository
        self.logger = LoggerService()
    
    def execute(self) -> List[Device]:
        self.logger.debug("ListDevicesUseCase executed")
        return self.repository.get_all()


class GetDeviceUseCase:
    """Get device by customer_device_id"""
    def __init__(self, repository: DeviceRepository):
        self.repository = repository
        self.logger = LoggerService()
    
    def execute(self, customer_device_id: str) -> Optional[Device]:
        self.logger.debug(f"GetDeviceUseCase executed for {customer_device_id}")
        return self.repository.get_by_customer_device_id(customer_device_id)


class CreateDeviceUseCase:
    """Create a new device with QR-Code generation"""
    def __init__(self, repository: DeviceRepository):
        self.repository = repository
        self.logger = LoggerService()
    
    def execute(self, device: Device) -> Device:
        self.logger.debug(f"CreateDeviceUseCase executed for {device.customer}")
        
        # Generate customer_device_id if not provided
        if not device.customer_device_id and device.customer:
            device.customer_device_id = self.repository.get_next_customer_device_id(device.customer)
            self.logger.debug(f"Generated customer_device_id: {device.customer_device_id}")
        
        # Generate QR-Code wenn customer_device_id vorhanden ist
        if device.customer_device_id:
            qr_code_bytes = QRCodeGenerator.generate_qr_code(
                device_id=device.customer_device_id,
                customer=device.customer or ""
            )
            if qr_code_bytes:
                device.qr_code = qr_code_bytes
                self.logger.debug(f"QR-Code generated for {device.customer_device_id}")
        
        created_device = self.repository.create(device)
        self.logger.info(f"Device created: {created_device.customer_device_id}")
        return created_device


class UpdateDeviceUseCase:
    """Update an existing device"""
    def __init__(self, repository: DeviceRepository):
        self.repository = repository
        self.logger = LoggerService()
    
    def execute(self, device: Device) -> Device:
        self.logger.debug(f"UpdateDeviceUseCase executed for {device.customer_device_id}")
        updated_device = self.repository.update(device)
        self.logger.info(f"Device updated: {updated_device.customer_device_id}")
        return updated_device


class DeleteDeviceUseCase:
    """Delete a device"""
    def __init__(self, repository: DeviceRepository):
        self.repository = repository
        self.logger = LoggerService()
    
    def execute(self, customer_device_id: str) -> bool:
        self.logger.debug(f"DeleteDeviceUseCase executed for {customer_device_id}")
        result = self.repository.delete(customer_device_id)
        if result:
            self.logger.info(f"Device deleted: {customer_device_id}")
        return result
