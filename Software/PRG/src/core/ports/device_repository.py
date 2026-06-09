"""Device Repository Port - Hexagonal Architecture Interface"""
from abc import ABC, abstractmethod
from typing import List, Optional
from src.core.domain.device import Device


class DeviceRepository(ABC):
    """Abstract Device Repository - Port for Hexagonal Architecture
    
    This interface defines the contract that all device repository implementations
    must follow. It separates the business logic from the persistence layer.
    """
    
    @abstractmethod
    def create(self, device: Device) -> Device:
        """Create a new device
        
        Args:
            device: Device object to create
            
        Returns:
            Created device with ID assigned
            
        Raises:
            Exception: If device creation fails
        """
        pass
    
    @abstractmethod
    def get_by_id(self, device_id: int) -> Optional[Device]:
        """Get device by numeric ID
        
        Args:
            device_id: Numeric device ID
            
        Returns:
            Device object or None if not found
        """
        pass
    
    @abstractmethod
    def get_by_customer_device_id(self, customer_device_id: str) -> Optional[Device]:
        """Get device by customer_device_id (e.g., Parloa-00001)
        
        Args:
            customer_device_id: Customer-formatted device ID
            
        Returns:
            Device object or None if not found
        """
        pass
    
    @abstractmethod
    def get_all(self) -> List[Device]:
        """Get all devices
        
        Returns:
            List of all devices
        """
        pass
    
    @abstractmethod
    def update(self, device: Device) -> Device:
        """Update an existing device
        
        Args:
            device: Device object with updated values
            
        Returns:
            Updated device object
            
        Raises:
            Exception: If device update fails
        """
        pass
    
    @abstractmethod
    def delete(self, customer_device_id: str) -> bool:
        """Delete a device
        
        Args:
            customer_device_id: Customer-formatted device ID to delete
            
        Returns:
            True if deleted, False otherwise
            
        Raises:
            Exception: If device deletion fails
        """
        pass
    
    @abstractmethod
    def get_next_customer_device_id(self, customer: str) -> str:
        """Get next customer device ID
        
        Args:
            customer: Customer name
            
        Returns:
            Next customer device ID (e.g., "Parloa-00001")
        """
        pass
