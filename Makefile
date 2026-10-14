PDF_JOBS ?= 4
DECKTAPE_ARGS ?=

prepare-render:
	cd skripte && julia -t1 --project lernpfad-zusammenstellen.jl || exit 1

render-assignments: prepare-render
	quarto render lernpfad/aufgaben -t tinh-notes-html

render-slides: prepare-render
	quarto render lernpfad/folien -t tinh-slides-revealjs

render-slides-veranstaltung: prepare-render
	quarto render lernpfad/veranstaltung/c -t tinh-slides-revealjs

render-slides-all: prepare-render
	quarto render lernpfad/folien-alle -t html

render-slides-pdf:
	find __output/lernpfad/folien/c __output/lernpfad/veranstaltung/c -maxdepth 1 -name '*.html' -print0 | \
		xargs -0 -P $(PDF_JOBS) -I {} sh -c 'decktape reveal $(DECKTAPE_ARGS) -s 1050x700 -p 200 "$$1" "$${1%.html}.pdf"' _ {}

render: render-assignments render-slides render-slides-veranstaltung render-slides-all

publish: render render-slides-pdf

update-extension:
	quarto update matthiasbaitsch/quarto-tinh --no-prompt

clean:
	rm -rf lernpfad/*/c
	rm -rf __output
