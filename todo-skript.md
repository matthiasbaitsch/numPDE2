# TODO: `skripte/make-learning-path.jl` vereinfachen

Ungenutzt:

- [ ]  `resolve_includes`: keine Quelle verwendet `{{< include >}}`.
- [ ]  `copy_files` mit `allow_duplicates` und `mmap` (und damit das Paket `Mmap`): war nur für das mehrfache Kopieren
  von `bausteine/` nach `aufgaben/c` da.
- [ ]  Felder `name`, `content` und `duration` in `BuildingBlock` werden gelesen, aber nirgends verwendet.
- [ ]  `${title}` wird nur im Kopf benutzt, den das Skript selbst erzeugt (`title: "$(bb.part): \${title}"`).

Umständlich:

- [ ]  Clean: die `c`-Ordner werden in einer Schleife über alle Bausteine gelöscht (derselbe Ordner neunmal).
- [ ]  Drei verschiedene Arten, Ordner zu kopieren: `copy_files`, `copy_images_folder` und eine eigene Schleife mit
  Filter (Affinity, Graffle, Lock-Dateien) bei der Veranstaltung.
- [ ]  Metadaten und Literatur werden am Schluss separat nach `c` kopiert, gehören aber zum Anlegen der `c`-Ordner.
- [ ]  Die Folien zur Veranstaltung sind ein eigener Code-Weg im Hauptteil statt einer Funktion wie `make_slides`
  und `make_assignments`.
- [ ]  `components` mit Paaren aus Funktion und Ordnername, nur um zwei Funktionen aufzurufen.
- [ ]  `zip_notebook` schreibt das Notebook erst in einen temporären Ordner und liest es zum Zippen wieder ein; die
  `.qmd` zum Prüfen entsteht in derselben Funktion als Nebenwirkung.
- [ ]  Zwei Arten von Platzhaltern: `${slug}`, `${notebook}` in den Quellen (`make_dict`, `substitute_text`) und
  `$(…)`-Interpolation in den Köpfen, die das Skript erzeugt.
