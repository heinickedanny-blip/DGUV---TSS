"""USB-C Inspection Domain Model"""
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class USBCInspection:
    """USB-C Inspection Entity"""
    id: Optional[int] = None
    device_id: int = 0
    connector_type: str = "usb-c"
    connector_condition: str = ""
    cable_test: str = ""
    power_delivery: str = ""
    data_transfer: str = ""
    result: str = "pass"
    notes: str = ""
    created_at: Optional[datetime] = None

    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()

    def __repr__(self):
        return f"USBCInspection(id={self.id}, device_id={self.device_id}, result={self.result})"
