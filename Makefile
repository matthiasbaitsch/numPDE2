render: render-aufgaben render-folien render-veranstaltung

prepare-render:
	cd skripte && julia -t1 --project make-learning-path.jl || exit 1

render-aufgaben: prepare-render
	quarto render lernpfad/aufgaben/c

render-folien: prepare-render
	quarto render lernpfad/folien/c

render-veranstaltung: prepare-render
	quarto render lernpfad/veranstaltung/c

# Update extension tinh (_extensions/) and brand of Hochschule Bochum (_brand/)
update-extension:
	quarto update matthiasbaitsch/quarto-tinh --no-prompt
	quarto use brand matthiasbaitsch/hsbo-brand --force

# Copy Project.toml, Manifest.toml, instantiate.jl and workspace file from bausteine/00-templates to all
# project folders, including the folder structure for the students (lernpfad/veranstaltung/*/zip/*/projekt-*).
# Workspace name in bausteine from folder and block without number (aufgaben-grundlagen), in the folder structure like the folder.
copy-templates:
	julia skripte/copy-templates.jl

# At the start of the semester: update package versions (also MMJMesh main) in the template manifest and distribute
update-packages:
	julia --project=bausteine/00-templates -e 'using Pkg; Pkg.update()'
	julia skripte/copy-templates.jl

clean:
	rm -rf lernpfad/*/c
	rm -rf __output
	rm -rf _freeze
