
"""QR Code Generator Service - Für Device IDs - SVG Version"""
import qrcode
import qrcode.image.svg
import base64
from io import BytesIO
from typing import Optional


class QRCodeGenerator:
    """Generiert QR-Codes für Device IDs als SVG"""
    
    @staticmethod
    def generate_qr_code(device_id: str, customer: str = "") -> Optional[bytes]:
        """
        Generiert einen QR-Code für eine Device ID als SVG Base64
        
        Args:
            device_id: Die Device ID (z.B. "Parloa-00001")
            customer: Der Kundenname (optional)
            
        Returns:
            QR-Code als Base64 String (bytes) oder None bei Fehler
        """
        try:
            qr_data = f"{customer}|{device_id}" if customer else device_id
            
            # Erstelle QR-Code mit SVG Factory
            qr_code = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
                image_factory=qrcode.image.svg.SvgPathImage,
            )
            qr_code.add_data(qr_data)
            qr_code.make(fit=True)
            
            # Erstelle SVG Image
            img = qr_code.make_image()
            
            # Speichere SVG als Bytes
            svg_bytes = BytesIO()
            img.save(svg_bytes)
            svg_bytes.seek(0)
            
            # Konvertiere zu Base64
            svg_data = svg_bytes.getvalue()
            base64_svg = base64.b64encode(svg_data).decode('utf-8')
            
            print(f"✓ QR-Code (SVG) generiert für {device_id}")
            return base64_svg.encode('utf-8')
        except Exception as e:
            print(f"Error generating QR code: {e}")
            return None

