#!/bin/bash

ENERGY=$1
RUN_ID=$2

if [ -z "$ENERGY" ] || [ -z "$RUN_ID" ]; then
  echo "❌ Uso: $0 <ENERGY(MeV)> <RUN_ID>"
  exit 1
fi

cd "$(dirname "$0")" || exit 1

BASE_MACRO="macros/photon_${ENERGY}MeV.mac"
TMP_MACRO="macros/tmp_${ENERGY}MeV_run${RUN_ID}.mac"
OUTPUT_FILE="output_final.csv"
RENAMED_OUTPUT="output/${ENERGY}MeV/${ENERGY}MeV_output_run${RUN_ID}.csv"

# Crear subcarpeta de salida por energía si no existe
mkdir -p "output/${ENERGY}MeV"

# Generar semillas aleatorias
SEED1=$(( RANDOM * RANDOM ))
SEED2=$(( RANDOM * RANDOM ))

# Crear macro temporal con semillas + macro base
echo "/random/setSeeds ${SEED1} ${SEED2}" > "${TMP_MACRO}"
cat "${BASE_MACRO}" >> "${TMP_MACRO}"

echo "🚀 Simulación ${ENERGY} MeV, run ${RUN_ID} con semillas ${SEED1} ${SEED2}"

./sim "${TMP_MACRO}"
SIM_EXIT=$?

# Borrar macro temporal
rm -f "${TMP_MACRO}"

if [ "$SIM_EXIT" -ne 0 ]; then
  echo "❌ La simulación falló con código $SIM_EXIT"
  exit 1
fi

echo "⏳ Esperando a que se cree el archivo ${OUTPUT_FILE}..."
while [ ! -f "${OUTPUT_FILE}" ] || [ ! -s "${OUTPUT_FILE}" ]; do
  sleep 1
done

echo "✅ Moviendo resultado a ${RENAMED_OUTPUT}"
mv "${OUTPUT_FILE}" "${RENAMED_OUTPUT}"

