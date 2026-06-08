#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Virtual Environment nicht gefunden: $VENV_DIR"
    exit 1
fi

export CFLAGS="-march=native -O3"
export CXXFLAGS="-march=native -O3"
export LDFLAGS="-march=native -O3"
export PYTHONOPTIMIZE=2
export PIP_NO_CACHE_DIR=1

source "$VENV_DIR/bin/activate"

echo "✓ CachyOS Virtual Environment aktiviert"
echo "  Python: $(which python)"
echo "  Optimierungen: Native CPU (-march=native -O3)"
