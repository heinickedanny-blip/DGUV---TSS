"""Device Routes Adapter - FIXED"""
from flask import Blueprint, request, jsonify
from src.core.domain.device import Device
from src.config.dependencies import container

device_bp = Blueprint('devices', __name__, url_prefix='/api/devices')

@device_bp.route('', methods=['GET'])
def list_devices():
    try:
        devices = container.list_devices_usecase.execute()
        return jsonify([{
            'id': d.id,
            'name': d.name,
            'serial_number': d.serial_number,
            'device_type': d.device_type
        } for d in devices])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('/<int:device_id>', methods=['GET'])
def get_device(device_id: int):
    try:
        device = container.get_device_usecase.execute(device_id)
        if device:
            return jsonify({
                'id': device.id,
                'name': device.name,
                'serial_number': device.serial_number,
                'device_type': device.device_type,
                'manufacturer': device.manufacturer,
                'model': device.model,
                'description': device.description
            })
        return jsonify({'error': 'Device not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('', methods=['POST'])
def create_device():
    try:
        data = request.json
        device = Device(
            name=data.get('name'),
            device_type=data.get('device_type'),
            serial_number=data.get('serial_number'),
            manufacturer=data.get('manufacturer'),
            model=data.get('model'),
            description=data.get('description')
        )
        created = container.create_device_usecase.execute(device)
        return jsonify({'id': created.id, 'message': 'Device created'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('/<int:device_id>', methods=['PUT'])
def update_device(device_id: int):
    try:
        data = request.json
        device = Device(
            id=device_id,
            name=data.get('name'),
            device_type=data.get('device_type'),
            serial_number=data.get('serial_number'),
            manufacturer=data.get('manufacturer'),
            model=data.get('model'),
            description=data.get('description')
        )
        container.update_device_usecase.execute(device)
        return jsonify({'message': 'Device updated'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@device_bp.route('/<int:device_id>', methods=['DELETE'])
def delete_device(device_id: int):
    try:
        container.delete_device_usecase.execute(device_id)
        return jsonify({'message': 'Device deleted'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
