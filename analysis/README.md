# Analysis (MATLAB) / Análisis (MATLAB)

*Bilingual. / Bilingüe.* Developed on **MATLAB R2025a**.

## 🇬🇧 English

### What each script does
| Script | Reads | Produces |
|---|---|---|
| `parte1.m` | raw per-run CSVs in `datos finales/<E>MeV/` | `DepthDose_Averaged_<E>MeV.csv`, `Resumen_<E>MeV.csv`, `Dosis3D_Averaged_<E>MeV.csv`; mean dose, std, voxel-wise SEM% |
| `parte2.m` | `DepthDose_Averaged_*` | PDD comparison figure across energies + long-form PDD CSV |
| `parte3.m` | `Dosis3D_Averaged_*` | 2D max-intensity-projection maps and 3D voxel maps, per dose component |
| `parte4.m` | `Dosis3D_Averaged_*` | percentage contribution of each secondary particle + bar chart CSV |
| `parte5.m` | raw per-run CSVs | per-energy histograms of D_max (nGy) and depth-of-D_max (mm), annotated with μ, σ, ε |

### How to run
1. The batch scripts write per-run CSVs to `output/<E>MeV/`. Set `baseDir` at the top
   of each script to that folder (or rename it to the default `'datos finales'`). See
   `../docs/PIPELINE.md` for the CSV schema and folder convention.
2. Run in order: `parte1` → `parte2` → `parte3` → `parte4` → `parte5`.
   `parte1` must run first because it generates the averaged files the others read.

### Correctness note (voxel pitch)
The real X/Y voxel pitch is `400 mm / 27 = 14.8148 mm` (Z is exactly 2 mm), because
the 40 cm phantom is not divisible by the nominal 15 mm. The map script
(`parte3.m`) and the pitch definitions in `parte1.m`/`parte5.m` were updated to use
the real pitch instead of a hardcoded 15 mm. This only affected the X/Y **axis
labels** of the maps (~1.2 %); dose values were never affected. Full detail in
`../docs/KNOWN_ISSUES.md`.

### Tips
- The scripts are tuned for **poster-quality** figures (large fonts). Lower the
  `*Font` variables at the top for on-screen or paper-column use.
- `parte1`/`parte5` stream the CSVs in blocks (`readSize`) to keep RAM bounded on
  large datasets — adjust to your machine.

---

## 🇪🇸 Español

### Qué hace cada script
| Script | Lee | Produce |
|---|---|---|
| `parte1.m` | CSVs crudos por corrida en `datos finales/<E>MeV/` | `DepthDose_Averaged_<E>MeV.csv`, `Resumen_<E>MeV.csv`, `Dosis3D_Averaged_<E>MeV.csv`; dosis media, std, SEM% por vóxel |
| `parte2.m` | `DepthDose_Averaged_*` | figura comparativa de PDD entre energías + CSV long-form |
| `parte3.m` | `Dosis3D_Averaged_*` | mapas 2D (proyección de máxima intensidad) y mapas 3D de vóxeles, por componente |
| `parte4.m` | `Dosis3D_Averaged_*` | porcentaje de contribución de cada secundaria + CSV para barras |
| `parte5.m` | CSVs crudos por corrida | histogramas por energía de D_max (nGy) y prof. de D_max (mm), con μ, σ, ε |

### Cómo ejecutar
1. Los scripts de lote escriben los CSV por corrida en `output/<E>MeV/`. Ajusta
   `baseDir` al inicio de cada script a esa carpeta (o renómbrala al valor por defecto
   `'datos finales'`). Ver `../docs/PIPELINE.md` para el esquema del CSV y la
   convención de carpetas.
2. Ejecuta en orden: `parte1` → `parte2` → `parte3` → `parte4` → `parte5`.
   `parte1` debe correr primero porque genera los archivos promediados que leen los
   demás.

### Nota de corrección (paso de vóxel)
El paso real de vóxel en X/Y es `400 mm / 27 = 14.8148 mm` (Z es exacto: 2 mm),
porque el fantoma de 40 cm no es divisible entre los 15 mm nominales. El script de
mapas (`parte3.m`) y las definiciones de paso en `parte1.m`/`parte5.m` se
actualizaron para usar el paso real en vez de 15 mm fijos. Esto solo afectaba las
**etiquetas de los ejes** X/Y de los mapas (~1.2 %); los valores de dosis nunca se
vieron afectados. Detalle completo en `../docs/KNOWN_ISSUES.md`.

### Consejos
- Los scripts están afinados para figuras **calidad póster** (fuentes grandes).
  Baja las variables `*Font` del inicio para pantalla o columna de artículo.
- `parte1`/`parte5` leen los CSV por bloques (`readSize`) para acotar la RAM en
  datasets grandes — ajústalo a tu equipo.
