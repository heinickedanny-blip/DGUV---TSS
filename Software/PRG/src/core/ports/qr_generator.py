"""QR Generator Port"""
from abc import ABC, abstractmethod
from typing import Optional

class QRGenerator(ABC):
    """Abstract QR Generator"""

    @abstractmethod
    def generate(self, data: str) -> Optional[bytes]:
        pass

    @abstractmethod
    def generate_to_file(self, data: str, filename: str) -> bool:
        pass
