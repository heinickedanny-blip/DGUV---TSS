"""Data Transfer Objects für Device API"""
from src.adapters.web.dto.device_dto import (
    CreateDeviceRequest,
    UpdateDeviceRequest,
    DeviceResponse,
    DeviceStatus,
    create_device_request_from_json,
    update_device_request_from_json
)

__all__ = [
    'CreateDeviceRequest',
    'UpdateDeviceRequest',
    'DeviceResponse',
    'DeviceStatus',
    'create_device_request_from_json',
    'update_device_request_from_json'
]
