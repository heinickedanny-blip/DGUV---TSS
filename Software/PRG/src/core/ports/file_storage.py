"""File Storage Port"""
from abc import ABC, abstractmethod
from typing import Optional

class FileStorage(ABC):
    """Abstract File Storage"""

    @abstractmethod
    def save(self, filename: str, content: bytes) -> str:
        pass

    @abstractmethod
    def load(self, filename: str) -> Optional[bytes]:
        pass

    @abstractmethod
    def delete(self, filename: str) -> bool:
        pass

    @abstractmethod
    def exists(self, filename: str) -> bool:
        pass
