"""
PDF Export Route für die Geräteliste
Verwendet WeasyPrint zur PDF-Generierung
"""

from flask import Blueprint, render_template_string, send_file, jsonify
from io import BytesIO
from datetime import datetime
from weasyprint import HTML, CSS
import os

# Blueprint für PDF-Export
pdf_bp = Blueprint('pdf', __name__, url_prefix='/pdf')


def get_devices_from_container(container):
    """Hole alle Geräte aus der Repository"""
    try:
        devices = container.device_repository.get_all()
        return devices
    except Exception as e:
        return []


@pdf_bp.route('/devices', methods=['GET'])
def export_devices_pdf(container=None):
    """
    Exportiere alle Geräte als PDF
    GET /pdf/devices
    """
    try:
        # Hole alle Geräte
        if container is None:
            from src.config.dependencies import Container
            container = Container()
        
        devices = get_devices_from_container(container)
        
        # HTML Template für PDF
        html_template = """
        <!DOCTYPE html>
        <html lang="de">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Geräteliste</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: Arial, sans-serif;
                    font-size: 11pt;
                    color: #333;
                    background: white;
                }
                
                .header {
                    text-align: center;
                    margin-bottom: 30px;
                    border-bottom: 2px solid #333;
                    padding-bottom: 15px;
                }
                
                .header h1 {
                    font-size: 24pt;
                    margin-bottom: 5px;
                    color: #1a1a1a;
                }
                
                .header p {
                    font-size: 10pt;
                    color: #666;
                }
                
                .metadata {
                    display: flex;
                    justify-content: space-between;
                    margin-bottom: 20px;
                    font-size: 10pt;
                    color: #666;
                }
                
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 20px;
                }
                
                thead {
                    background-color: #f0f0f0;
                    border-top: 2px solid #333;
                    border-bottom: 2px solid #333;
                }
                
                th {
                    padding: 10px;
                    text-align: left;
                    font-weight: bold;
                    font-size: 10pt;
                    color: #333;
                }
                
                td {
                    padding: 8px 10px;
                    border-bottom: 1px solid #ddd;
                    font-size: 10pt;
                }
                
                tbody tr:nth-child(even) {
                    background-color: #f9f9f9;
                }
                
                tbody tr:hover {
                    background-color: #f0f0f0;
                }
                
                .status-active {
                    color: #28a745;
                    font-weight: bold;
                }
                
                .status-inactive {
                    color: #dc3545;
                    font-weight: bold;
                }
                
                .status-maintenance {
                    color: #ffc107;
                    font-weight: bold;
                }
                
                .status-retired {
                    color: #6c757d;
                    font-weight: bold;
                }
                
                .empty-message {
                    text-align: center;
                    padding: 40px;
                    color: #999;
                    font-size: 12pt;
                }
                
                .footer {
                    margin-top: 30px;
                    padding-top: 15px;
                    border-top: 1px solid #ddd;
                    font-size: 9pt;
                    color: #999;
                    text-align: center;
                }
                
                @page {
                    size: A4;
                    margin: 20mm;
                }
                
                @media print {
                    body {
                        margin: 0;
                        padding: 0;
                    }
                }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Benning Device Manager</h1>
                <p>Geräteliste</p>
            </div>
            
            <div class="metadata">
                <div>
                    <strong>Gesamtzahl Geräte:</strong> {{ devices|length }}
                </div>
                <div>
                    <strong>Generiert:</strong> {{ generated_date }}
                </div>
            </div>
            
            {% if devices %}
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Kundenname</th>
                        <th>Geräte-ID</th>
                        <th>Name</th>
                        <th>Typ</th>
                        <th>Seriennummer</th>
                        <th>Standort</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    {% for device in devices %}
                    <tr>
                        <td>{{ device.id }}</td>
                        <td>{{ device.customer }}</td>
                        <td>{{ device.customer_device_id }}</td>
                        <td>{{ device.name }}</td>
                        <td>{{ device.type or '-' }}</td>
                        <td>{{ device.serial_number or '-' }}</td>
                        <td>{{ device.location or '-' }}</td>
                        <td>
                            <span class="status-{{ device.status or 'active' }}">
                                {{ device.status or 'active' }}
                            </span>
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
            {% else %}
            <div class="empty-message">
                <p>Keine Geräte vorhanden</p>
            </div>
            {% endif %}
            
            <div class="footer">
                <p>Benning Device Manager | Geräteliste PDF Export</p>
            </div>
        </body>
        </html>
        """
        
        # Render HTML mit Jinja2
        from flask import render_template_string
        html_content = render_template_string(
            html_template,
            devices=devices,
            generated_date=datetime.now().strftime('%d.%m.%Y %H:%M:%S')
        )
        
        # Konvertiere HTML zu PDF mit WeasyPrint
        pdf_file = BytesIO()
        HTML(string=html_content).write_pdf(pdf_file)
        pdf_file.seek(0)
        
        # Sende PDF als Download
        filename = f"geraete_liste_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        
        return send_file(
            pdf_file,
            mimetype='application/pdf',
            as_attachment=True,
            download_name=filename
        )
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'PDF-Generierung fehlgeschlagen: {str(e)}'
        }), 500


