render: render-aufgaben render-folien render-veranstaltung

prepare-render:
	cd skripte && julia -t1 --project lernpfad-zusammenstellen.jl || exit 1

render-aufgaben: prepare-render
	quarto render lernpfad/aufgaben

render-folien: prepare-render
	quarto render lernpfad/folien

render-veranstaltung: prepare-render
	quarto render lernpfad/veranstaltung

update-extension:
	quarto update matthiasbaitsch/quarto-tinh --no-prompt

# Project.toml, instantiate.jl und Workspace-Datei aus bausteine/00-templates in alle Projektordner kopieren,
# auch in die Ordnerstruktur für die Studierenden (lernpfad/veranstaltung/*/zip/*/projekt-*).
# Workspace-Name in bausteine ohne Nummer (grundlagen-musterloesung), in der Ordnerstruktur wie der Ordner.
copy-templates:
	julia skripte/copy-templates.jl

clean:
	rm -rf lernpfad/*/c
	rm -rf __output
