# Photoneutron & Secondary-Particle Dose Decomposition in a Water Phantom (Geant4 + MATLAB)

> Monte Carlo characterization of the spatial dose distribution of monoenergetic
> photon beams (6, 10, 12, 15, 18 MeV) in a voxelized water phantom, decomposing
> the total dose into primary and secondary components (electrons, positrons,
> photons and **neutrons**), with emphasis on the photoneutron contribution.

<!-- Suggested badges — edit the URLs once the repo is public
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Geant4](https://img.shields.io/badge/Geant4-v11.3.2-blue)
![MATLAB](https://img.shields.io/badge/MATLAB-R2025a-orange)
-->

*Bilingual README — English first, Spanish below. / README bilingüe — inglés primero, español debajo.*

---

## 🇬🇧 English

### Overview
This repository contains a full Monte Carlo pipeline built with **Geant4** (C++)
and post-processed in **MATLAB**. A monoenergetic photon beam is fired at a cubic
water phantom (40 cm side) discretized into a voxel grid. Every energy deposit is
tagged by the particle that produced it and by whether it came from the primary
beam or a secondary particle, so the total dose can be split into its physical
components. The focus is the **secondary neutron** field produced by photonuclear
reactions above ~10 MeV, which is small in magnitude but radiobiologically
relevant (high LET / RBE).

This work was developed during the *XXX Verano del Programa Delfín* research
summer at **CICATA-Legaria (IPN)**, Dosimetry Laboratory.

### Key results
| Beam | D_max mean [nGy] | ε(D_max) [%] | Depth of D_max [mm] | ε(depth) [%] |
|------|-----------------:|-------------:|--------------------:|-------------:|
| 6 MeV  | 11.03 | 0.59 | 26.26 | 10.10 |
| 10 MeV | 15.59 | 0.50 | 43.88 |  6.47 |
| 12 MeV | 17.79 | 0.42 | 52.58 |  6.12 |
| 15 MeV | 21.12 | 0.35 | 65.72 |  4.17 |
| 18 MeV | 24.39 | 0.39 | 77.26 |  3.94 |

- PDD curves reproduce the expected physics (build-up region, D_max depth growing
  with energy, softer tail).
- The neutron component is low, grows with energy, and is spatially more diffuse —
  consistent with photonuclear production.
- Voxel-to-voxel relative SEM stays around 5.3–5.5 % across energies.

### Repository layout
```
photoneutron-dosimetry-geant4/
├── simulation/          Geant4 application (C++)
│   ├── include/         headers (.hh)
│   ├── src/             sources (.cc)
│   ├── macros/          init_vis + per-energy beam macros (photon_<E>MeV)
│   └── scripts/         batch drivers (master.sh, run_photon.sh)
├── analysis/            MATLAB post-processing (parte1..parte5)
├── docs/
│   ├── report/          bilingual report PDFs (EN/ES) + LaTeX source
│   ├── PIPELINE.md      data flow, CSV schema, how the scripts chain
│   └── KNOWN_ISSUES.md  honest notes on limitations and quirks
├── LICENSE
├── CITATION.cff
└── README.md
```

### How it works (in one paragraph)
`sim.cc` builds a multithreaded run manager, registers the physics list
(`G4EmStandardPhysics` + `G4EmExtraPhysics` with `GammaNuclear` +
`G4HadronPhysicsQGSP_BIC_HP` + `G4HadronElasticPhysics`), the voxelized water
phantom (`DetectorConstruction`) and the particle gun (`PrimaryGeneratorAction`,
driven by macros). The sensitive detector `MyDoseDeposit` routes each energy
deposit to `MyRun`, which keeps 3D grids for total, primary and per-particle
secondary dose. `MyRunAction::EndOfRunAction` writes one CSV per run. The MATLAB
scripts then average across runs, compute PDD and global metrics, build 2D/3D dose
maps and histograms, and quantify the secondary contribution.

### Build & run (Geant4)
```bash
cd simulation
mkdir build && cd build
cmake ..
make -j$(nproc)
# interactive (opens the visualizer):
./sim
# batch (one macro = one run):
./sim ../macros/photon_15MeV.mac
```
Requires a Geant4 v11.x installation with the high-precision neutron data
(`G4NDL`) and multithreading enabled. See `simulation/README.md`.

### Analyze (MATLAB)
The batch scripts write per-run CSVs to `output/<E>MeV/`. Point the MATLAB scripts at
that folder (set `baseDir`, default `'datos finales'`) and run them in order
(`parte1` → `parte5`). See `analysis/README.md` and `docs/PIPELINE.md`.

### Report
`docs/report/` contains the compiled bilingual report — **English** (`report_en.pdf`)
and **Spanish** (`report_es.pdf`) — with the LaTeX source (`report_en.tex`,
`report_es.tex`, `references.bib`) included for reference.

### License & citation
MIT License (see `LICENSE`). If you use this work, please cite it via
`CITATION.cff`.

---

## 🇪🇸 Español

### Resumen
Este repositorio contiene un flujo de Monte Carlo completo en **Geant4** (C++) y
post-procesamiento en **MATLAB**. Un haz de fotones monoenergéticos incide sobre
un fantoma cúbico de agua (40 cm de lado) discretizado en una malla de vóxeles.
Cada depósito de energía se etiqueta por la partícula que lo produjo y por si
proviene del haz primario o de una partícula secundaria, de modo que la dosis
total puede descomponerse en sus componentes físicas. El énfasis está en el campo
de **neutrones secundarios** generados por reacciones fotonucleares por encima de
~10 MeV, de baja magnitud pero relevante radiobiológicamente (alto LET / RBE).

Trabajo desarrollado durante el *XXX Verano del Programa Delfín* en el
**CICATA-Legaria (IPN)**, Laboratorio de Dosimetría.

### Resultados principales
| Haz | D_max media [nGy] | ε(D_max) [%] | Prof. de D_max [mm] | ε(prof.) [%] |
|-----|------------------:|-------------:|--------------------:|-------------:|
| 6 MeV  | 11.03 | 0.59 | 26.26 | 10.10 |
| 10 MeV | 15.59 | 0.50 | 43.88 |  6.47 |
| 12 MeV | 17.79 | 0.42 | 52.58 |  6.12 |
| 15 MeV | 21.12 | 0.35 | 65.72 |  4.17 |
| 18 MeV | 24.39 | 0.39 | 77.26 |  3.94 |

- Las curvas PDD reproducen la física esperada (acumulación, profundidad de D_max
  creciente con la energía, cola más suave).
- La componente neutrónica es baja, crece con la energía y es espacialmente más
  difusa, coherente con la producción fotonuclear.
- El SEM relativo vóxel a vóxel se mantiene en ~5.3–5.5 % entre energías.

### Estructura del repositorio
Ver el árbol en la sección en inglés. En breve: `simulation/` (Geant4),
`analysis/` (MATLAB), `docs/` (reporte bilingüe, pipeline y notas).

### Compilar y ejecutar (Geant4)
```bash
cd simulation
mkdir build && cd build
cmake ..
make -j$(nproc)
./sim                          # modo interactivo (visualizador)
./sim ../macros/photon_15MeV.mac  # modo batch (una macro = una corrida)
```
Requiere Geant4 v11.x con los datos de neutrones de alta precisión (`G4NDL`) y
multihilo. Ver `simulation/README.md`.

### Analizar (MATLAB)
Los scripts de lote escriben los CSV por corrida en `output/<E>MeV/`. Apunta los
scripts de MATLAB a esa carpeta (ajusta `baseDir`, por defecto `'datos finales'`) y
ejecútalos en orden (`parte1` → `parte5`). Ver `analysis/README.md` y
`docs/PIPELINE.md`.

### Reporte
`docs/report/` contiene el reporte bilingüe compilado — **inglés** (`report_en.pdf`)
y **español** (`report_es.pdf`) — junto con la fuente LaTeX (`report_en.tex`,
`report_es.tex`, `references.bib`) incluida como referencia.

### Licencia y cita
Licencia MIT (ver `LICENSE`). Si usas este trabajo, cítalo con `CITATION.cff`.

---

### Authors / Autores
- **Jorge Ramírez López** — Licenciatura en Física, CUCEI, Universidad de Guadalajara
- **Valeria Catalina Siordia Ortíz** — Ingeniería Biomédica, CUTlajomulco, Universidad de Guadalajara

**Advisors / Asesores (CICATA-Legaria, IPN):** Dr. Teodoro Rivera Montalvo ·
Lic. Alejandra Inzunza Lugo · Lic. César Samuel Romero Núñez
