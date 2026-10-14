# Bestandsaufnahme der Vorgängerversionen

Stand: 2026-10-14. Überblick über die Materialien in `../../numPDE` (erste Fassung) und `../../numPDE_2.0` (erster Neuorganisationsversuch) als Grundlage für numPDE 2.1.

## Überblick

| | numPDE (1.0) | numPDE_2.0 |
|---|---|---|
| Sprache | Englisch | Deutsch (Siezen) |
| Textformat | LaTeX (Skript, Beamer, Übungsblätter) | Quarto (`.qmd`) |
| Programmierung | MATLAB (+ Mathematica, teils Python/Julia) | Julia mit MMJMesh |
| Gliederung | Kapitel (Skript) bzw. Übungsblätter | Aufgabenblätter bzw. „Pakete" |
| Versionskontrolle | nein | Git |
| Inhaltliche Breite | 1D bis geometrisch nichtlinear 2D | Aufgaben: 1D + 2D-Wärmeleitung; Lösungen bis 2D-Elastizität |

## numPDE (erste Fassung)

### Skript – `01-skript/`

LaTeX-Buch (`numpde-script.tex`, Inhalt in `contents.tex`), englisch, vier Kapitel:

1. Problems in one dimension: Pile foundation (Bohrpfahl)
2. Problems in two dimensions: Stationary heat transfer
3. Problems with multiple fields: 2D structural mechanics
4. Geometrically nonlinear analysis of 2D structures

### Folien – `02-folien/`

Beamer-Folien, gemeinsame Makros in `common/`, PDFs in `99-pdf/`.

- Aktiv: `00-einfuehrung`, `01-fem-for-1d-problems`, `02-fem-for-2d-heat-transfer`
- Mit `x`-Präfix (alt bzw. ungenutzt): `x02-fem-for-higher-dimensions` (u.a. Raumakustik), `x03-structural-mechanics`, `xA-linear-spaces`, `xslides-hofem`

### Handschriftliche Notizen – `03-notizen/`

- `1D/`: „NP 1D 01–13" – Introduction, Strong form, Weak form, Properties of weak form, Linear spaces, Properties of a and b, Abstract variational problem, Approximation of functions, Subspaces, Numerical solution, Pile foundation (11.1–11.4: Beiträge von C, S, Lastvektor), Element-wise computation of K and r, Summary
- `2D/`: Wärmeleitung (NP 2D 00–07: Mathematische Grundlagen, Randwertproblem, schwache Form, FE-Formulierung, Dirichlet-RB, Netzgenerierung, Robin-RB, instationär) und Elastizität (NP 2D 08)

Identisch in `numPDE_2.0/notizen/` vorhanden.

### Übungsblätter – `04-uebungsaufgaben/`

- LaTeX-Blätter `uebungsblatt-01` bis `-09` (ohne `-05`, das liegt als `.unused` vor), jeweils mit `01-musterloesung/`
- Varianten: `uebungsblatt-04-python`, `uebungsblatt-04-julia`, zusätzlich `isoparametric-heat-element`
- Gemeinsames in `00-common/`, PDFs in `99-pdf/`

### Code und Material

- `05-matlab/`: Live-Scripts (mathematische Grundlagen 2D, Finite Differenzen, Netzgenerierung mit Gmsh)
- `06-mathematica/`: Green-Lagrange-Verzerrung, Massenmatrix Dreieck
- `07-matlab/`: MATLAB-Code nach Themen – `00-grundlagen-matlab`, `01-pile-foundation`, `02-heat-transfer`, `03-transient-heat-transfer`, `04-structural-mechanics` (CST, Reissner-Mindlin), `05-nonlinear-structural-mechanics`
- `08-material/`: Paper, Baumechanik-Vorlesungen, PDE-Toolbox-Beispiel Wärmebrücke, Bilder
- `09-software/`: `MMJMesh.jl` (Kopie der eigenen Julia-Bibliothek, mit eigener CLAUDE.md), Gmsh-Anbindungen für Python/Julia/MATLAB, `julia-demo`
- `10-studienarbeit/`: Studienarbeiten 2015–2024
- `12-moodle/`: Moodle-Exporte (PDFs, Notebooks, Zips)
- `99-old/`: umfangreiche Altbestände (Java, COMSOL, Videos, vor-Corona-Material, ältere Übungen)

