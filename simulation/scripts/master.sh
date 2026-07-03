#!/bin/bash

# --------------------------
# Script maestro desde /build
# --------------------------

ENERGIES=($1)
REPEAT=$2

if [ ${#ENERGIES[@]} -eq 0 ] || [ -z "$REPEAT" ]; then
  echo "❌ Uso: $0 \"<energías>\" <repeticiones>"
  echo "Ejemplo: $0 \"6 10 12 15 18\" 5"
  exit 1
fi

# Ir al build y llamar ../run_photon.sh
for ENERGY in ${ENERGIES[@]}; do
  for ((RUN_ID=1; RUN_ID<=REPEAT; RUN_ID++)); do
    echo "🚀 Ejecutando ${ENERGY} MeV, run ${RUN_ID}"
    ./run_photon.sh ${ENERGY} ${RUN_ID}
  done
done

echo "🏁 Todas las simulaciones han finalizado correctamente."

