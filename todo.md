# TODO

- [X]  Aufgabenblätter ohne Inhaltsverzeichnis
- [X]  Bibliographie bei Aufgaben pdf raus
- [X]  Folien nur als PDF
- [X]  Simplify issue in MMJMesh - broken test
- [X]  DotMaps ist aus der Projektvorlage entfernt: Aufgabentext 4.1 (`04-numerische-loesung/aufgaben/01-exakte-loesung.qmd`)
  und die Musterlösungen in 04 und 05 von `p = DotMap()` auf NamedTuples umstellen (wie in 07).
- [ ]  Musterlösungen zu den Aufgaben auf Papier (Herleitungen, Skizzen, Handrechnungen) erstellen. Material:
  Musterlösungen zu den LaTeX-Übungsblättern in `../../numPDE/04-uebungsaufgaben/uebungsblatt-*/01-musterloesung`.
- [ ]  Baustein **Elastizität** anlegen. Inhalt: ebene Elastizität, Finite-Elemente-Formulierung mit mehreren
  Feldern. Material: Notizen NP 2D 08, Skript 1.0 Kapitel 3, Lösungs-Notebooks `11-elasticity2d*` und `cst.jl` in
  `../../numPDE_2.0/loesungen`.
- [ ]  Baustein **Geometrisch nichtlineare Analyse** anlegen. Inhalt: Grundlagen der nichtlinearen
  Kontinuumsmechanik, Finite-Elemente-Diskretisierung, Lösung des nichtlinearen Gleichungssystems. Material: Skript
  1.0 Kapitel 4, `../../numPDE/07-matlab/05-nonlinear-structural-mechanics`.
- [ ]  Idee, nicht dringend: `skripte/make-learning-path.jl` mit dem Informatik-Projekt
  (`../../informatik-master_2.0/unterlagen/skripte/lernpfad-zusammenstellen.jl`) zusammenführen, z.B. als gemeinsames Repo analog zu `tinh`.
  Unterschiede: Zip-Inhalte (C# bzw. Julia), `teil` in Folientitel und Buchteilen, `veranstaltung` nur hier,
  Duplikat-Check und dotnet nur in Informatik. Angehen, sobald dieselbe Verbesserung mehrfach in beiden Kopien
  nachgezogen werden muss. Mathe B bleibt außen vor (R-Pipeline mit Submodulen, zu verschieden).
- [ ]  Folien zur Einführung (`lernpfad/veranstaltung/einfuehrung/folien.qmd`) zusätzlich als PDF
  (`tinh-slides-typst` neben Reveal.js, mit `shift-heading-level-by: 0` wie bei den Bausteinfolien). Prüfen, wie
  revealjs-spezifische Klassen wie `.down80` im PDF wirken.
- [ ]  Skript zur Veranstaltung schreiben und die Folien daraus ableiten. Bis dahin sind die Folien die
  handschriftlichen Notizen (`bausteine/*/folien/notizen/`, seitenweise eingebunden in `folien/folien.qmd`).
