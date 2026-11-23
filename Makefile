render: render-aufgaben render-folien render-veranstaltung

prepare-render:
	cd skripte && julia -t1 --project make-learning-path.jl || exit 1

# Own project, loi-moi prepares c/ from bausteine/*/aufgaben as pre-render
render-aufgaben:
	quarto render lernpfad/aufgaben

render-folien: prepare-render
	quarto render lernpfad/folien/c

render-veranstaltung: prepare-render
	quarto render lernpfad/veranstaltung/c

# Check the published pages from the link page of loi-moi (written by render-aufgaben) and the links on them, with
# lychee (brew install lychee), also run on GitHub after deploying
check-links:
	grep -o 'https://matthiasbaitsch\.github\.io/[^"<]*\.html' lernpfad/links-site.html | sort -u \
		| xargs lychee --no-progress --max-retries 5 --retry-wait-time 10

# Check the links in the Moodle course (URL activities and texts) through the web service, only locally: token in
# ~/.config/moodle/token (not in the repo), sent by POST. jq unescapes the JSON, links to Moodle itself are skipped
MOODLE = https://moodle.hs-bochum.de/webservice/rest/server.php
MOODLE_COURSE = 11681

check-moodle-links:
	curl -s "$(MOODLE)?moodlewsrestformat=json&wsfunction=core_course_get_contents&courseid=$(MOODLE_COURSE)" \
		--data-urlencode "wstoken=$$(tr -d '[:space:]' < ~/.config/moodle/token)" \
		| jq -r '.. | strings' \
		| lychee --no-progress --exclude 'moodle\.hs-bochum\.de' -

# Update extensions tinh and loi-moi (_extensions/) and brand of Hochschule Bochum (_brand/)
update-extension:
	quarto update matthiasbaitsch/quarto-tinh --no-prompt
	quarto update matthiasbaitsch/quarto-loi-moi --no-prompt
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
