#!/usr/bin/env bash
# Corre la simulacion de ignicion en ngspice y guarda salidas en sim/wave2/out/
# Uso: bash sim/wave2/run.sh   (desde la raiz del repo o desde sim/wave2)
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p out

NGSPICE="${NGSPICE:-ngspice}"
command -v "$NGSPICE" >/dev/null 2>&1 || {
  echo "ERROR: ngspice no encontrado en PATH" >&2
  exit 1
}

# -b batch; salida completa teada al log para el informe
"$NGSPICE" -b ignition-sim.cir 2>&1 | tee out/ngspice.log
grep -q "CASE4" out/ngspice.log
echo "OK: simulacion completa, salidas en sim/wave2/out/"
