# Known issues & design notes / Problemas conocidos y notas de diseño

*Bilingual. / Bilingüe.* These are honest, verified notes. None of them invalidate
the scored dose results; they are documented for transparency and for anyone
extending the project.

---

## 🇬🇧 English

### 1. Misleading comments in `DetectorConstruction.cc` (cosmetic, source unchanged)
The constructor computes the grid as:
```cpp
fNVoxX = int(400.0*mm / 15.0*mm + 0.5);  // comment says "100" but is actually 27
fNVoxZ = int(400.0*mm /  2.0*mm + 0.5);  // comment says "400" but is actually 200
```
The `// 100`, `// 400` and the "4mm×1mm" comments are **stale leftovers** from an
older voxel design. The **actual** grid is **27 × 27 × 200**, which is what the
MATLAB scripts use — so there is **no dimension mismatch** between the simulation
and the analysis. Only the comments are wrong. (Left as-is per project scope; the
simulation code is not modified.)

### 2. Real X/Y voxel pitch is 14.8148 mm, not 15 mm — **fixed in MATLAB**
Because 400 mm is not divisible by 15 mm, rounding to 27 voxels forces the real
pitch to `400/27 = 14.8148 mm` in X/Y (Z is exactly `400/200 = 2 mm`). The MATLAB
map script previously used `dx_mm = dy_mm = 15`, which stretched the X/Y map axes
by ~1.2 %. This has been corrected in `analysis/parte3.m` (and, for consistency,
`parte1.m` / `parte5.m`, where `dx,dy` were defined but unused). Dose values were
never affected — the phantom mass in `DetectorConstruction` already uses the real
pitch, and the exported dose is in Gy.

### 3. `SteppingAction` neutron-kill is silently inactive (no effect on results)
`SteppingAction.cc` tries to kill neutrons that leave the phantom by looking up a
region named `"PhantomRegion"`:
```cpp
fPhantomRegion = G4RegionStore::GetInstance()->GetRegion("PhantomRegion", false);
if (!fPhantomRegion) return;   // <-- always returns here
```
But `DetectorConstruction` never creates a region with that name, so the lookup
returns `nullptr` and the action does nothing. This was intended as a **CPU
optimization** (stop tracking neutrons once they escape). Its absence does **not**
change the scored dose, because the sensitive detector only exists on voxels inside
the phantom — neutrons outside deposit no dose there. Impact: slightly longer run
time. Documented here rather than "fixed" to keep the simulation code untouched.

### 4. Report used nominal voxel size (15×15×2 mm, ≈450 mm³)
The original report quotes the nominal design. The **real** voxel is
14.8148 × 14.8148 × 2.0 mm ≈ **438.96 mm³**. The rewritten report in `docs/report/`
uses the accurate figures with a short footnote.

### 5. Source `phantomFrontZ = -15 cm` vs phantom half-Z = 20 cm (simulation only)
In `PrimaryGeneratorAction`, the source is placed relative to `phantomFrontZ =
-15 cm`, while the phantom spans ±20 cm in Z. This shifts where SSD is measured
from by 5 cm. It does not affect the MATLAB analysis (depth is taken relative to
the first non-zero voxel), but it is worth revisiting if absolute SSD accuracy
matters. Left unchanged (simulation scope).

### Suggested future improvements
- Center the 2D/3D map axes on the beam (currently plotted in raw index units).
- Report LET / RBE-weighted dose for the neutron component.
- Add variance-reduction to lower the ~5 % voxel-wise SEM at fixed CPU cost.
- Add clinical spectra and an accelerator head instead of ideal monoenergetic beams.

---

## 🇪🇸 Español

### 1. Comentarios engañosos en `DetectorConstruction.cc` (cosmético, sin cambios)
El constructor calcula la malla así:
```cpp
fNVoxX = int(400.0*mm / 15.0*mm + 0.5);  // el comentario dice "100" pero es 27
fNVoxZ = int(400.0*mm /  2.0*mm + 0.5);  // el comentario dice "400" pero es 200
```
Los `// 100`, `// 400` y los comentarios de "4mm×1mm" son **restos viejos** de un
diseño de vóxel anterior. La malla **real** es **27 × 27 × 200**, que es justo la
que usan los scripts de MATLAB, así que **no hay desajuste de dimensiones** entre
la simulación y el análisis. Solo los comentarios están mal. (Se deja tal cual: no
se modifica el código de simulación.)

### 2. El paso real de vóxel X/Y es 14.8148 mm, no 15 mm — **corregido en MATLAB**
Como 400 mm no es divisible entre 15 mm, redondear a 27 vóxeles obliga a un paso
real de `400/27 = 14.8148 mm` en X/Y (Z es exacto: `400/200 = 2 mm`). El script de
mapas usaba antes `dx_mm = dy_mm = 15`, lo que estiraba los ejes X/Y de los mapas
~1.2 %. Se corrigió en `analysis/parte3.m` (y, por consistencia, en `parte1.m` /
`parte5.m`, donde `dx,dy` estaban definidos pero sin usar). Los valores de dosis
nunca se vieron afectados: la masa del fantoma en `DetectorConstruction` ya usa el
paso real y la dosis exportada está en Gy.

### 3. El "mata-neutrones" de `SteppingAction` está inactivo (sin efecto en resultados)
`SteppingAction.cc` intenta eliminar los neutrones que salen del fantoma buscando
una región llamada `"PhantomRegion"`:
```cpp
fPhantomRegion = G4RegionStore::GetInstance()->GetRegion("PhantomRegion", false);
if (!fPhantomRegion) return;   // <-- siempre sale aquí
```
Pero `DetectorConstruction` nunca crea una región con ese nombre, así que la
búsqueda devuelve `nullptr` y la acción no hace nada. Era una **optimización de
CPU** (dejar de seguir neutrones al escapar). Su ausencia **no** cambia la dosis
registrada, porque el detector sensible solo existe en los vóxeles dentro del
fantoma: los neutrones fuera no depositan dosis ahí. Impacto: tiempo de cómputo un
poco mayor. Se documenta en vez de "corregir" para no tocar la simulación.

### 4. El reporte usaba el tamaño nominal de vóxel (15×15×2 mm, ≈450 mm³)
El reporte original cita el diseño nominal. El vóxel **real** es
14.8148 × 14.8148 × 2.0 mm ≈ **438.96 mm³**. El reporte reescrito en `docs/report/`
usa las cifras exactas con una nota al pie.

### 5. Fuente en `phantomFrontZ = -15 cm` vs medio-Z del fantoma = 20 cm (solo sim.)
En `PrimaryGeneratorAction`, la fuente se coloca respecto a `phantomFrontZ =
-15 cm`, mientras que el fantoma abarca ±20 cm en Z. Eso corre 5 cm el punto desde
el que se mide el SSD. No afecta el análisis de MATLAB (la profundidad se toma
respecto al primer vóxel con dosis), pero conviene revisarlo si importa la
exactitud absoluta del SSD. Se deja sin cambios (ámbito de simulación).

### Mejoras futuras sugeridas
- Centrar los ejes de los mapas 2D/3D en el haz (hoy se grafican en índices crudos).
- Reportar dosis pesada por LET / RBE para la componente neutrónica.
- Añadir reducción de varianza para bajar el SEM (~5 %) por vóxel a igual CPU.
- Incorporar espectros clínicos y cabezal de acelerador en vez de haces
  monoenergéticos ideales.
