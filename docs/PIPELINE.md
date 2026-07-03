# Data pipeline / Flujo de datos

*Bilingual. / Bilingüe.*

## 🇬🇧 English

### End-to-end flow
```
Geant4 (sim)                                   MATLAB
────────────                                   ──────
scripts/master.sh "6 10 12 15 18" 100
   └─ run_photon.sh  (per run: random seeds,
      ./sim, wait, move output_final.csv)
         └─► output/<E>MeV/<E>MeV_output_run<ID>.csv
                                               parte1.m  ─► DepthDose_Averaged_<E>MeV.csv
   point the analysis at that folder                       Resumen_<E>MeV.csv
   (set baseDir, see note below)        ─────►             Dosis3D_Averaged_<E>MeV.csv
                                               parte2.m  ─► PDD comparison figure + long-form CSV
                                               parte3.m  ─► 2D (MIP) & 3D dose maps per component
                                               parte4.m  ─► secondary % contribution + bar chart
                                               parte5.m  ─► Dmax & depth-of-Dmax histograms
```

### Folder convention
The batch scripts write to:
```
output/
├── 6MeV/    6MeV_output_run1.csv, 6MeV_output_run2.csv, ...
├── 10MeV/   10MeV_output_run1.csv, ...
├── 12MeV/   ...
├── 15MeV/   ...
└── 18MeV/   ...
```
The MATLAB scripts read a folder set by `baseDir` (default `'datos finales'`). Either
set `baseDir = 'output'` (or the absolute path to it), or copy/rename your curated
run set to a `datos finales/` folder. The scripts detect any subfolder matching
`*MeV` and read every `*.csv` inside as an independent run. `parte1.m` writes the
averaged products (`DepthDose_Averaged_*`, `Resumen_*`, `Dosis3D_Averaged_*`) back
into each energy folder.

### Raw per-run CSV schema (written by Geant4)
Header produced by `MyRunAction::EndOfRunAction`:
```
X,Y,Z,DosisTotal,DosisPrimaria,Sec_<particle1>,Sec_<particle2>,...
```
- `X,Y,Z` — integer voxel indices (replica numbers). X is the innermost replica
  (kXAxis), Z is the slice axis (kZAxis, i.e. depth along the beam).
- `DosisTotal`, `DosisPrimaria` — dose in **Gy** (already divided by voxel mass).
- `Sec_*` — one column per secondary particle name seen during the run, dose in Gy.
  Column set can differ between runs; MATLAB matches columns by name, not position.

Only voxels with non-zero total dose are written (sparse output).

### Averaged 3D CSV schema (written by parte1.m)
```
X,Y,Z,D_total_Gy,D_total_Std_Gy,Err_total_prct,
D_primary_Gy,D_e_minus_Gy,D_e_plus_Gy,D_gamma_Gy,D_neutron_Gy,D_other_Gy
```

### Geometry constants (single source of truth)
| Quantity | Value |
|---|---|
| Phantom | cubic `G4_WATER`, 40 cm side |
| Grid | 27 × 27 × 200 voxels |
| Voxel pitch X/Y | 400 mm / 27 = **14.8148 mm** |
| Voxel pitch Z | 400 mm / 200 = **2.0 mm** |
| Voxel volume | ≈ 438.96 mm³ |

> Note: nominal design was 15 × 15 × 2 mm, but 400 mm is not divisible by 15 mm,
> so the rounded 27 voxels give a real pitch of 14.8148 mm in X/Y. See
> `KNOWN_ISSUES.md`.

---

## 🇪🇸 Español

### Flujo de principio a fin
```
Geant4 (sim)                                   MATLAB
────────────                                   ──────
scripts/master.sh "6 10 12 15 18" 100
   └─ run_photon.sh  (por corrida: semillas
      aleatorias, ./sim, espera, mueve CSV)
         └─► output/<E>MeV/<E>MeV_output_run<ID>.csv
                                               parte1.m ─► DepthDose_Averaged_<E>MeV.csv
   apunta el análisis a esa carpeta                       Resumen_<E>MeV.csv
   (ajusta baseDir, ver nota)           ─────►            Dosis3D_Averaged_<E>MeV.csv
                                               parte2.m ─► figura comparativa PDD + CSV long-form
                                               parte3.m ─► mapas 2D (MIP) y 3D por componente
                                               parte4.m ─► % de contribución secundaria + barras
                                               parte5.m ─► histogramas de Dmax y prof. de Dmax
```

### Convención de carpetas
Los scripts de lote escriben en:
```
output/
├── 6MeV/    6MeV_output_run1.csv, 6MeV_output_run2.csv, ...
├── 10MeV/   10MeV_output_run1.csv, ...
├── 12MeV/   ...
├── 15MeV/   ...
└── 18MeV/   ...
```
Los scripts de MATLAB leen una carpeta definida por `baseDir` (por defecto
`'datos finales'`). Puedes poner `baseDir = 'output'` (o la ruta absoluta), o
copiar/renombrar tu conjunto curado de corridas a una carpeta `datos finales/`. Los
scripts detectan cualquier subcarpeta que coincida con `*MeV` y leen cada `*.csv`
dentro como una corrida independiente. `parte1.m` escribe los productos promediados
(`DepthDose_Averaged_*`, `Resumen_*`, `Dosis3D_Averaged_*`) en cada carpeta.

### Esquema del CSV crudo por corrida (lo escribe Geant4)
Encabezado producido por `MyRunAction::EndOfRunAction`:
```
X,Y,Z,DosisTotal,DosisPrimaria,Sec_<particula1>,Sec_<particula2>,...
```
- `X,Y,Z` — índices enteros del vóxel (números de réplica). X es la réplica más
  interna (kXAxis); Z es el eje de rebanadas (kZAxis, profundidad a lo largo del haz).
- `DosisTotal`, `DosisPrimaria` — dosis en **Gy** (ya dividida por la masa del vóxel).
- `Sec_*` — una columna por cada nombre de partícula secundaria vista en la corrida,
  dosis en Gy. El conjunto de columnas puede variar entre corridas; MATLAB empareja
  columnas por nombre, no por posición.

Solo se escriben los vóxeles con dosis total distinta de cero (salida dispersa).

### Esquema del CSV 3D promediado (lo escribe parte1.m)
```
X,Y,Z,D_total_Gy,D_total_Std_Gy,Err_total_prct,
D_primary_Gy,D_e_minus_Gy,D_e_plus_Gy,D_gamma_Gy,D_neutron_Gy,D_other_Gy
```

### Constantes de geometría (fuente única de verdad)
| Cantidad | Valor |
|---|---|
| Fantoma | `G4_WATER` cúbico, 40 cm de lado |
| Malla | 27 × 27 × 200 vóxeles |
| Paso de vóxel X/Y | 400 mm / 27 = **14.8148 mm** |
| Paso de vóxel Z | 400 mm / 200 = **2.0 mm** |
| Volumen del vóxel | ≈ 438.96 mm³ |

> Nota: el diseño nominal era 15 × 15 × 2 mm, pero 400 mm no es divisible entre
> 15 mm, así que los 27 vóxeles redondeados dan un paso real de 14.8148 mm en X/Y.
> Ver `KNOWN_ISSUES.md`.
