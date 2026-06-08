#!/bin/bash

echo "=== EMERGENCY DIAGNOSIS ==="
echo ""

echo "1. Container Status:"
podman ps -a | grep benning

echo ""
echo "2. Flask Container Logs (letzte 50 Zeilen):"
podman logs --tail 50 benning-flask 2>&1

echo ""
echo "3. Python Syntax Check device.py:"
python3 -m py_compile /home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG/src/core/domain/device.py 2>&1

echo ""
echo "4. Python Syntax Check device_routes.py:"
python3 -m py_compile /home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG/src/adapters/web/device_routes.py 2>&1

echo ""
echo "5. Python Syntax Check mysql_device_repository.py:"
python3 -m py_compile /home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG/src/adapters/repositories/mysql_device_repository.py 2>&1

echo ""
echo "6. Ordner-Berechtigungen:"
ls -la /home/y/Dokumente/vsCode/Benning-DGUV3/Software/PRG/static/uploads/ 2>&1

echo ""
echo "=== END DIAGNOSIS ==="
