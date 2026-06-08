#!/usr/bin/env python3
"""
Entfernt doppelte Funktionsdefinitionen aus app.py
"""

import re
from pathlib import Path

def remove_duplicate_functions(app_file_path):
    """Entfernt doppelte Funktionsdefinitionen"""
    
    app_file_path = str(app_file_path)
    
    print(f"📖 Lese {app_file_path}")
    
    with open(app_file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Backup erstellen
    backup_path = str(app_file_path) + '.dedup_backup'
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✓ Backup erstellt: {backup_path}")
    
    # Finde alle Funktionsdefinitionen mit ihren Dekoratoren
    # Pattern: Alle Zeilen von @app.route bis zur nächsten @app.route oder if __name__
    func_pattern = r'(@app\.route.*?\ndef \w+\(.*?\):.*?)(?=\n@app\.route|if __name__|$)'
    
    functions = re.findall(func_pattern, content, re.DOTALL)
    
    print(f"🔍 Gefundene Funktionen: {len(functions)}")
    
    # Extrahiere Funktionsnamen
    func_names = {}
    for func_code in functions:
        match = re.search(r'def (\w+)\(', func_code)
        if match:
            func_name = match.group(1)
            if func_name not in func_names:
                func_names[func_name] = []
            func_names[func_name].append(func_code)
    
    # Zeige Duplikate
    duplicates = {name: codes for name, codes in func_names.items() if len(codes) > 1}
    
    if not duplicates:
        print("✓ Keine Duplikate gefunden")
        return False
    
    print(f"\n⚠ Gefundene Duplikate:")
    for name, codes in duplicates.items():
        print(f"  - {name}: {len(codes)}x")
    
    # Entferne Duplikate (behalte nur das erste Vorkommen)
    new_content = content
    for name, codes in duplicates.items():
        # Entferne alle außer dem ersten
        for duplicate_code in codes[1:]:
            # Escape special regex characters
            escaped_code = re.escape(duplicate_code)
            new_content = re.sub(escaped_code, '', new_content, count=1)
            print(f"  ✓ Entferne Duplikat von {name}")
    
    # Bereinige mehrfache Leerzeilen
    new_content = re.sub(r'\n{3,}', '\n\n', new_content)
    
    # Schreibe zurück
    with open(app_file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"\n✓ {sum(len(codes) - 1 for codes in duplicates.values())} Duplikat(e) entfernt")
    
    # Prüfe Ergebnis
    with open(app_file_path, 'r', encoding='utf-8') as f:
        new_content = f.read()
    
    new_func_names = re.findall(r'def (usbc_\w+)\(', new_content)
    print(f"\n📊 Ergebnis:")
    from collections import Counter
    counts = Counter(new_func_names)
    for func, count in counts.items():
        status = "✓" if count == 1 else "⚠"
        print(f"  {status} {func}: {count}x")
    
    return True

if __name__ == '__main__':
    app_file = Path.home() / 'Dokumente' / 'vsCode' / 'Benning-DGUV3' / 'Software' / 'PRG' / 'app.py'
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║  Doppelte Funktionen entfernen                            ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print()
    
    if not app_file.exists():
        print(f"❌ Datei nicht gefunden: {app_file}")
        exit(1)
    
    success = remove_duplicate_functions(app_file)
    
    print()
    if success:
        print("✅ Bereinigung erfolgreich!")
        print()
        print("Starten Sie Flask neu:")
        print("  cd ~/Dokumente/vsCode/Benning-DGUV3/Software/PRG")
        print("  ./venv/bin/python app.py")
    else:
        print("⚠ Keine Duplikate gefunden")
    print()
