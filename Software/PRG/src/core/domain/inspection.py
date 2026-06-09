"""Inspection Domain Model"""
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class Inspection:
    """Inspection Entity"""
    id: Optional[int] = None
    device_id: int = 0
    inspection_type: str = ""
    status: str = "pending"
    result: str = ""
    notes: str = ""
    inspector: str = ""
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()
        if self.updated_at is None:
            self.updated_at = datetime.now()

    def __repr__(self):
        return f"Inspection(id={self.id}, device_id={self.device_id}, status={self.status})"
