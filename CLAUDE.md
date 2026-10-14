# Vorlesungsunterlagen Numerik partieller Differentialgleichungen – Master Bau- und Umweltingenieurwesen

## Kontext

Dieses Projekt enthält die Lehrveranstaltungsunterlagen für das Modul **Numerik partieller Differentialgleichungen** im **Master Bau- und Umweltingenieurwesen** an der **Hochschule Bochum**.

Die Veranstaltung basiert auf der ersten Fassung `../../numPDE` und dem ersten Neuorganisationsversuch `../../numPDE_2.0`. Eine Übersicht über deren Inhalte steht in `bestandsaufnahme-vorgaenger.md`.

Aufbau und Werkzeuge folgen dem Informatik-Projekt `../../informatik-master_2.0/unterlagen`.

## Projektstruktur

- Inhalte liegen in `bausteine/NN-thema/` mit `about.yaml` (Titel, Teil, Inhalt, Dauer), `folien/folien.qmd`, `aufgaben/*.qmd` und jeweils `bilder/`.
- In `lernpfad/` werden nur die Unterordner `c/` sowie `folien-alle/` automatisch generiert (`skripte/lernpfad-zusammenstellen.jl`, aufgerufen über `make prepare-render`) – nie manuell bearbeiten, alle inhaltlichen Änderungen gehen in `bausteine/`. Die Konfigurationsdateien direkt in `lernpfad/aufgaben/` und `lernpfad/folien/` (`_metadata.yml`) sind eingecheckt und dürfen bearbeitet werden.
- Die Bausteine sind über das Feld `teil` in `about.yaml` nach Modellproblemen gruppiert: `Bohrpfahl (1D)` (01–05), `Wärmeleitung (2D)` (06–09). Ordnernamen und Nummern enthalten den Teil bewusst nicht; das Skript bildet daraus die Buchteile in `lernpfad/folien-alle`. Geplante Bausteine (Elastizität, geometrisch nichtlineare Analyse) stehen in `todo.md`.
- Folien der Bausteine sind vorerst die handschriftlichen Notizen (englisch, PDF im Querformat) in `bausteine/NN/folien/notizen/`. `skripte/notizen-zu-folien.jl` (Teil von `make prepare-render`) erzeugt daraus pro Seite ein Bild `folien/bilder/notizen-*.png` und die Datei `folien/folien.qmd` mit einer Folie pro Seite. Beides ist generiert und per `.gitignore` ausgeschlossen – nicht bearbeiten. Langfristig sollen die Folien aus einem Skript abgeleitet werden (siehe `todo.md`); dann die `.gitignore`-Regel für `folien.qmd` entfernen.
- `lernpfad/veranstaltung/` enthält Folien, die nur zu dieser Veranstaltung gehören und keinem Baustein zugeordnet sind (z.B. Einführung), wie in `~/sciebo/mathematik-fbb/mathematik-b_2.0/unterlagen`. Die Quellen liegen lokal, ein Ordner je Foliensatz (`einfuehrung/` mit `folien.qmd`, ggf. `bilder/`, `daten/`, `skripte/`). Die Reihenfolge steht in `veranstaltung_parts` in `skripte/lernpfad-zusammenstellen.jl`, das sie nach `lernpfad/veranstaltung/c/NN-name.qmd` kopiert (Affinity-/Graffle-Dateien ausgenommen).
- Aussehen und gemeinsame Format-Optionen kommen aus der Quarto-Extension `tinh` (Repo `matthiasbaitsch/quarto-tinh`, lokal `~/sciebo/lehrveranstaltungen/quarto-tinh`), eingecheckt unter `_extensions/`. Stiländerungen nur im Extension-Repo machen, pushen und dann `make update-extension` – die Kopie in `_extensions/` nicht direkt bearbeiten. Das HSBO-Logo kommt aus `_brand.yml`.
- Skripte (Julia) liegen in `skripte/` und dürfen direkt bearbeitet werden.
- `bestandsaufnahme-vorgaenger.md` – Bestandsaufnahme von `../../numPDE` und `../../numPDE_2.0`

## Technischer Aufbau

- **Format:** Quarto (`.qmd`), Deutsch
- **Ausgabeformate:** Reveal.js-Folien (`tinh-slides-revealjs`) und HTML-Seiten (`tinh-notes-html`, Aufgaben `tinh-assignments-*`)
- **Programmierung:** Julia mit der eigenen Bibliothek MMJMesh (`github.com/matthiasbaitsch/mmjmesh`) und CairoMakie
- Julia-Code in Folien und Aufgaben ist **statisch** (wird beim Rendern nicht ausgeführt); bei Bedarf einzeln anpassen

## Zusammenarbeit mit dem Nutzer

- Den Nutzer duzen
- Auf Fragen („wie geht…?", „kann ich…?", „warum…?") zuerst nur erklären – Dateien erst ändern, wenn der Nutzer ausdrücklich darum bittet

## Hinweise zur Zusammenarbeit

- Notizen und Erinnerungen gehören in diese Datei (`CLAUDE.md`)
- Kein Memory-Verzeichnis anlegen – weder im Projekt noch anderswo. Das eingebaute auto-memory-System nicht verwenden.

## Inhaltliche Richtlinien

- Alle Texte auf **Deutsch** (Siezen: „Sie"); **Ausnahme Folien:** dürfen englisch sein, damit die Studierenden die englische Terminologie lernen
- Abstrakte mathematische Konzepte (lineare Räume, Bilinearformen, Variationsprobleme, …) werden **unterwegs eingeführt**, jeweils nur das, was am Modellproblem gerade benötigt wird – bewusst anders als in der mathematischen Literatur, wo die Theorie vorab aufgebaut wird. Nicht als Mangel werten und keine vorgezogenen Theorie-Bausteine vorschlagen.
