# TODO

- [ ]  Aufgabenblätter ohne Inhaltsverzeichnis.
- [ ]  Simplify issue in MMJMesh - broken test
- [ ]  Pre-Commit-Hook für Kopien in `aufgaben/projekt-musterloesung/src/` (z.B. `fem.jl`). Zunächst
  `githooks/pre-commit` und `skripte/duplikate.jl` aus dem Informatik-Projekt unverändert übernehmen (erkennt
  einseitig geänderte, bisher identische Kopien). Dann erweitern: Ändert sich eine Datei in einem früheren Baustein,
  schreibt der Hook in alle gleichnamigen Dateien späterer Bausteine eine Zeile `# TODO(sync): …` und bricht den
  Commit ab. Änderungen, die nur aus `TODO(sync)`-Zeilen bestehen, ignorieren; keine doppelten TODOs. Erweiterung
  möglichst auch ins Informatik-Projekt übernehmen.
- [ ]  Musterlösungen zu den Aufgaben auf Papier (Herleitungen, Skizzen, Handrechnungen) erstellen. Material:
  Musterlösungen zu den LaTeX-Übungsblättern in `../../numPDE/04-uebungsaufgaben/uebungsblatt-*/01-musterloesung`.
- [ ]  Baustein **Elastizität** anlegen. Inhalt: ebene Elastizität, Finite-Elemente-Formulierung mit mehreren
  Feldern. Material: Notizen NP 2D 08, Skript 1.0 Kapitel 3, Lösungs-Notebooks `11-elasticity2d*` und `cst.jl` in
  `../../numPDE_2.0/loesungen`.
- [ ]  Baustein **Geometrisch nichtlineare Analyse** anlegen. Inhalt: Grundlagen der nichtlinearen
  Kontinuumsmechanik, Finite-Elemente-Diskretisierung, Lösung des nichtlinearen Gleichungssystems. Material: Skript
  1.0 Kapitel 4, `../../numPDE/07-matlab/05-nonlinear-structural-mechanics`.
- [ ]  Idee, nicht dringend: `skripte/lernpfad-zusammenstellen.jl` mit dem Informatik-Projekt
  (`../../informatik-master_2.0/unterlagen/skripte`) zusammenführen, z.B. als gemeinsames Repo analog zu `tinh`.
  Unterschiede: Zip-Inhalte (C# bzw. Julia), `teil` in Folientitel und Buchteilen, `veranstaltung` nur hier,
  Duplikat-Check und dotnet nur in Informatik. Angehen, sobald dieselbe Verbesserung mehrfach in beiden Kopien
  nachgezogen werden muss. Mathe B bleibt außen vor (R-Pipeline mit Submodulen, zu verschieden).
- [ ]  Skript zur Veranstaltung schreiben und die Folien daraus ableiten. Bis dahin sind die Folien die
  handschriftlichen Notizen (`bausteine/*/folien/notizen/`, umgewandelt von `skripte/notizen-zu-folien.jl`).
