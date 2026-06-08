"""Device Routes Adapter - mit customer_device_id und Input-Validierung"""
from flask import Blueprint, request, jsonify
from src.core.domain.device import Device
from src.config.dependencies import container
from src.adapters.web.dto.device_dto import (
    create_device_request_from_json,
    update_device_request_from_json
)
from datetime import datetime

device_bp = Blueprint('devices', __name__, url_prefix='/api/devices')


def _clean_date_field(value):
    """Convert empty string to None for date fields with validation"""
    if not value or (isinstance(value, str) and not value.strip()):
        return None
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value).date()
        except (ValueError, AttributeError):
            return None
    return value


@device_bp.route('', methods=['GET'])
def list_devices():
    try:
        devices = container.list_devices_usecase.execute()
        return jsonify({
            'success': True,
            'data': [{
                'id': d.id,
                'customer': d.customer,
                'customer_device_id': d.customer_device_id,
                'name': d.name,
                'type': d.type,
                'location': d.location,
                'manufacturer': d.manufacturer,
                'serial_number': d.serial_number,
                'status': d.status
            } for d in devices]
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@device_bp.route('/<customer_device_id>', methods=['GET'])
def get_device(customer_device_id: str):
    try:
        # Sanitize input
        customer_device_id = customer_device_id.strip() if customer_device_id else None
        
        if not customer_device_id:
            return jsonify({
                'success': False,
                'error': 'customer_device_id cannot be empty'
            }), 400
        
        device = container.device_repository.get_by_customer_device_id(customer_device_id)
        if device:
            return jsonify({
                'success': True,
                'device': {
                    'id': device.id,
                    'customer': device.customer,
                    'customer_device_id': device.customer_device_id,
                    'name': device.name,
                    'type': device.type,
                    'location': device.location,
                    'manufacturer': device.manufacturer,
                    'serial_number': device.serial_number,
                    'purchase_date': str(device.purchase_date) if device.purchase_date else None,
                    'last_inspection': str(device.last_inspection) if device.last_inspection else None,
                    'next_inspection': str(device.next_inspection) if device.next_inspection else None,
                    'status': device.status,
                    'notes': device.notes
                }
            })
        return jsonify({'success': False, 'error': 'Device not found'}), 404
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@device_bp.route('/next-id', methods=['GET'])
def get_next_customer_device_id():
    """Get next customer device ID (e.g., Parloa-00001)"""
    try:
        customer = request.args.get('customer', '').strip()
        if not customer:
            return jsonify({'success': False, 'error': 'Customer parameter required'}), 400
        
        next_id = container.device_repository.get_next_customer_device_id(customer)
        return jsonify({
            'success': True,
            'next_id': next_id
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@device_bp.route('', methods=['POST'])
def create_device():
    try:
        data = request.json or {}
        
        # Validate request with DTOs
        create_request, errors = create_device_request_from_json(data)
        if errors:
            return jsonify({
                'success': False,
                'errors': errors
            }), 400
        
        device = Device(
            customer=create_request.customer,
            customer_device_id=create_request.customer_device_id,
            name=create_request.name,
            type=create_request.type,
            location=create_request.location,
            manufacturer=create_request.manufacturer,
            serial_number=create_request.serial_number,
            purchase_date=_clean_date_field(create_request.purchase_date),
            status=create_request.status,
            notes=create_request.notes
        )
        created = container.create_device_usecase.execute(device)
        return jsonify({
            'success': True,
            'device': {
                'id': created.id,
                'customer_device_id': created.customer_device_id,
                'customer': created.customer,
                'name': created.name,
                'type': created.type
            },
            'message': 'Device created successfully'
        }), 201
    except ValueError as e:
        return jsonify({'success': False, 'error': str(e)}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@device_bp.route('/<customer_device_id>', methods=['PUT'])
def update_device(customer_device_id: str):
    try:
        # Sanitize customer_device_id
        customer_device_id = customer_device_id.strip() if customer_device_id else None
        if not customer_device_id:
            return jsonify({
                'success': False,
                'error': 'customer_device_id cannot be empty'
            }), 400
        
        data = request.json or {}
        
        # Validate request with DTOs
        update_request, errors = update_device_request_from_json(data)
        if errors:
            return jsonify({
                'success': False,
                'errors': errors
            }), 400
        
        device = Device(
            customer_device_id=customer_device_id,
            customer=update_request.customer,
            name=update_request.name,
            type=update_request.type,
            location=update_request.location,
            manufacturer=update_request.manufacturer,
            serial_number=update_request.serial_number,
            purchase_date=_clean_date_field(update_request.purchase_date),
            status=update_request.status or 'active',
            notes=update_request.notes
        )
        updated = container.update_device_usecase.execute(device)
        return jsonify({
            'success': True,
            'device': {
                'id': updated.id,
                'customer_device_id': updated.customer_device_id,
                'customer': updated.customer,
                'name': updated.name,
                'type': updated.type
            },
            'message': 'Device updated successfully'
        })
    except ValueError as e:
        return jsonify({'success': False, 'error': str(e)}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@device_bp.route('/<customer_device_id>', methods=['DELETE'])
def delete_device(customer_device_id: str):
    try:
        # Sanitize customer_device_id
        customer_device_id = customer_device_id.strip() if customer_device_id else None
        if not customer_device_id:
            return jsonify({
                'success': False,
                'error': 'customer_device_id cannot be empty'
            }), 400
        
        container.delete_device_usecase.execute(customer_device_id)
        return jsonify({
            'success': True,
            'message': 'Device deleted successfully'
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@device_bp.route('/health', methods=['GET'])
def health_check():
    """Überprüft den Gesundheitsstatus der Anwendung"""
    try:
        from src.adapters.services.health_check_service import HealthCheckService
        from src.adapters.services.logger_service import LoggerService
        
        logger = LoggerService()
        health = HealthCheckService()
        
        # Führe Health Check aus
        health_status = health.full_health_check()
        
        # Logge den Health Check
        logger.log_health_check(
            status=health_status.get('overall_status'),
            database_status=health_status.get('database', {}).get('status'),
            response_time_ms=health_status.get('database', {}).get('response_time_ms')
        )
        
        # Gebe Status zurück
        status_code = 200 if health_status.get('overall_status') == 'healthy' else 503
        return jsonify(health_status), status_code
    except Exception as e:
        return jsonify({
            'overall_status': 'unhealthy',
            'error': str(e)
        }), 503
