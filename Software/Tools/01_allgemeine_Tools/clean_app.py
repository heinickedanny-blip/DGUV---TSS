#!/usr/bin/env python3
"""
Bereinigt app.py von doppelten USB-C Routen
"""

import re
import sys
from pathlib import Path

def clean_app_py(app_file_path):
    """Entfernt doppelte USB-C Routen aus app.py"""
    
    print(f"📖 Lese {app_file_path}")
    
    with open(app_file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Backup erstellen
    backup_path = str(app_file_path) + '.clean_backup'
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✓ Backup erstellt: {backup_path}")
    
    # Finde alle USB-C Routen-Blöcke (vom Kommentar bis zur nächsten Route oder if __name__)
    usbc_pattern = r'(# ={70,}\n# USB-C KABEL-PRÜFUNG ERWEITERUNG\n# ={70,}.*?)(?=\n(?:@app\.route|if __name__|$))'
    
    usbc_blocks = list(re.finditer(usbc_pattern, content, re.DOTALL))
    
    print(f"🔍 Gefundene USB-C Blöcke: {len(usbc_blocks)}")
    
    if len(usbc_blocks) == 0:
        print("❌ Keine USB-C Blöcke gefunden!")
        return False
    
    if len(usbc_blocks) == 1:
        print("✓ Nur 1 USB-C Block gefunden")
        
        # Prüfe auf doppelte Funktionsnamen
        func_names = re.findall(r'def (usbc_\w+)\(', content)
        print(f"🔍 USB-C Funktionen: {func_names}")
        
        if len(func_names) != len(set(func_names)):
            print("⚠ Doppelte Funktionsnamen gefunden!")
            # Zähle jede Funktion
            from collections import Counter
            counts = Counter(func_names)
            for func, count in counts.items():
                if count > 1:
                    print(f"  - {func}: {count}x")
        else:
            print("✓ Keine doppelten Funktionsnamen")
            print("\n⚠ Das Problem liegt nicht an Duplikaten!")
            print("Prüfen Sie, ob die Funktionen richtig definiert sind.")
            return False
    
    if len(usbc_blocks) > 1:
        print(f"⚠ {len(usbc_blocks)} USB-C Blöcke gefunden - entferne Duplikate...")
        
        # Behalte nur den ersten Block
        new_content = content
        for block in reversed(usbc_blocks[1:]):
            new_content = new_content[:block.start()] + new_content[block.end():]
        
        with open(app_file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print(f"✓ {len(usbc_blocks) - 1} Duplikat(e) entfernt")
        
        # Prüfe Ergebnis
        with open(app_file_path, 'r', encoding='utf-8') as f:
            new_content = f.read()
        
        func_names = re.findall(r'def (usbc_\w+)\(', new_content)
        print(f"✓ Verbleibende USB-C Funktionen: {len(func_names)}")
        for func in set(func_names):
            count = func_names.count(func)
            print(f"  - {func}: {count}x")
        
        return True
    
    return False

if __name__ == '__main__':
    app_file = Path.home() / 'Dokumente' / 'vsCode' / 'Benning-DGUV3' / 'Software' / 'PRG' / 'app.py'
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║  app.py Bereinigung                                       ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print()
    
    if not app_file.exists():
        print(f"❌ Datei nicht gefunden: {app_file}")
        sys.exit(1)
    
    success = clean_app_py(app_file)
    
    print()
    if success:
        print("✅ Bereinigung erfolgreich!")
        print()
        print("Starten Sie Flask neu:")
        print("  cd ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG")
        print("  ./venv/bin/python app.py")
    else:
        print("⚠ Keine Änderungen vorgenommen")
        print()
        print("Manuelle Prüfung erforderlich:")
        print("  grep -n 'def usbc' ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG/app.py")
    print()