@pdf_bp.route('/devices/customer/<customer>', methods=['GET'])
def export_customer_devices_pdf(customer, container=None):
    """
    Exportiere Geräte eines bestimmten Kunden als PDF
    GET /pdf/devices/customer/<customer>
    """
    try:
        if container is None:
            from src.config.dependencies import Container
            container = Container()
        
        # Hole alle Geräte
        all_devices = get_devices_from_container(container)
        
        # Filtere nach Kundenname
        devices = [d for d in all_devices if d.customer.lower() == customer.lower()]
        
        # HTML Template für PDF
        html_template = """
        <!DOCTYPE html>
        <html lang="de">
        <head>
            <meta charset="UTF-8">
            <title>Geräteliste - {{ customer }}</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: Arial, sans-serif;
                    font-size: 11pt;
                    color: #333;
                }
                
                .header {
                    text-align: center;
                    margin-bottom: 30px;
                    border-bottom: 2px solid #333;
                    padding-bottom: 15px;
                }
                
                .header h1 {
                    font-size: 24pt;
                    margin-bottom: 5px;
                }
                
                .header p {
                    font-size: 12pt;
                    color: #666;
                }
                
                .metadata {
                    display: flex;
                    justify-content: space-between;
                    margin-bottom: 20px;
                    font-size: 10pt;
                    color: #666;
                }
                
                table {
                    width: 100%;
                    border-collapse: collapse;
                }
                
                thead {
                    background-color: #f0f0f0;
                    border-top: 2px solid #333;
                    border-bottom: 2px solid #333;
                }
                
                th {
                    padding: 10px;
                    text-align: left;
                    font-weight: bold;
                }
                
                td {
                    padding: 8px 10px;
                    border-bottom: 1px solid #ddd;
                }
                
                tbody tr:nth-child(even) {
                    background-color: #f9f9f9;
                }
                
                .empty-message {
                    text-align: center;
                    padding: 40px;
                    color: #999;
                }
                
                @page {
                    size: A4;
                    margin: 20mm;
                }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Benning Device Manager</h1>
                <p>Geräteliste für Kunde: <strong>{{ customer }}</strong></p>
            </div>
            
            <div class="metadata">
                <div>
                    <strong>Kundenname:</strong> {{ customer }}
                </div>
                <div>
                    <strong>Anzahl Geräte:</strong> {{ devices|length }}
                </div>
                <div>
                    <strong>Generiert:</strong> {{ generated_date }}
                </div>
            </div>
            
            {% if devices %}
            <table>
                <thead>
                    <tr>
                        <th>Geräte-ID</th>
                        <th>Name</th>
                        <th>Typ</th>
                        <th>Seriennummer</th>
                        <th>Standort</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    {% for device in devices %}
                    <tr>
                        <td>{{ device.customer_device_id }}</td>
                        <td>{{ device.name }}</td>
                        <td>{{ device.type or '-' }}</td>
                        <td>{{ device.serial_number or '-' }}</td>
                        <td>{{ device.location or '-' }}</td>
                        <td>{{ device.status or 'active' }}</td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
            {% else %}
            <div class="empty-message">
                <p>Keine Geräte für diesen Kunden vorhanden</p>
            </div>
            {% endif %}
        </body>
        </html>
        """
        
        # Render HTML
        from flask import render_template_string
        html_content = render_template_string(
            html_template,
            customer=customer,
            devices=devices,
            generated_date=datetime.now().strftime('%d.%m.%Y %H:%M:%S')
        )
        
        # Konvertiere zu PDF
        pdf_file = BytesIO()
        HTML(string=html_content).write_pdf(pdf_file)
        pdf_file.seek(0)
        
        # Sende als Download
        filename = f"geraete_{customer}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        
        return send_file(
            pdf_file,
            mimetype='application/pdf',
            as_attachment=True,
            download_name=filename
        )
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'PDF-Generierung fehlgeschlagen: {str(e)}'
        }), 500
