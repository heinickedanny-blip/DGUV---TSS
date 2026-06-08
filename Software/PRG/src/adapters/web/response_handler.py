"""Response Handler für detaillierte Success/Error Messages"""
from typing import Dict, Any, Optional, List
from datetime import datetime
from enum import Enum


class ResponseStatus(str, Enum):
    """Response Status Codes"""
    SUCCESS = "success"
    ERROR = "error"
    VALIDATION_ERROR = "validation_error"
    DUPLICATE_ERROR = "duplicate_error"
    NOT_FOUND = "not_found"
    SERVER_ERROR = "server_error"


class ResponseHandler:
    """Handler für standardisierte API Responses"""
    
    @staticmethod
    def success_create(
        device_id: int,
        customer_device_id: str,
        customer: str,
        name: str,
        device_type: Optional[str] = None,
        additional_fields: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Erfolgreiche Erstellung eines Devices"""
        response = {
            "status": ResponseStatus.SUCCESS.value,
            "timestamp": datetime.now().isoformat(),
            "action": "CREATE",
            "message": f"✅ Device erfolgreich gespeichert",
            "device": {
                "id": device_id,
                "customer_device_id": customer_device_id,
                "customer": customer,
                "name": name,
                "type": device_type
            },
            "details": {
                "saved_fields": {
                    "customer": customer,
                    "customer_device_id": customer_device_id,
                    "name": name,
                    "type": device_type
                }
            }
        }
        
        if additional_fields:
            response["device"].update(additional_fields)
            response["details"]["saved_fields"].update(additional_fields)
        
        return response
    
    @staticmethod
    def success_update(
        device_id: int,
        customer_device_id: str,
        updated_fields: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Erfolgreiche Aktualisierung eines Devices"""
        return {
            "status": ResponseStatus.SUCCESS.value,
            "timestamp": datetime.now().isoformat(),
            "action": "UPDATE",
            "message": f"✅ Device '{customer_device_id}' erfolgreich aktualisiert",
            "device": {
                "id": device_id,
                "customer_device_id": customer_device_id
            },
            "details": {
                "updated_fields": updated_fields,
                "field_count": len(updated_fields)
            }
        }
    
    @staticmethod
    def success_delete(customer_device_id: str) -> Dict[str, Any]:
        """Erfolgreiche Löschung eines Devices"""
        return {
            "status": ResponseStatus.SUCCESS.value,
            "timestamp": datetime.now().isoformat(),
            "action": "DELETE",
            "message": f"✅ Device '{customer_device_id}' erfolgreich gelöscht"
        }
    
    @staticmethod
    def error_validation(errors: List[str]) -> Dict[str, Any]:
        """Validierungsfehler"""
        return {
            "status": ResponseStatus.VALIDATION_ERROR.value,
            "timestamp": datetime.now().isoformat(),
            "action": "VALIDATION",
            "message": f"❌ Validierungsfehler: {len(errors)} Problem(e) gefunden",
            "errors": errors,
            "error_count": len(errors),
            "details": {
                "reason": "Die eingegebenen Daten erfüllen nicht die Anforderungen",
                "hint": "Bitte überprüfen Sie die Fehler oben und versuchen Sie es erneut"
            }
        }
    
    @staticmethod
    def error_duplicate(field_name: str, field_value: str, existing_id: Optional[int] = None) -> Dict[str, Any]:
        """Duplikat-Fehler"""
        return {
            "status": ResponseStatus.DUPLICATE_ERROR.value,
            "timestamp": datetime.now().isoformat(),
            "action": "CREATE/UPDATE",
            "message": f"❌ Duplikat: {field_name} '{field_value}' existiert bereits",
            "error": f"Duplicate entry '{field_value}' for key '{field_name}'",
            "details": {
                "conflicting_field": field_name,
                "conflicting_value": field_value,
                "existing_id": existing_id,
                "reason": f"Ein Device mit {field_name} '{field_value}' existiert bereits",
                "hint": f"Verwenden Sie einen eindeutigen {field_name} oder aktualisieren Sie das bestehende Device"
            }
        }
    
    @staticmethod
    def error_not_found(device_id: str) -> Dict[str, Any]:
        """Device nicht gefunden"""
        return {
            "status": ResponseStatus.NOT_FOUND.value,
            "timestamp": datetime.now().isoformat(),
            "action": "GET/UPDATE/DELETE",
            "message": f"❌ Device nicht gefunden: '{device_id}'",
            "error": f"Device with ID '{device_id}' not found",
            "details": {
                "searched_id": device_id,
                "reason": "Das gesuchte Device existiert nicht in der Datenbank",
                "hint": "Überprüfen Sie die Device-ID und versuchen Sie es erneut"
            }
        }
    
    @staticmethod
    def error_server(error_message: str, error_type: Optional[str] = None) -> Dict[str, Any]:
        """Server-Fehler"""
        return {
            "status": ResponseStatus.SERVER_ERROR.value,
            "timestamp": datetime.now().isoformat(),
            "action": "UNKNOWN",
            "message": f"❌ Server-Fehler: {error_message}",
            "error": error_message,
            "error_type": error_type,
            "details": {
                "reason": "Ein unerwarteter Fehler ist aufgetreten",
                "hint": "Bitte kontaktieren Sie den Administrator oder versuchen Sie es später erneut"
            }
        }
    
    @staticmethod
    def error_database_connection() -> Dict[str, Any]:
        """Datenbankverbindungsfehler"""
        return {
            "status": ResponseStatus.SERVER_ERROR.value,
            "timestamp": datetime.now().isoformat(),
            "action": "DATABASE",
            "message": "❌ Datenbankverbindungsfehler",
            "error": "Cannot connect to database",
            "details": {
                "reason": "Die Verbindung zur Datenbank konnte nicht hergestellt werden",
                "hint": "Überprüfen Sie, ob der MySQL-Server läuft und erreichbar ist"
            }
        }
    
    @staticmethod
    def error_missing_required_field(field_name: str) -> Dict[str, Any]:
        """Erforderliches Feld fehlt"""
        return {
            "status": ResponseStatus.VALIDATION_ERROR.value,
            "timestamp": datetime.now().isoformat(),
            "action": "VALIDATION",
            "message": f"❌ Erforderliches Feld fehlt: '{field_name}'",
            "error": f"Required field '{field_name}' is missing",
            "details": {
                "missing_field": field_name,
                "reason": f"Das Feld '{field_name}' ist erforderlich und darf nicht leer sein",
                "hint": f"Geben Sie einen Wert für '{field_name}' ein"
            }
        }
    
    @staticmethod
    def format_error_message(db_error: str) -> Dict[str, Any]:
        """Formatiere Datenbankfehler in lesbare Meldung"""
        
        # Duplicate Entry Fehler
        if "Duplicate entry" in db_error:
            parts = db_error.split("'")
            if len(parts) >= 4:
                value = parts[1]
                key = parts[3] if len(parts) > 3 else "unknown"
                return ResponseHandler.error_duplicate(key, value)
        
        # Foreign Key Fehler
        if "foreign key constraint" in db_error.lower():
            return {
                "status": ResponseStatus.ERROR.value,
                "timestamp": datetime.now().isoformat(),
                "message": "❌ Referenzfehler: Bezogenes Datensatz existiert nicht",
                "error": db_error,
                "details": {
                    "reason": "Das referenzierte Datensatz existiert nicht",
                    "hint": "Überprüfen Sie die Referenzen und versuchen Sie es erneut"
                }
            }
        
        # Timeout Fehler
        if "timeout" in db_error.lower():
            return {
                "status": ResponseStatus.SERVER_ERROR.value,
                "timestamp": datetime.now().isoformat(),
                "message": "❌ Datenbankzugriff Timeout",
                "error": db_error,
                "details": {
                    "reason": "Die Datenbankabfrage hat zu lange gedauert",
                    "hint": "Versuchen Sie es in Kürze erneut"
                }
            }
        
        # Generischer Fehler
        return ResponseHandler.error_server(db_error, "DatabaseError")


def create_success_response(
    status_code: int,
    device_id: int,
    customer_device_id: str,
    customer: str,
    name: str,
    device_type: Optional[str] = None,
    additional_fields: Optional[Dict[str, Any]] = None
) -> tuple:
    """Erstelle erfolgreiche Response"""
    response = ResponseHandler.success_create(
        device_id=device_id,
        customer_device_id=customer_device_id,
        customer=customer,
        name=name,
        device_type=device_type,
        additional_fields=additional_fields
    )
    return response, status_code


def create_error_response(
    status_code: int,
    error_type: str,
    error_data: Optional[Dict[str, Any]] = None
) -> tuple:
    """Erstelle Error Response"""
    
    if error_type == "validation":
        errors = error_data.get("errors", []) if error_data else []
        response = ResponseHandler.error_validation(errors)
    elif error_type == "duplicate":
        field = error_data.get("field", "unknown") if error_data else "unknown"
        value = error_data.get("value", "") if error_data else ""
        response = ResponseHandler.error_duplicate(field, value)
    elif error_type == "not_found":
        device_id = error_data.get("device_id", "unknown") if error_data else "unknown"
        response = ResponseHandler.error_not_found(device_id)
    elif error_type == "database_connection":
        response = ResponseHandler.error_database_connection()
    else:
        message = error_data.get("message", "Unknown error") if error_data else "Unknown error"
        response = ResponseHandler.error_server(message)
    
    return response, status_code
