# Simulation (Geant4) / Simulación (Geant4)

*Bilingual. / Bilingüe.*

## 🇬🇧 English

### Requirements
- Geant4 **v11.x** (developed on v11.3.2), built with **multithreading** and
  **Qt/OpenGL vis** drivers for the interactive visualizer.
- The **high-precision neutron data** library `G4NDL` (needed by `QGSP_BIC_HP`).
  Make sure `G4NEUTRONHPDATA` points to it (Geant4's `geant4.sh` usually sets it).
- CMake ≥ 3.10, a C++17 compiler.

### Build
```bash
cd simulation
mkdir build && cd build
cmake ..
make -j$(nproc)
```
The build copies `macros/` and the batch scripts (`master.sh`, `run_photon.sh`)
into the `build/` directory, next to the `sim` binary.

### Run a single beam
```bash
# Interactive (opens the visualizer):
./sim

# Batch (headless): one macro = one run, writes output_final.csv
./sim macros/photon_15MeV.mac
```

### Beam definition (macros)
The beam uses the built-in `G4ParticleGun` interface. Each `macros/photon_<E>MeV.mac`
looks like:
```
/run/initialize
/gun/particle gamma
/gun/energy 15 MeV
/gun/position 0 0 -120 cm
/gun/direction 0 0 1
/run/verbose 1
/run/beamOn 1000000
```
The source sits at `z = -120 cm` firing along `+z`. With the phantom front face at
`z = -20 cm` (40 cm cube centered at the origin), this gives a **source-to-surface
distance (SSD) of 100 cm**. Energies provided: 6, 10, 12, 15 and 18 MeV.

> Note: the code also ships a custom `/generator/...` messenger
> (`PrimaryGeneratorMessenger`), but the production runs drive the gun through the
> standard `/gun/...` commands above, so that is what the macros use.

### Produce the full dataset (batch)
Two scripts automate many independent runs per energy. Run them **from the build
directory** (where `sim` lives):
```bash
cd build
# usage: ./master.sh "<energies>" <repetitions>
./master.sh "6 10 12 15 18" 100
```
- `master.sh` loops over energies × repetitions and calls `run_photon.sh`.
- `run_photon.sh` injects **random seeds** (`/random/setSeeds`) into a temporary
  macro so every run is statistically independent, launches `./sim`, waits for
  `output_final.csv`, and moves it to:
  ```
  output/<E>MeV/<E>MeV_output_run<ID>.csv
  ```
So a full campaign of 100 runs × 5 energies lands under `output/`. Point the MATLAB
analysis at that folder (see `../analysis/README.md` and `../docs/PIPELINE.md`).

### Physics list (`physics.cc`)
- `G4EmStandardPhysics` — EM for photons, e⁻, e⁺.
- `G4EmExtraPhysics` with `GammaNuclear(true)` — **photonuclear → secondary neutrons**.
- `G4HadronPhysicsQGSP_BIC_HP` + `G4HadronElasticPhysics` — high-precision neutron
  transport (thermal → intermediate). A trimmed `QGSP_BIC_HP` (no ion or decay
  physics, irrelevant for 6–18 MeV photon beams).

### Geometry (`DetectorConstruction.cc`)
Cubic `G4_WATER` phantom, 40 cm side, replicated into **27 × 27 × 200** voxels
(real pitch 14.8148 × 14.8148 × 2.0 mm). The sensitive detector `MyDoseDeposit` tags
every energy deposit as primary vs. secondary and by particle name.

> See `../docs/KNOWN_ISSUES.md` for two honest notes: stale grid comments in the
> constructor, and an inactive neutron-kill in `SteppingAction` (no effect on
> results). The simulation source is kept as originally written.

### File map
| File | Role |
|---|---|
| `sim.cc` | main; run manager, physics, geometry, actions, UI/vis |
| `physics.cc/.hh` | modular physics list |
| `DetectorConstruction.cc/.hh` | phantom + voxel replicas + sensitive detector |
| `PrimaryGeneratorAction.*` | particle gun (position/energy set via `/gun/...`) |
| `PrimaryGeneratorMessenger.*` | optional custom `/generator/...` commands |
| `MyDoseDeposit.*` | sensitive detector → routes deposits to MyRun |
| `MyRun.*` | per-run 3D dose grids (total/primary/secondary) + Merge |
| `MyRunAction.*` | end-of-run CSV writer (multithreaded) |
| `MyActionInitialization.*` | wires actions for master/worker threads |
| `SteppingAction.*` | neutron-kill outside phantom (see known issues) |
| `macros/photon_<E>MeV.mac` | per-energy beam definitions |
| `scripts/master.sh`, `scripts/run_photon.sh` | batch driver + per-run runner |

---

## 🇪🇸 Español

### Requisitos
- Geant4 **v11.x** (desarrollado en v11.3.2), compilado con **multihilo** y drivers
  de **visualización Qt/OpenGL**.
- La librería de **datos de neutrones de alta precisión** `G4NDL` (la necesita
  `QGSP_BIC_HP`). Verifica que `G4NEUTRONHPDATA` apunte a ella (normalmente lo fija
  `geant4.sh`).
- CMake ≥ 3.10 y un compilador C++17.

### Compilar
```bash
cd simulation
mkdir build && cd build
cmake ..
make -j$(nproc)
```
La compilación copia `macros/` y los scripts de lote (`master.sh`, `run_photon.sh`)
a la carpeta `build/`, junto al binario `sim`.

### Ejecutar un solo haz
```bash
./sim                              # interactivo (visualizador)
./sim macros/photon_15MeV.mac      # batch: una macro = una corrida
```

### Definición del haz (macros)
El haz usa el `G4ParticleGun` integrado. Cada `macros/photon_<E>MeV.mac` es:
```
/run/initialize
/gun/particle gamma
/gun/energy 15 MeV
/gun/position 0 0 -120 cm
/gun/direction 0 0 1
/run/verbose 1
/run/beamOn 1000000
```
La fuente está en `z = -120 cm` disparando en `+z`. Con la cara frontal del fantoma
en `z = -20 cm` (cubo de 40 cm centrado en el origen), esto da un **SSD de 100 cm**.
Energías incluidas: 6, 10, 12, 15 y 18 MeV.

> Nota: el código también trae un messenger propio `/generator/...`
> (`PrimaryGeneratorMessenger`), pero las corridas de producción manejan el cañón con
> los comandos estándar `/gun/...`, que es lo que usan las macros.

### Generar el dataset completo (batch)
Dos scripts automatizan muchas corridas independientes por energía. Ejecútalos **desde
la carpeta build** (donde está `sim`):
```bash
cd build
# uso: ./master.sh "<energías>" <repeticiones>
./master.sh "6 10 12 15 18" 100
```
- `master.sh` recorre energías × repeticiones y llama a `run_photon.sh`.
- `run_photon.sh` inyecta **semillas aleatorias** (`/random/setSeeds`) en una macro
  temporal para que cada corrida sea estadísticamente independiente, lanza `./sim`,
  espera a `output_final.csv` y lo mueve a:
  ```
  output/<E>MeV/<E>MeV_output_run<ID>.csv
  ```
Así, una campaña de 100 corridas × 5 energías queda bajo `output/`. Apunta el análisis
de MATLAB a esa carpeta (ver `../analysis/README.md` y `../docs/PIPELINE.md`).

### Lista de física (`physics.cc`)
- `G4EmStandardPhysics` — EM para fotones, e⁻, e⁺.
- `G4EmExtraPhysics` con `GammaNuclear(true)` — **fotonuclear → neutrones secundarios**.
- `G4HadronPhysicsQGSP_BIC_HP` + `G4HadronElasticPhysics` — transporte de neutrones de
  alta precisión (térmico → intermedio). Un `QGSP_BIC_HP` recortado (sin iones ni
  decaimientos, irrelevantes para haces de fotones de 6–18 MeV).

### Geometría (`DetectorConstruction.cc`)
Fantoma cúbico de `G4_WATER`, 40 cm de lado, replicado en **27 × 27 × 200** vóxeles
(paso real 14.8148 × 14.8148 × 2.0 mm). El detector sensible `MyDoseDeposit` etiqueta
cada depósito como primario o secundario y por nombre de partícula.

> Ver `../docs/KNOWN_ISSUES.md` para dos notas honestas: comentarios de malla
> desactualizados en el constructor y un "mata-neutrones" inactivo en
> `SteppingAction` (sin efecto en los resultados). El código de simulación se conserva
> tal como estaba.

### Mapa de archivos
Ver la tabla en la sección en inglés (los nombres de archivo son los mismos).
