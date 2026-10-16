PDF_JOBS ?= 4
DECKTAPE_ARGS ?=

prepare-render:
	cd skripte && julia -t1 --project lernpfad-zusammenstellen.jl || exit 1

render-assignments: prepare-render
	quarto render lernpfad/aufgaben -t tinh-notes-html

render-slides: prepare-render
	quarto render lernpfad/folien -t tinh-slides-typst

render-slides-veranstaltung: prepare-render
	quarto render lernpfad/veranstaltung/c -t tinh-slides-revealjs

render-slides-pdf:
	find __output/lernpfad/veranstaltung/c -maxdepth 1 -name '*.html' -print0 | \
		xargs -0 -P $(PDF_JOBS) -I {} sh -c 'decktape reveal $(DECKTAPE_ARGS) -s 1050x700 -p 200 "$$1" "$${1%.html}.pdf"' _ {}

render: render-assignments render-slides render-slides-veranstaltung

publish: render render-slides-pdf

update-extension:
	quarto update matthiasbaitsch/quarto-tinh --no-prompt

# Project.toml, instantiate.jl und Workspace-Datei aus bausteine/00-templates in alle Projektordner kopieren,
# auch in die Ordnerstruktur für die Studierenden (lernpfad/veranstaltung/*/zip/*/projekt-*).
# Workspace-Name in bausteine mit Nummer, weil Bausteintitel sich wiederholen (01-grundlagen, 06-grundlagen),
# in der Ordnerstruktur wie der Ordner. Vorhandene Workspace-Dateien werden ersetzt.
TEMPLATES = bausteine/00-templates
copy-templates:
	for f in bausteine/*/*/projekt* lernpfad/veranstaltung/*/zip/*/projekt-*; do \
		case "$$f" in \
			lernpfad/*) package=`basename $$f` ;; \
			*) package=`echo $$f | cut -d'/' -f2` ;; \
		esac; \
		case "$$f" in \
			lernpfad/*) ;; \
			*-musterloesung) package=$$package-musterloesung ;; \
			*-playground) package=$$package-playground ;; \
			*-fertig) package=$$package-fertig ;; \
		esac; \
		cp $(TEMPLATES)/Project.toml $(TEMPLATES)/instantiate.jl $$f; \
		rm -f $$f/*.code-workspace; \
		cp $(TEMPLATES)/projekt.code-workspace $$f/$$package.code-workspace; \
	done

clean:
	rm -rf lernpfad/*/c
	rm -rf __output
