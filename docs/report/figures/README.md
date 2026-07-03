# Figures / Figuras

*Bilingual. / Bilingüe.*

## 🇬🇧 English
Both `report_es.tex` and `report_en.tex` use a `\smartfig` command: if the PNG below
exists in this folder it is embedded; if not, a placeholder box is shown and the
document **still compiles**. Export these from the MATLAB scripts (`parte3.m`,
`parte5.m`) and save them here with **exactly** these names:

| File name | Source | What it shows |
|---|---|---|
| `esquema_geometrico.png` | your own diagram | geometry sketch of the phantom + beam |
| `visualizador_18MeV.png` | Geant4 visualizer screenshot | beam tracks at 18 MeV |
| `PDD_comparacion.png` | `parte2.m` | PDD curves for all energies |
| `Hist_DosisMax_6MeV.png` | `parte5.m` | histogram of D_max, 6 MeV |
| `Hist_DosisMax_10MeV.png` | `parte5.m` | histogram of D_max, 10 MeV |
| `Hist_DosisMax_12MeV.png` | `parte5.m` | histogram of D_max, 12 MeV |
| `Hist_DosisMax_15MeV.png` | `parte5.m` | histogram of D_max, 15 MeV |
| `Hist_DosisMax_18MeV.png` | `parte5.m` | histogram of D_max, 18 MeV |
| `Maps2D_15MeV.png` | `parte3.m` | 2D MIP dose maps, 15 MeV |
| `Map3D_15MeV_Total.png` | `parte3.m` | 3D dose map, total |
| `Map3D_15MeV_eminus.png` | `parte3.m` | 3D dose map, electrons |
| `Map3D_15MeV_eplus.png` | `parte3.m` | 3D dose map, positrons |
| `Map3D_15MeV_neutron.png` | `parte3.m` | 3D dose map, neutrons |
| `Map3D_15MeV_other.png` | `parte3.m` | 3D dose map, other secondaries |

Tip: in MATLAB, `exportgraphics(gcf, 'figures/Maps2D_15MeV.png', 'Resolution', 300)`
gives clean 300-dpi PNGs. PDF/EPS also work if you change the extension in the `.tex`.

## 🇪🇸 Español
Tanto `report_es.tex` como `report_en.tex` usan el comando `\smartfig`: si el PNG de
abajo existe en esta carpeta, se incrusta; si no, se muestra un recuadro-guía y el
documento **compila igual**. Expórtalos desde los scripts de MATLAB (`parte3.m`,
`parte5.m`) y guárdalos aquí con **exactamente** estos nombres (ver la tabla en la
sección en inglés — los nombres de archivo son los mismos).

Consejo: en MATLAB, `exportgraphics(gcf, 'figures/Maps2D_15MeV.png', 'Resolution',
300)` da PNG limpios a 300 dpi. También sirven PDF/EPS si cambias la extensión en
el `.tex`.
