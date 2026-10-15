# Vorlesungsunterlagen Numerik partieller Differentialgleichungen – Master Bau- und Umweltingenieurwesen

## Kontext

Dieses Projekt enthält die Lehrveranstaltungsunterlagen für das Modul **Numerik partieller Differentialgleichungen** im **Master Bau- und Umweltingenieurwesen** an der **Hochschule Bochum**.

Die Veranstaltung basiert auf der ersten Fassung `../../numPDE` und dem ersten Neuorganisationsversuch `../../numPDE_2.0`. Eine Übersicht über deren Inhalte steht in `bestandsaufnahme-vorgaenger.md`.

Aufbau und Werkzeuge folgen dem Informatik-Projekt `../../informatik-master_2.0/unterlagen`. Verwandt ist außerdem Mathematik B (`~/sciebo/mathematik-fbb/mathematik-b_2.0/unterlagen`). Die drei Projekte sind nahezu gleich aufgebaut und sollen sich möglichst wenig unterscheiden – bei Strukturfragen erst dort nachsehen und deren Lösung übernehmen. Langfristiges Ziel: `skripte/lernpfad-zusammenstellen.jl` projektübergreifend vereinheitlichen.

## Projektstruktur

- Inhalte liegen in `bausteine/NN-thema/` mit `about.yaml` (Titel, Teil, Inhalt, Dauer), `folien/folien.qmd`, `aufgaben/*.qmd` und jeweils `bilder/`.
- **Namensregel:** Von Hand vergebene Namen beschreiben nur den Inhalt (ohne Teil, ohne Baustein); alles, was vom Ort abhängt, erzeugt ein Skript. Bausteinordner `NN-slug`, Aufgaben `NN-inhalt.qmd`.
- **Notebooks:** Jedes Projekt zu Folien und Aufgaben enthält genau ein Notebook mit generischem Namen – `folien.ipynb` in `folien/projekt` und `folien/projekt-fertig`, `aufgaben.ipynb` in `aufgaben/projekt` (Gerüst, optional) und `aufgaben/projekt-musterloesung`. Mehrere Aufgaben stehen als Abschnitte `# Aufgabe 7.2: Kreisscheibe` im selben Notebook. Netze werden als `.geo` im Notebook geschrieben (`write("x.geo", raw"""…""")`), nur sehr umfangreiche Geometrien als eigene Datei. Ausnahme: `projekt-playground` (beliebig viele Notebooks, freie Namen, wird nicht ausgeliefert).
- **Auslieferung:** Die Studierenden laden nur Notebooks herunter, keine Projekte. Das Lernpfad-Skript kopiert sie unter dem Slug (mit Teil): `…-folien.ipynb` (auf der Titelfolie verlinkt), `…-folien-fertig.ipynb` (Referenz, separat verlinkt, z.B. Moodle), `…-aufgaben.ipynb` (in den Aufgaben verlinkt über `${slug}-aufgaben.ipynb`) und `musterloesungen/<hash>/…-musterloesung.ipynb` (Hash aus dem Slug, stabil). Die Studierenden richten einen Ordner `numerik-partieller-dgln/` mit `folien/`, `aufgaben/`, `projekt-folien/` und `projekt-aufgaben/` ein (dort wächst `src/` über die Bausteine), beschrieben im Foliensatz `lernpfad/veranstaltung/ordner-einrichten`. Die Struktur liegt dort unter `zip/numerik-partieller-dgln/` (leere Ordner mit `.gitkeep`); das Skript liefert jeden Ordner `lernpfad/veranstaltung/*/zip/<name>` als `<name>.zip` aus. Die Pakete installieren die Studierenden mit `instantiate.jl` (in jedem Projektordner, holt auch die aktuelle MMJMesh-Version) – keine `Pkg`-Zellen in den Notebooks.
- Musterlösungen zu Programmieraufgaben liegen in `aufgaben/projekt-musterloesung/` (Julia-Projekt mit `aufgaben.ipynb` und `src/`). `src/` legen sich die Studierenden selbst an und wird nicht ausgeliefert. `src/` enthält den Code-Stand nach Bearbeitung des Blatts; Dateien aus früheren Bausteinen (z.B. `fem.jl`) werden kopiert und weiterentwickelt. Änderungen an einer früheren Kopie werden vorerst von Hand in die späteren übertragen.
- Ausprobier- und Test-Notebooks liegen in `aufgaben/projekt-playground/` des Bausteins, zu dem sie gehören (nicht zwischen den Musterlösungen). Sie binden den Code aus `../projekt-musterloesung/src/` ein, statt eigene Kopien anzulegen.
- Der Pre-Commit-Hook `githooks/pre-commit` entfernt mit `nbstripout` die Ausgaben aus allen vorgemerkten Notebooks. Aktiviert pro Klon mit `git config core.hooksPath githooks`.
- In `lernpfad/` werden nur die Unterordner `c/` sowie `folien-alle/` automatisch generiert (`skripte/lernpfad-zusammenstellen.jl`, aufgerufen über `make prepare-render`) – nie manuell bearbeiten, alle inhaltlichen Änderungen gehen in `bausteine/`. Die Konfigurationsdateien direkt in `lernpfad/aufgaben/` und `lernpfad/folien/` (`_metadata.yml`) sind eingecheckt und dürfen bearbeitet werden.
- Die Bausteine sind über das Feld `teil` in `about.yaml` nach Modellproblemen gruppiert: `Bohrpfahl` (01–05), `Wärmeleitung` (06–09). Ordnernamen und Nummern enthalten den Teil bewusst nicht; das Skript bildet daraus die Buchteile in `lernpfad/folien-alle` und den Folientitel „Teil: Titel“. Bausteintitel deshalb so wählen, dass sie den Teil nicht wiederholen (z.B. „Grundlagen“ statt „Wärmeleitung“). Geplante Bausteine (Elastizität, geometrisch nichtlineare Analyse) stehen in `todo.md`.
- Vorlesungsnotebooks (in der Vorlesung live gemeinsam ausgefüllt): `folien/projekt/` enthält das Grundgerüst (Text und `using`-Zellen, übrige Code-Zellen leer), `folien/projekt-fertig/` den Endzustand, den die Studierenden am Ende selbst eingegeben haben sollen.
- `aufgaben/reserve/` enthält zurückgestellte Aufgaben, die wieder verwendet werden können. Sie sind eingecheckt, erscheinen aber nicht im Lernpfad (das Skript liest nur `.qmd` direkt in `aufgaben/`). Aufgabennummern zählen fortlaufend; beim Verschieben Verweise wie „Aufgabe 1.2“ und die Abschnittsüberschriften in `aufgaben.ipynb` anpassen.
- `Project.toml`, `instantiate.jl` und `.code-workspace` in allen Projektordnern (`bausteine/*/*/projekt*` und `lernpfad/veranstaltung/*/zip/*/projekt-*`) kommen aus `bausteine/00-templates` und werden mit `make copy-templates` verteilt (wie in Informatik) – Änderungen nur in der Vorlage. Der Workspace-Name wird dabei aus dem Ordner gebildet (`01-grundlagen-musterloesung.code-workspace`, mit Nummer, weil Titel sich wiederholen; in der Ordnerstruktur `projekt-folien.code-workspace`) und immer neu geschrieben – nie von Hand umbenennen.
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
- Folien: Titel ist das Thema, `subtitle` immer der Veranstaltungstitel „Numerik partieller Differentialgleichungen“ (bei Bausteinen setzt ihn das Lernpfad-Skript, bei `lernpfad/veranstaltung/*/folien.qmd` von Hand)
- Abstrakte mathematische Konzepte (lineare Räume, Bilinearformen, Variationsprobleme, …) werden **unterwegs eingeführt**, jeweils nur das, was am Modellproblem gerade benötigt wird – bewusst anders als in der mathematischen Literatur, wo die Theorie vorab aufgebaut wird. Nicht als Mangel werten und keine vorgezogenen Theorie-Bausteine vorschlagen.
