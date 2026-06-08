#!/usr/bin/env python3
"""
Zeigt alle registrierten Flask-Routen an
"""

import sys
import os

# Füge PRG zum Python-Path hinzu
sys.path.insert(0, os.path.expanduser('~/Dokumente/vsCode/Benning-DGUV3/Software/PRG'))

print("╔════════════════════════════════════════════════════════════╗")
print("║  Registrierte Flask-Routen                                ║")
print("╚════════════════════════════════════════════════════════════╝")
print()

try:
    # Importiere die Flask-App
    from app import app
    
    print(f"✓ Flask-App erfolgreich importiert")
    print(f"  Debug-Modus: {app.debug}")
    print()
    
    # Zeige alle Routen
    print("Registrierte Routen:")
    print("-" * 80)
    
    routes = []
    for rule in app.url_map.iter_rules():
        methods = ','.join(sorted(rule.methods - {'HEAD', 'OPTIONS'}))
        routes.append({
            'endpoint': rule.endpoint,
            'methods': methods,
            'path': str(rule)
        })
    
    # Sortiere nach Pfad
    routes.sort(key=lambda x: x['path'])
    
    # Zeige Routen
    usbc_found = False
    for route in routes:
        marker = "🔌" if 'usbc' in route['path'] else "  "
        print(f"{marker} {route['methods']:10s} {route['path']:50s} -> {route['endpoint']}")
        
        if 'usbc' in route['path']:
            usbc_found = True
    
    print("-" * 80)
    print(f"Gesamt: {len(routes)} Routen")
    print()
    
    if usbc_found:
        print("✓ USB-C Routen gefunden!")
    else:
        print("❌ KEINE USB-C Routen gefunden!")
        print()
        print("Mögliche Ursachen:")
        print("  1. USB-C Routen wurden beim Import nicht registriert")
        print("  2. Syntax-Fehler in den USB-C Routen")
        print("  3. USB-C Code liegt nach 'if __name__ == \"__main__\"'")
    
except ImportError as e:
    print(f"❌ Fehler beim Importieren der App: {e}")
    print()
    print("Mögliche Ursachen:")
    print("  1. Virtual Environment nicht aktiviert")
    print("  2. Dependencies fehlen")
    print("  3. Syntax-Fehler in app.py")
except Exception as e:
    print(f"❌ Fehler: {e}")
    import traceback
    traceback.print_exc()

print()
