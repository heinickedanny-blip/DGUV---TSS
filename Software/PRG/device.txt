"""Device Domain Model - Saubere Version"""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


@dataclass
class Device:
    """Device Entity - Hexagonal Architecture"""
    
    # ANCHOR: Required Fields
    id: Optional[int] = None
    name: str = ""
    
    # ANCHOR: Optional Fields
    type: Optional[str] = None
    serial_number: Optional[str] = None
    manufacturer: Optional[str] = None
    model: Optional[str] = None
    location: Optional[str] = None
    purchase_date: Optional[str] = None
    last_inspection: Optional[str] = None
    next_inspection: Optional[str] = None
    status: str = "active"
    notes: Optional[str] = None
    
    # ANCHOR: Timestamps
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    def __post_init__(self):
        """Initialize timestamps if not provided"""
        if self.created_at is None:
            self.created_at = datetime.now()
        if self.updated_at is None:
            self.updated_at = datetime.now()

    def update(self, **kwargs) -> None:
        """Update device attributes and refresh timestamp"""
        for key, value in kwargs.items():
            if hasattr(self, key):
                setattr(self, key, value)
        self.updated_at = datetime.now()

    def __repr__(self) -> str:
        """String representation of Device"""
        return (
            f"Device(id={self.id}, name='{self.name}', type={self.type}, "
            f"serial={self.serial_number}, status={self.status})"
        )

    def __eq__(self, other) -> bool:
        """Compare devices by ID and name"""
        if not isinstance(other, Device):
            return False
        return self.id == other.id and self.name == other.name

    def to_dict(self) -> dict:
        """Convert device to dictionary"""
        return {
            'id': self.id,
            'name': self.name,
            'type': self.type,
            'serial_number': self.serial_number,
            'manufacturer': self.manufacturer,
            'model': self.model,
            'location': self.location,
            'purchase_date': self.purchase_date,
            'last_inspection': self.last_inspection,
            'next_inspection': self.next_inspection,
            'status': self.status,
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'Device':
        """Create device from dictionary"""
        return cls(**data)
