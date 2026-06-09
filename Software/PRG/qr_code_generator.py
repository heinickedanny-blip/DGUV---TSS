"""QR Code Generator Service - Für Device IDs"""
import qrcode
from io import BytesIO
from typing import Optional


class QRCodeGenerator:
    """Generiert QR-Codes für Device IDs"""
    
    @staticmethod
    def generate_qr_code(device_id: str, customer: str = "") -> Optional[bytes]:
        """
        Generiert einen QR-Code für eine Device ID
        
        Args:
            device_id: Die Device ID (z.B. "Parloa-00001")
            customer: Der Kundenname (optional)
            
        Returns:
            QR-Code als PNG Bytes oder None bei Fehler
        """
        try:
            # Erstelle QR-Code Daten
            qr_data = f"{customer}|{device_id}" if customer else device_id
            
            # Erstelle QR-Code
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
            )
            qr.add_data(qr_data)
            qr.make(fit=True)
            
            # Erstelle Bild
            img = qr.make_image(fill_color="black", back_color="white")
            
            # Konvertiere zu Bytes
            img_bytes = BytesIO()
            img.save(img_bytes, format='PNG')
            img_bytes.seek(0)
            
            return img_bytes.getvalue()
        except Exception as e:
            print(f"Error generating QR code: {e}")
            return None
