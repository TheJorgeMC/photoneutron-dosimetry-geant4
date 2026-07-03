# Report / Reporte

*Bilingual. / Bilingüe.*

Two standalone reports, same content in two languages:
- `report_en.tex` — English
- `report_es.tex` — Spanish
- `references.bib` — shared bibliography
- `figures/` — put your PNGs here (see `figures/README.md`)

## 🇬🇧 English — compile on Overleaf
1. Create a new Overleaf project and upload `report_en.tex` (or `report_es.tex`),
   `references.bib`, and the `figures/` folder.
2. Set the **main document** to the `.tex` you want and the compiler to **pdfLaTeX**.
3. Compile. Overleaf runs BibTeX automatically; locally use:
   ```bash
   pdflatex report_en
   bibtex   report_en
   pdflatex report_en
   pdflatex report_en
   ```
The reports compile even with an empty `figures/` folder (placeholders appear where
images are missing), so you can build first and add figures later.

Both files are plain `article` class — no institutional template required. Edit the
author block, keywords, or `\bibliographystyle` as needed.

## 🇪🇸 Español — compilar en Overleaf
1. Crea un proyecto nuevo en Overleaf y sube `report_es.tex` (o `report_en.tex`),
   `references.bib` y la carpeta `figures/`.
2. Marca como **documento principal** el `.tex` deseado y el compilador **pdfLaTeX**.
3. Compila. Overleaf corre BibTeX solo; en local usa:
   ```bash
   pdflatex report_es
   bibtex   report_es
   pdflatex report_es
   pdflatex report_es
   ```
Los reportes compilan aunque `figures/` esté vacía (aparecen recuadros-guía donde
falten imágenes), así que puedes compilar primero y agregar figuras después.

Ambos usan la clase `article` estándar (sin plantilla institucional). Ajusta el
bloque de autores, las palabras clave o `\bibliographystyle` según necesites.
