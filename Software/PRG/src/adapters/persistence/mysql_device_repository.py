"""MySQL Device Repository - Hexagonal Architecture Pattern mit customer_device_id und USB-Kabel Feldern"""
import time
from typing import List, Optional
from src.core.domain.device import Device
from src.adapters.services.logger_service import LoggerService
import mysql.connector
from mysql.connector import Error


class MySQLDeviceRepository:
    """MySQL implementation of Device Repository"""
    
    def __init__(self, host: str, port: int, user: str, password: str, database: str):
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.database = database
        self.logger = LoggerService()
        self.logger.info("MySQLDeviceRepository initialized", host=host)
    
    def _get_connection(self):
        """Get MySQL connection"""
        try:
            conn = mysql.connector.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                database=self.database
            )
            return conn
        except Error as e:
            self.logger.error(f"Database connection failed: {e}")
            raise
    
    def create(self, device: Device) -> Device:
        """Create a new device"""
        try:
            start_time = time.time()
            conn = self._get_connection()
            cursor = conn.cursor(dictionary=True)
            
            # Generate customer_device_id if not provided
            if not device.customer_device_id and device.customer:
                device.customer_device_id = self._generate_customer_device_id(device.customer)
            
            # FIX: Konvertiere leere Strings zu NULL für serial_number
            # Dies verhindert Duplicate-Fehler bei leeren Seriennummern
            if device.serial_number == "" or device.serial_number is None:
                device.serial_number = None
            
            # FIX: Konvertiere leere Strings zu NULL für purchase_date
            if device.purchase_date == "":
                device.purchase_date = None
            
            query = """
                INSERT INTO devices 
                (customer, customer_device_id, name, type, location, manufacturer, serial_number, 
                 purchase_date, last_inspection, next_inspection, status, notes, 
                 r_pe, r_iso, i_pe, i_b,
                 cable_type, test_result, internal_resistance, emarker_active, inspection_notes)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            values = (
                device.customer,
                device.customer_device_id,
                device.name,
                device.type,
                device.location,
                device.manufacturer,
                device.serial_number,  # Jetzt NULL statt leerer String
                device.purchase_date,  # Jetzt NULL statt leerer String
                device.last_inspection,  # Prüfdatum
                device.next_inspection,  # Nächste Prüfung
                device.status or 'active',
                device.notes,
                device.r_pe,
                device.r_iso,
                device.i_pe,
                device.i_b,
                # USB-Kabel Felder (NEU)
                device.cable_type,
                device.test_result,
                device.internal_resistance,
                device.emarker_active,
                device.inspection_notes
            )
            
            cursor.execute(query, values)
            conn.commit()
            
            # Get the inserted ID
            device.id = cursor.lastrowid
            
            duration_ms = (time.time() - start_time) * 1000
            self.logger.log_db_operation(
                operation="INSERT",
                table="devices",
                result="success",
                duration_ms=duration_ms,
                customer_device_id=device.customer_device_id,
                customer=device.customer
            )
            
            cursor.close()
            conn.close()
            
            return device
        except Exception as e:
            self.logger.error(f"Failed to create device: {e}", exception=e)
            raise
    
    def get_by_id(self, device_id: int) -> Optional[Device]:
        """Get device by ID"""
        try:
            start_time = time.time()
            conn = self._get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = "SELECT * FROM devices WHERE id = %s"
            cursor.execute(query, (device_id,))
            result = cursor.fetchone()
            
            duration_ms = (time.time() - start_time) * 1000
            self.logger.log_db_operation(
                operation="SELECT",
                table="devices",
                result="success",
                duration_ms=duration_ms
            )
            
            cursor.close()
            conn.close()
            
            if result:
                return self._map_to_device(result)
            return None
        except Exception as e:
            self.logger.error(f"Failed to get device by id: {e}", exception=e)
            raise
    
    def get_by_customer_device_id(self, customer_device_id: str) -> Optional[Device]:
        """Get device by customer_device_id (e.g. Parloa-00001)"""
        try:
            start_time = time.time()
            conn = self._get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = "SELECT * FROM devices WHERE customer_device_id = %s"
            cursor.execute(query, (customer_device_id,))
            result = cursor.fetchone()
            
            duration_ms = (time.time() - start_time) * 1000
            self.logger.log_db_operation(
                operation="SELECT",
                table="devices",
                result="success",
                duration_ms=duration_ms
            )
            
            cursor.close()
            conn.close()
            
            if result:
                return self._map_to_device(result)
            return None
        except Exception as e:
            self.logger.error(f"Failed to get device by customer_device_id: {e}", exception=e)
            raise
    
    def get_all(self) -> List[Device]:
        """Get all devices"""
        try:
            start_time = time.time()
            conn = self._get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = "SELECT * FROM devices ORDER BY id DESC"
            cursor.execute(query)
            results = cursor.fetchall()
            
            duration_ms = (time.time() - start_time) * 1000
            self.logger.log_db_operation(
                operation="SELECT",
                table="devices",
                result="success",
                duration_ms=duration_ms
            )
            
            cursor.close()
            conn.close()
            
            return [self._map_to_device(row) for row in results]
        except Exception as e:
            self.logger.error(f"Failed to get all devices: {e}", exception=e)
            raise
    
    def update(self, device: Device) -> Device:
        """Update an existing device"""
        try:
            start_time = time.time()
            conn = self._get_connection()
            cursor = conn.cursor(dictionary=True)
            
            # FIX: Konvertiere leere Strings zu NULL
            if device.serial_number == "":
                device.serial_number = None
            if device.purchase_date == "":
                device.purchase_date = None
            
            query = """
                UPDATE devices 
                SET customer = %s, name = %s, type = %s, location = %s, 
                    manufacturer = %s, serial_number = %s, purchase_date = %s, 
                    status = %s, notes = %s,
                    cable_type = %s, test_result = %s, internal_resistance = %s,
                    emarker_active = %s, inspection_notes = %s
                WHERE customer_device_id = %s
            """
            
            values = (
                device.customer,
                device.name,
                device.type,
                device.location,
                device.manufacturer,
                device.serial_number,
                device.purchase_date,
                device.status or 'active',
                device.notes,
                # USB-Kabel Felder (NEU)
                device.cable_type,
                device.test_result,
                device.internal_resistance,
                device.emarker_active,
                device.inspection_notes,
                device.customer_device_id
            )
            
            cursor.execute(query, values)
            conn.commit()
            
            duration_ms = (time.time() - start_time) * 1000
            self.logger.log_db_operation(
                operation="UPDATE",
                table="devices",
                result="success",
                duration_ms=duration_ms,
                customer_device_id=device.customer_device_id
            )
            
            cursor.close()
            conn.close()
            
            return device
        except Exception as e:
            self.logger.error(f"Failed to update device: {e}", exception=e)
            raise
    
    def delete(self, customer_device_id: str) -> bool:
        """Delete a device"""
        try:
            start_time = time.time()
            conn = self._get_connection()
            cursor = conn.cursor(dictionary=True)
            
            query = "DELETE FROM devices WHERE customer_device_id = %s"
            cursor.execute(query, (customer_device_id,))
            conn.commit()
            
            duration_ms = (time.time() - start_time) * 1000
            self.logger.log_db_operation(
                operation="DELETE",
                table="devices",
                result="success",
                duration_ms=duration_ms,
                customer_device_id=customer_device_id
            )
            
            cursor.close()
            conn.close()
            
            return cursor.rowcount > 0
        except Exception as e:
            self.logger.error(f"Failed to delete device: {e}", exception=e)
            raise
    
    def get_next_customer_device_id(self, customer: str) -> str:
        """Get next customer device ID (e.g., Parloa-00001)"""
        try:
            conn = self._get_connection()
            cursor = conn.cursor(dictionary=True)
            
            # Get the highest number for this customer
            query = """
                SELECT MAX(CAST(SUBSTRING_INDEX(customer_device_id, '-', -1) AS UNSIGNED)) as max_num 
                FROM devices 
                WHERE customer = %s AND customer_device_id LIKE %s
            """
            
            pattern = f"{customer}-%"
            cursor.execute(query, (customer, pattern))
            result = cursor.fetchone()
            
            cursor.close()
            conn.close()
            
            max_num = result.get('max_num') if result else 0
            next_num = (max_num or 0) + 1
            
            # Format as "Customer-00001"
            next_id = f"{customer}-{next_num:05d}"
            
            self.logger.debug(f"Generated customer_device_id: {next_id}", customer=customer)
            
            return next_id
        except Exception as e:
            self.logger.error(f"Failed to get next customer_device_id: {e}", exception=e)
            return f"{customer}-00001"
    
    def _generate_customer_device_id(self, customer: str) -> str:
        """Generate a new customer device ID"""
        return self.get_next_customer_device_id(customer)
    
    def _map_to_device(self, row: dict) -> Device:
        """Map database row to Device domain object"""
        return Device(
            id=row.get('id'),
            customer=row.get('customer'),
            customer_device_id=row.get('customer_device_id'),
            name=row.get('name'),
            type=row.get('type'),
            location=row.get('location'),
            manufacturer=row.get('manufacturer'),
            serial_number=row.get('serial_number'),
            purchase_date=row.get('purchase_date'),
            last_inspection=row.get('last_inspection'),
            next_inspection=row.get('next_inspection'),
            status=row.get('status'),
            notes=row.get('notes'),
            r_pe=row.get('r_pe'),
            r_iso=row.get('r_iso'),
            i_pe=row.get('i_pe'),
            i_b=row.get('i_b'),
            # USB-Kabel Felder (NEU)
            cable_type=row.get('cable_type'),
            test_result=row.get('test_result'),
            internal_resistance=row.get('internal_resistance'),
            emarker_active=row.get('emarker_active'),
            inspection_notes=row.get('inspection_notes')
        )
