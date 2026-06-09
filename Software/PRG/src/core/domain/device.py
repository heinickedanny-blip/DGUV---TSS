"""Device Entity - Hexagonal Architecture mit customer_device_id, DGUV3-Prüfwerten und USB-Kabel Feldern"""
from dataclasses import dataclass
from typing import Optional
from datetime import date




@dataclass
class Device:
    """Device Entity - Hexagonal Architecture
    
    Attributes:
        id: Numerische Datenbank-ID (auto-increment)
        customer: Kundenname (z.B. "Parloa")
        customer_device_id: Formatierte Kunden-ID (z.B. "Parloa-00001")
        name: Gerätename
        type: Gerätetyp (z.B. "Elektrowerkzeug", "USB-Kabel")
        serial_number: Seriennummer (UNIQUE)
        manufacturer: Hersteller
        model: Modell
        location: Standort
        purchase_date: Kaufdatum
        last_inspection: Letzte Inspektion
        next_inspection: Nächste Inspektion
        status: Status (active, inactive, maintenance, retired)
        qr_code: QR-Code als Bytes (PNG/Base64)
        notes: Notizen
        
        # DGUV3 Prüfwerte
        r_pe: Schutzleiterwiderstand in Ohm (Grenzwert: < 0,3 Ω)
        r_iso: Isolationswiderstand in MegaOhm (Grenzwert: > 1,0 MΩ)
        i_pe: Schutzleiterstrom in mA (Grenzwert: < 3,5 mA)
        i_b: Berührungsstrom in mA (Grenzwert: < 0,5 mA)
        
        # USB-Kabel Inspektionsfelder (NEU)
        cable_type: Kabeltyp (USB-C, Lightning, Micro-USB, etc.)
        test_result: Testergebnis (bestanden, nicht_bestanden, verloren, nicht_vorhanden)
        internal_resistance: Innenwiderstand in Ohm
        emarker_active: eMarker Status (nur USB-C)
        inspection_notes: Inspektionsnotizen
    """
    
    # ANCHOR: Required Fields
    id: Optional[int] = None
    name: str = ""
    customer: Optional[str] = None
    customer_device_id: Optional[str] = None
    
    # ANCHOR: Optional Fields
    type: Optional[str] = None
    serial_number: Optional[str] = None
    manufacturer: Optional[str] = None
    model: Optional[str] = None
    location: Optional[str] = None
    purchase_date: Optional[date] = None
    last_inspection: Optional[date] = None
    next_inspection: Optional[date] = None
    status: str = "active"
    qr_code: Optional[bytes] = None
    notes: Optional[str] = None
    
    # ANCHOR: DGUV3 Prüfwerte
    r_pe: Optional[float] = None      # Schutzleiterwiderstand in Ohm
    r_iso: Optional[float] = None     # Isolationswiderstand in MegaOhm
    i_pe: Optional[float] = None      # Schutzleiterstrom in mA
    i_b: Optional[float] = None       # Berührungsstrom in mA
    
    # ANCHOR: USB-Kabel Inspektionsfelder (NEU)
    cable_type: Optional[str] = None              # USB-C, Lightning, Micro-USB, etc.
    test_result: Optional[str] = None             # bestanden, nicht_bestanden, verloren, nicht_vorhanden
    internal_resistance: Optional[float] = None   # Innenwiderstand in Ohm
    emarker_active: Optional[bool] = None         # eMarker Status (nur USB-C)
    inspection_notes: Optional[str] = None        # Inspektionsnotizen
    
    def __post_init__(self):
        """Validate device after initialization"""
        if not self.name:
            raise ValueError("Device name is required")
        if not self.customer:
            raise ValueError("Customer is required")
    
    def __str__(self) -> str:
        """String representation"""
        return f"Device({self.customer_device_id}: {self.name})"
    
    def __repr__(self) -> str:
        """Detailed representation"""
        return (
            f"Device(id={self.id}, customer_device_id={self.customer_device_id}, "
            f"name={self.name}, type={self.type}, status={self.status})"
        )
    
    def is_active(self) -> bool:
        """Check if device is active"""
        return self.status == "active"
    
    def is_due_for_inspection(self) -> bool:
        """Check if device is due for inspection"""
        if not self.next_inspection:
            return True
        from datetime import datetime
        return datetime.now().date() >= self.next_inspection
    
    # ANCHOR: DGUV3 Grenzwertprüfungen
    def is_r_pe_within_limit(self) -> bool:
        """Prüft ob Schutzleiterwiderstand innerhalb Grenzwert (< 0,3 Ω)"""
        return self.r_pe is not None and self.r_pe < 0.3
    
    def is_r_iso_within_limit(self) -> bool:
        """Prüft ob Isolationswiderstand innerhalb Grenzwert (> 1,0 MΩ)"""
        return self.r_iso is not None and self.r_iso > 1.0
    
    def is_i_pe_within_limit(self) -> bool:
        """Prüft ob Schutzleiterstrom innerhalb Grenzwert (< 3,5 mA)"""
        return self.i_pe is not None and self.i_pe < 3.5
    
    def is_i_b_within_limit(self) -> bool:
        """Prüft ob Berührungsstrom innerhalb Grenzwert (< 0,5 mA)"""
        return self.i_b is not None and self.i_b < 0.5
    
    def all_dguv3_tests_passed(self) -> bool:
        """Prüft ob alle DGUV3-Prüfwerte vorhanden und innerhalb der Grenzwerte sind"""
        if self.r_pe is None or self.r_iso is None or self.i_pe is None or self.i_b is None:
            return False
        return (self.is_r_pe_within_limit() and 
                self.is_r_iso_within_limit() and 
                self.is_i_pe_within_limit() and 
                self.is_i_b_within_limit())
    
    # ANCHOR: USB-Kabel Prüfungen (NEU)
    def is_usb_cable(self) -> bool:
        """Prüft ob es sich um ein USB-Kabel handelt"""
        return self.type == "USB-Kabel"
    
    def usb_test_passed(self) -> bool:
        """Prüft ob USB-Kabel Test bestanden wurde"""
        return self.test_result == "bestanden"
    
    def to_dict(self) -> dict:
        """Convert device to dictionary"""
        return {
            'id': self.id,
            'customer': self.customer,
            'customer_device_id': self.customer_device_id,
            'name': self.name,
            'type': self.type,
            'serial_number': self.serial_number,
            'manufacturer': self.manufacturer,
            'model': self.model,
            'location': self.location,
            'purchase_date': str(self.purchase_date) if self.purchase_date else None,
            'last_inspection': str(self.last_inspection) if self.last_inspection else None,
            'next_inspection': str(self.next_inspection) if self.next_inspection else None,
            'status': self.status,
            'notes': self.notes,
            # DGUV3 Prüfwerte
            'r_pe': self.r_pe,
            'r_iso': self.r_iso,
            'i_pe': self.i_pe,
            'i_b': self.i_b,
            # USB-Kabel Felder (NEU)
            'cable_type': self.cable_type,
            'test_result': self.test_result,
            'internal_resistance': self.internal_resistance,
            'emarker_active': self.emarker_active,
            'inspection_notes': self.inspection_notes
        }
