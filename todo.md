# TODO

## Bis zum nächsten Termin

* [X]  MuLö Hermite
* [ ]  Abschnitt 04 fertigmachen
  * [ ]  Elastisch gelagerter Balken: Die Musterlösung verwendet `hermitefunctions(…, midnode=true)`, der Tipp auf
    dem Blatt `hermitefunctions(nodes)`. Entweder `midnode=true` in den Tipp oder die Lösung mit mehreren Elementen.
  * [ ]  `aufgaben/reserve/01-exakte-loesung.qmd` enthält noch die alte Mathematica-Formel statt der geschlossenen
    Lösung.
* [ ]  Beim Rendern prüfen: Lösungsblätter 01 und 03 (Lösung in der Aufgabe, auf dem Aufgabenblatt nicht zu
  sehen, Größe der neuen PNGs), Plotgröße in Typst (`is_typst()` in `_setup.jl`), `fig-align` bei Bildern ohne
  Bildunterschrift.
* [ ]  Baustein 05 überarbeiten: alte Überschriften (`# Aufgabe 5.2b`), `IntervalSets` fehlt in der Projektvorlage
  (ohne ist `..` mehrdeutig), `DimensionMismatch` in `fem.jl:41` (vermutlich `nodeindices` eines Knotens leer in
  der aktuellen MMJMesh-Version).

## Inhalte langfristig

- [X]  Musterlösungen zu den Aufgaben auf Papier (Herleitungen, Skizzen, Handrechnungen) erstellen. Material:
  Musterlösungen zu den LaTeX-Übungsblättern in `../../numPDE/04-uebungsaufgaben/uebungsblatt-*/01-musterloesung`.
  Erledigt für 01 und 03.
- [ ]  Baustein **Elastizität** anlegen. Inhalt: ebene Elastizität, Finite-Elemente-Formulierung mit mehreren
  Feldern. Material: Notizen NP 2D 08, Skript 1.0 Kapitel 3, Lösungs-Notebooks `11-elasticity2d*` und `cst.jl` in
  `../../numPDE_2.0/loesungen`.
- [ ]  Baustein **Geometrisch nichtlineare Analyse** anlegen. Inhalt: Grundlagen der nichtlinearen
  Kontinuumsmechanik, Finite-Elemente-Diskretisierung, Lösung des nichtlinearen Gleichungssystems. Material: Skript
  1.0 Kapitel 4, `../../numPDE/07-matlab/05-nonlinear-structural-mechanics`.
- [ ]  Skript zur Veranstaltung schreiben und die Folien daraus ableiten. Bis dahin sind die Folien die
  handschriftlichen Notizen (`bausteine/*/folien/notizen/`, seitenweise eingebunden in `folien/folien.qmd`).

## Extension `tinh`

- [ ]  `#notiz` in die Extension `tinh-slides-typst` übernehmen
  (`~/sciebo/lehrveranstaltungen/quarto-tinh`, dann `make update-extension`). Danach die Definitionen in
  `lernpfad/folien/_metadata.yml` und die Kopie in `bausteine/_metadata.yml` löschen. Vorteil: Folien lassen sich
  direkt in `bausteine/` ansehen, und Informatik und Mathe B können die Funktion mitbenutzen.
- [ ]  In der Extension zusätzlich eine Funktion, die eine PDF-Seite als Bild über die ganze Folienbreite einbindet
  (normale Folie mit Titel, nicht randlos wie `#notiz`), z.B. für einzelne Ausschnitte aus Notizen oder Skizzen.
- [ ]  In der Extension eine Funktion `#demo("…")` für Demo-Folien (einheitlich gestaltet, z.B. Notebook-Symbol
  und farbiger Hintergrund). Bis dahin sind Demos normale Folien `## Demo: …` mit den Abschnitten im Folien-Notebook
  (bisher in 01 bis 03).
- [ ]  Informatik und Mathe B wie hier auf `tinh-notebook` und `.tinh-solution`/`.tinh-scaffold` umstellen (siehe
  `todo.md` in quarto-tinh); in Mathe B zusätzlich die `.sol.qmd` als `.tinh-solution` in die Aufgaben übernehmen.

## Lernpfad-Skript

- [ ]  Prüfen, ob die Kopie von `_metadata.yml` nach `c/` (`copy_common_files`) nötig ist: Quarto liest die
  `_metadata.yml` aller Ordner bis zur Projektwurzel, also auch `lernpfad/aufgaben/_metadata.yml` beim Rendern von
  `c/`. Haken: relative Pfade (`bibliography`, `csl`) beziehen sich vermutlich auf den Ordner der
  `_metadata.yml`. Gleiche Lösung wie in Informatik.
- [ ]  Idee, nicht dringend: `skripte/make-learning-path.jl` mit dem Informatik-Projekt
  (`../../informatik-master_2.0/unterlagen/skripte/lernpfad-zusammenstellen.jl`) zusammenführen, z.B. als gemeinsames Repo analog zu `tinh`.
  Unterschiede: Zip-Inhalte (C# bzw. Julia), `teil` in Folientitel und Buchteilen, `veranstaltung` nur hier,
  Duplikat-Check und dotnet nur in Informatik. Angehen, sobald dieselbe Verbesserung mehrfach in beiden Kopien
  nachgezogen werden muss. Mathe B bleibt außen vor (R-Pipeline mit Submodulen, zu verschieden).

## Erledigt

- [X]  Aufgabenblätter ohne Inhaltsverzeichnis
- [X]  Bibliographie bei Aufgaben pdf raus
- [X]  Folien nur als PDF
- [X]  Simplify issue in MMJMesh - broken test
- [X]  DotMaps ist aus der Projektvorlage entfernt: Aufgabentext 4.1 (`04-numerische-loesung/aufgaben/01-exakte-loesung.qmd`)
  und die Musterlösungen in 04 und 05 von `p = DotMap()` auf NamedTuples umstellen (wie in 07).
- [X]  Folien zur Einführung (`lernpfad/veranstaltung/einfuehrung/folien.qmd`) zusätzlich als PDF
  (`tinh-slides-typst` neben Reveal.js). Prüfen, wie
  revealjs-spezifische Klassen wie `.down80` im PDF wirken.