## numPDE_2.0 (erster Neuorganisationsversuch)

### Technik

- Git-Repo (Commit-Messages überwiegend „.")
- `_quarto.yml` minimal: `lang: de`, nummerierte Abschnitte, Ausgabe HTML und PDF; keine eigene Quarto-Extension
- Julia-Umgebung: CairoMakie, DotMaps, MMJMesh (von `github.com/matthiasbaitsch/mmjmesh`), teils Symbolics, Unitful; Installation über `install-dependencies.jl` bzw. `instantiate.jl`
- `.gitignore` schließt u.a. `attic`, `work`, `studienarbeit`, `videos`, `*.work`, `*.pdf`, `*.html` aus

### Aufgaben – `aufgaben/`

Acht Blätter, je Ordner `NN-thema/NN-thema.qmd` mit `bilder/` (SVG, Quellen als `.afdesign`), `engine: julia`:

1. Starke und schwache Form
2. Approximation von Funktionen
3. Numerische Lösung
4. Elementweise Berechnung (Assemblierung, Element-Steifigkeitsmatrix Bohrpfahl, Programmierung mit MMJMesh)
5. Wärmeleitung
6. Wärmeleitung – Dirichlet
7. Wärmeleitung – Robin
8. Wärmeleitung – instationär

In einigen Ordnern liegen LaTeX-Build-Reste (`out/`, `.aux`, `.log`, `.tex`).

### Lösungen – `loesungen/`

Jupyter-Notebooks (nummeriert passend zu den Aufgaben, teils mit Unternummern wie `06.1`, `08.3.2`) und Hilfsdateien:

- `fem.jl` – Assemblierung (`assemble_kr`, `assemble_kmr`), Freiheitsgrade, Dirichlet-RB
- `heat.jl`, `cst.jl`, `pile.jl` – Elementroutinen
- Reicht inhaltlich über die Aufgaben hinaus: Wand (`07-wall`), 2D-Elastizität (`11-elasticity2d*`)
- Diverse Test-Notebooks (`*-test.ipynb`), `old/`

### Codebeispiele – `codebeispiele/`

Notebooks `paket-01`, `paket-02`, `aufgabenblatt-01`. Deutet eine Gliederung in Pakete an, die nicht weiter ausgebaut ist.

### Sonstiges

- `notizen/`: handschriftliche Notizen (wie in 1.0) plus `b-matrix.pdf`, Material zu Tragwerksmodellen
- `studienarbeit/`: Arbeiten 2025 und 2026, Quarto-Folienvorlage für Studierendenvorträge (`folien-qmd/`)
- `videos/`: Final-Cut-Pro-Bibliothek
- Arbeits- bzw. Altordner: `work/`, `attic/`, `loesungen.work/`, `codebeispiele.work/` (letzterer u.a. mit Reissner-Mindlin- und 3D-Elastizitäts-Notebooks)

## Beobachtungen

- Der Wechsel 1.0 → 2.0 betrifft Sprache (Englisch → Deutsch), Werkzeuge (LaTeX/MATLAB → Quarto/Julia) und Gliederung (Kapitel → Aufgabenblätter/Pakete).
- In 2.0 gibt es **keine Folien und kein Skript**; Vorlesungsgrundlage sind weiterhin die handschriftlichen Notizen.
- In 2.0 fehlen Aufgaben zu **Strukturmechanik** und **geometrischer Nichtlinearität**; Ansätze existieren nur als Lösungs- bzw. Arbeitsnotebooks.
- Lösungs- und Codebeispiel-Notebooks sind verstreut über `loesungen/`, `loesungen.work/`, `codebeispiele/`, `codebeispiele.work/`, `work/` und `attic/` – welche Version aktuell ist, ist nicht ersichtlich.
- Die Aufgabenblätter in 2.0 sind die am weitesten ausgearbeitete, direkt wiederverwendbare Komponente.
- Das Informatik-Master-Projekt (`../../informatik-master_2.0/unterlagen`) zeigt bereits eine ausgereifte Struktur (`bausteine/`, `lernpfad/`, `about.yml` je Themenpaket, Quarto-Extension `tinh`), die als Vorbild für 2.1 dienen könnte.
