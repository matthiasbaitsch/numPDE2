# TODO: Umstellung der Notebooks

## Notebooks als `.qmd` verwalten

- [X]  Quellen in `bausteine/*/*/projekt*/` als `folien.qmd` bzw. `aufgaben.qmd` statt `.ipynb` einchecken
  (bestehende Notebooks einmalig konvertieren, z.B. `quarto convert`).
- [X]  Lernpfad-Skript (`try_zip_notebook` in `skripte/make-learning-path.jl`): `.qmd` erst beim
  Bereitstellen nach `.ipynb` konvertieren und dann wie bisher zippen. Dabei das Gerüst aus der Musterlösung
  erzeugen statt doppelt pflegen. In `aufgaben/projekt-musterloesung/aufgaben.qmd` markieren:
  - `#| keep: true` – Code-Zelle bleibt im Gerüst stehen, alle übrigen Code-Zellen werden geleert
    (nicht `{julia keep}`: solche Zellen führt Quarto nicht aus).
  - `::: {.loesung}` – Markdown (Antworten auf Fragen) fehlt im Gerüst.
  - `#|`-Zeilen in beiden Fassungen entfernen.

  Stufe pro Baustein in `about.yaml`, z.B. `geruest: voll | ueberschriften | keins` (Vorgaben über das Semester
  abbauen: voll am Anfang, nur Überschriften und Vorgabe-Zellen gegen Ende von Bohrpfahl, kein Gerüst bei
  Wärmeleitung). Danach `aufgaben/projekt/aufgaben.qmd` (01–04) löschen; Markierungen einmalig durch Vergleich
  mit den bisherigen Gerüsten setzen (Zellen mit Code im Gerüst → `keep: true`). CLAUDE.md anpassen.

  Überschrift im erzeugten Notebook vom Skript setzen, wie bei Folien und Aufgabenblättern („Teil: Titel“ aus
  `about.yaml`); von Hand gesetzte Titelzeilen in den `.qmd` (z.B. `# Bohrpfahl: Grundlagen`) dann entfernen.

  Genauso bei den Folien: `folien/projekt/folien.qmd` aus `folien/projekt-fertig/folien.qmd` erzeugen und dann
  löschen (01–03).

  Umgesetzt mit Blöcken `::: {.solution}` und `::: {.scaffold}` für alle Arten von Inhalt (statt `keep`
  und `.loesung`); Details in CLAUDE.md. `target: scaffold` in 01–04 (wie bisher), ohne `target` nur Musterlösung; `target: blank` für später, wenn die Studierenden weniger Hilfe bekommen.
- [X]  Pre-Commit-Hook `githooks/pre-commit` (nbstripout) entfernen, sobald keine `.ipynb` mehr eingecheckt sind.
- [X]  Aufräumen: `folien copy.ipynb` in `03-approximation-von-funktionen/folien/projekt-fertig/` (war das aktuelle
  fertige Notebook, ersetzt `folien.qmd`).
- [X]  CLAUDE.md (Abschnitte Notebooks, Pre-Commit-Hook) anpassen.

## Download-Link in den PDF-Folien

- [X]  Der Link auf der Folie „Material“ (`[⬇ Notebook zu den Folien herunterladen](…-folien.zip)`, erzeugt in
  `skripte/make-learning-path.jl`) funktioniert in den PDF-Folien nicht. Jetzt absolute URL zur
  GitHub-Seite (`SITE_URL` im Skript).

## IJulia

- [X]  Ausprobieren, ob das Arbeiten mit den Notebooks mit IJulia besser funktioniert. Ergebnis: verworfen,
  weil das Variablenfenster in VS Code mit IJulia leer bleibt (`varinfo()` als Ersatz scheitert an KaTeX).
  Es bleibt beim Kernel der Julia-Erweiterung.

## Paketversionen in git

- [X]  `Manifest.toml` aus `.gitignore` nehmen und einchecken.
- [X]  `bausteine/00-templates/Manifest.toml` von `make copy-templates` mitverteilen lassen.
- [X]  MMJMesh bleibt bewusst nicht fest: `rev = "main"` in `Project.toml` und `Pkg.update("MMJMesh")` in
  `instantiate.jl` bleiben, damit Änderungen an MMJMesh im Semester bei den Studierenden ankommen (nach erneutem
  Ausführen von `instantiate.jl`). Alle übrigen Pakete legt das Manifest fest.

## Revise für die Studierenden

- [X]  Revise in die Projektvorlage (`bausteine/00-templates/Project.toml`) aufnehmen.
- [X]  In den Notebooks `src/*.jl` mit `includet` statt `include` laden (mit `using Revise` in derselben Zelle).
- [X]  Aufgabentexte und Musterlösungen entsprechend anpassen (die Aufgabentexte erwähnen `include` nicht).
