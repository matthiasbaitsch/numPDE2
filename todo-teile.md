# TODO: Teile als Ordnerebene in `bausteine/`

Ziel: `bausteine/<teil>/<NN-baustein>/` mit `about.yaml` im Teilordner (mindestens `titel`), das Feld `teil` in den
`about.yaml` der Bausteine entfällt. Die Ebene ist optional, damit Informatik (keine Teile, flach) und später
Mathe B (mit Teilen) dasselbe Skript verwenden können.

## Vorher entscheiden

- [ ]  Nummerierung der Bausteine: fortlaufend über alle Teile (Vorschlag, Slugs, Links und Blattnummern bleiben
  gleich) oder je Teil neu (dann „Aufgabenblatt 1“ doppelt).
- [ ]  Teilordner ohne Nummer (`bohrpfahl`, `waermeleitung`, Reihenfolge aus den Bausteinnummern) oder mit.
- [ ]  Inhalt des Teil-`about.yaml`: nur `titel` oder auch Beschreibung des Modellproblems.

## Umsetzen

- [ ]  `skripte/make-learning-path.jl`: `building_blocks` zweistufig – Ordner mit `about.yaml` und `folien/` oder
  `aufgaben/` ist ein Baustein, sonst ein Teil; Bausteine erben `teil` vom Teil, ohne Teilordner kein Teil.
- [ ]  `skripte/copy-templates.jl`: Regex für den Workspace-Namen (`bausteine/\d\d-…/`) um die optionale Teilebene
  erweitern.
- [ ]  Ordner mit `git mv` verschieben, `teil` aus den `about.yaml` entfernen, `make copy-templates`.
- [ ]  Prüfen, ob `bausteine/_metadata.yml` (Vorschau) und `_setup.jl` (über `Base.active_project()`) aus der
  tieferen Ebene weiter gefunden werden.
- [ ]  CLAUDE.md anpassen: Projektstruktur, Pfadmuster (`bausteine/*/*/projekt*`), Absatz zu `teil`.
