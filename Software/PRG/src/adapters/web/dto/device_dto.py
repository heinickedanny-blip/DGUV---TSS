"""
Device DTOs (Data Transfer Objects) für Request/Response Validierung - KORRIGIERTE VERSION
Behebt varchar/string ID-Probleme durch explizite Validierung
"""

from dataclasses import dataclass, field
from typing import Optional
from datetime import date
from enum import Enum


class DeviceStatus(str, Enum):
    """Valid device statuses"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    MAINTENANCE = "maintenance"
    RETIRED = "retired"


@dataclass
class CreateDeviceRequest:
    """DTO für Device-Erstellung (POST)"""
    
    customer: str
    name: str
    type: str  # ✅ FIX: Mache erforderlich (war Optional)
    customer_device_id: Optional[str] = None  # ✅ Optional - wird nach dem Speichern generiert
    serial_number: Optional[str] = None
    manufacturer: Optional[str] = None
    location: Optional[str] = None
    purchase_date: Optional[str] = None
    status: str = "active"
    notes: Optional[str] = None
    
    def validate(self) -> list:
        """Validiere Request-Daten"""
        errors = []
        
        # Pflichtfelder
        if not self.customer or not self.customer.strip():
            errors.append("customer is required and cannot be empty")
        
        if not self.name or not self.name.strip():
            errors.append("name is required and cannot be empty")
        
        # ✅ FIX: Validiere type als erforderlich
        if not self.type or not self.type.strip():
            errors.append("type is required and cannot be empty")
        
        # Längenbeschränkungen (VARCHAR(255))
        if self.customer and len(self.customer) > 255:
            errors.append(f"customer must not exceed 255 characters (got {len(self.customer)})")
        
        if self.name and len(self.name) > 255:
            errors.append(f"name must not exceed 255 characters (got {len(self.name)})")
        
        if self.type and len(self.type) > 255:
            errors.append(f"type must not exceed 255 characters (got {len(self.type)})")
        
        if self.customer_device_id and len(self.customer_device_id) > 255:
            errors.append(f"customer_device_id must not exceed 255 characters (got {len(self.customer_device_id)})")
        
        if self.serial_number and len(self.serial_number) > 255:
            errors.append(f"serial_number must not exceed 255 characters (got {len(self.serial_number)})")
        
        if self.manufacturer and len(self.manufacturer) > 255:
            errors.append(f"manufacturer must not exceed 255 characters (got {len(self.manufacturer)})")
        
        if self.location and len(self.location) > 255:
            errors.append(f"location must not exceed 255 characters (got {len(self.location)})")
        
        # ✅ FIX: Validiere notes Längenbeschränkung
        if self.notes and len(self.notes) > 1000:
            errors.append(f"notes must not exceed 1000 characters (got {len(self.notes)})")
        
        # Status Validierung
        valid_statuses = [s.value for s in DeviceStatus]
        if self.status not in valid_statuses:
            errors.append(f"status must be one of {valid_statuses}, got '{self.status}'")
        
        # ✅ FIX: Bessere Datums-Validierung
        if self.purchase_date:
            purchase_date_str = self.purchase_date.strip() if isinstance(self.purchase_date, str) else str(self.purchase_date)
            if purchase_date_str:  # Nur wenn nicht leer nach Strip
                try:
                    date.fromisoformat(purchase_date_str)
                except (ValueError, AttributeError, TypeError) as e:
                    errors.append(f"purchase_date must be in ISO format (YYYY-MM-DD), got '{self.purchase_date}'")
        
        # customer_device_id wird nach dem Speichern automatisch generiert, daher keine Validierung nötig
        
        return errors
    

    
    def sanitize(self):
        """Sanitize string fields"""
        if self.customer:
            self.customer = self.customer.strip() if self.customer else None
        if self.name:
            self.name = self.name.strip() if self.name else None
        if self.type:
            self.type = self.type.strip() if self.type else None
        if self.customer_device_id:
            self.customer_device_id = self.customer_device_id.strip() if self.customer_device_id else None
        
        # ✅ FIX: Explizite Behandlung von leeren Strings für optional fields
        if self.serial_number == "":
            self.serial_number = None
        elif self.serial_number:
            self.serial_number = self.serial_number.strip()
        
        if self.manufacturer == "":
            self.manufacturer = None
        elif self.manufacturer:
            self.manufacturer = self.manufacturer.strip()
        
        if self.location == "":
            self.location = None
        elif self.location:
            self.location = self.location.strip()
        
        if self.purchase_date == "":
            self.purchase_date = None
        elif self.purchase_date:
            self.purchase_date = self.purchase_date.strip()
        
        if self.notes == "":
            self.notes = None
        elif self.notes:
            self.notes = self.notes.strip()


@dataclass
class UpdateDeviceRequest:
    """DTO für Device-Aktualisierung (PUT)"""
    
    customer: Optional[str] = None
    name: Optional[str] = None
    type: Optional[str] = None
    serial_number: Optional[str] = None
    manufacturer: Optional[str] = None
    location: Optional[str] = None
    purchase_date: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    
    def validate(self) -> list:
        """Validiere Request-Daten"""
        errors = []
        
        # Längenbeschränkungen
        if self.customer and len(self.customer) > 255:
            errors.append(f"customer must not exceed 255 characters")
        
        if self.name and len(self.name) > 255:
            errors.append(f"name must not exceed 255 characters")
        
        if self.type and len(self.type) > 255:
            errors.append(f"type must not exceed 255 characters")
        
        if self.serial_number and len(self.serial_number) > 255:
            errors.append(f"serial_number must not exceed 255 characters")
        
        if self.manufacturer and len(self.manufacturer) > 255:
            errors.append(f"manufacturer must not exceed 255 characters")
        
        if self.location and len(self.location) > 255:
            errors.append(f"location must not exceed 255 characters")
        
        # ✅ FIX: Validiere notes Längenbeschränkung
        if self.notes and len(self.notes) > 1000:
            errors.append(f"notes must not exceed 1000 characters")
        
        # Status Validierung
        if self.status:
            valid_statuses = [s.value for s in DeviceStatus]
            if self.status not in valid_statuses:
                errors.append(f"status must be one of {valid_statuses}")
        
        # ✅ FIX: Bessere Datums-Validierung
        if self.purchase_date:
            purchase_date_str = self.purchase_date.strip() if isinstance(self.purchase_date, str) else str(self.purchase_date)
            if purchase_date_str:
                try:
                    date.fromisoformat(purchase_date_str)
                except (ValueError, AttributeError, TypeError) as e:
                    errors.append(f"purchase_date must be in ISO format (YYYY-MM-DD)")
        
        return errors
    
    def sanitize(self):
        """Sanitize string fields"""
        if self.customer:
            self.customer = self.customer.strip() if self.customer else None
        if self.name:
            self.name = self.name.strip() if self.name else None
        if self.type:
            self.type = self.type.strip() if self.type else None
        
        # ✅ FIX: Explizite Behandlung von leeren Strings
        if self.serial_number == "":
            self.serial_number = None
        elif self.serial_number:
            self.serial_number = self.serial_number.strip()
        
        if self.manufacturer == "":
            self.manufacturer = None
        elif self.manufacturer:
            self.manufacturer = self.manufacturer.strip()
        
        if self.location == "":
            self.location = None
        elif self.location:
            self.location = self.location.strip()
        
        if self.purchase_date == "":
            self.purchase_date = None
        elif self.purchase_date:
            self.purchase_date = self.purchase_date.strip()
        
        if self.notes == "":
            self.notes = None
        elif self.notes:
            self.notes = self.notes.strip()


@dataclass
class DeviceResponse:
    """DTO für Device-Response"""
    
    id: int
    customer: str
    customer_device_id: str
    name: str
    type: Optional[str] = None
    serial_number: Optional[str] = None
    manufacturer: Optional[str] = None
    location: Optional[str] = None
    purchase_date: Optional[str] = None
    last_inspection: Optional[str] = None
    next_inspection: Optional[str] = None
    status: str = "active"
    notes: Optional[str] = None
    
    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            'id': self.id,
            'customer': self.customer,
            'customer_device_id': self.customer_device_id,
            'name': self.name,
            'type': self.type,
            'serial_number': self.serial_number,
            'manufacturer': self.manufacturer,
            'location': self.location,
            'purchase_date': self.purchase_date,
            'last_inspection': self.last_inspection,
            'next_inspection': self.next_inspection,
            'status': self.status,
            'notes': self.notes
        }


def create_device_request_from_json(data: dict) -> tuple[CreateDeviceRequest, list]:
    """
    Create CreateDeviceRequest from JSON data with validation
    
    Returns:
        (request, errors) - request is None if validation failed
    """
    try:
        request = CreateDeviceRequest(
            customer=data.get('customer', ''),
            name=data.get('name', ''),
            type=data.get('type', ''),  # ✅ FIX: Mache erforderlich
            customer_device_id=data.get('customer_device_id'),
            serial_number=data.get('serial_number'),
            manufacturer=data.get('manufacturer'),
            location=data.get('location'),
            purchase_date=data.get('purchase_date'),
            status=data.get('status', 'active'),
            notes=data.get('notes')
        )
        
        # Sanitize
        request.sanitize()
        
        # Validate
        errors = request.validate()
        
        return request, errors
    except Exception as e:
        return None, [f"Error parsing request: {str(e)}"]


def update_device_request_from_json(data: dict) -> tuple[UpdateDeviceRequest, list]:
    """
    Create UpdateDeviceRequest from JSON data with validation
    
    Returns:
        (request, errors) - request is None if validation failed
    """
    try:
        request = UpdateDeviceRequest(
            customer=data.get('customer'),
            name=data.get('name'),
            type=data.get('type'),
            serial_number=data.get('serial_number'),
            manufacturer=data.get('manufacturer'),
            location=data.get('location'),
            purchase_date=data.get('purchase_date'),
            status=data.get('status'),
            notes=data.get('notes')
        )
        
        # Sanitize
        request.sanitize()
        
        # Validate
        errors = request.validate()
        
        return request, errors
    except Exception as e:
        return None, [f"Error parsing request: {str(e)}"]
