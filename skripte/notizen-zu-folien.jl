using Poppler_jll

# Erzeugt für jeden Baustein mit Ordner folien/notizen aus den Notiz-PDFs eine Folie pro Seite:
# Bilder in folien/bilder/notizen-*.png und die Datei folien/folien.qmd (beides nicht bearbeiten).

slugify(s) = strip(replace(lowercase(s), r"[^a-z0-9]+" => "-"), '-')

function make_slides_from_notes(baustein_folder)
	notes_folder = joinpath(baustein_folder, "folien", "notizen")
	images_folder = joinpath(baustein_folder, "folien", "bilder")
	mkpath(images_folder)

	# Alte Bilder entfernen
	for f ∈ readdir(images_folder)
		startswith(f, "notizen-") && rm(joinpath(images_folder, f))
	end

	qmd = IOBuffer()
	println(qmd, "<!-- Generiert von skripte/notizen-zu-folien.jl aus folien/notizen, nicht bearbeiten -->\n")
	for pdf ∈ filter(f -> endswith(f, ".pdf"), readdir(notes_folder))
		prefix = "notizen-" * slugify(splitext(pdf)[1])
		# stderr unterdrückt: Meldungen zu fehlenden CJK-Sprachpaketen betreffen nur die unsichtbare Textebene
		cmd = `$(pdftocairo()) -png -scale-to 1800 $(joinpath(notes_folder, pdf)) $(joinpath(images_folder, prefix))`
		run(pipeline(cmd, stderr = devnull))
		pages = filter(f -> startswith(f, prefix * "-") && endswith(f, ".png"), readdir(images_folder))
		for page ∈ pages
			println(qmd, "## \n\n![](bilder/$(page)){.r-stretch}\n")
		end
	end
	write(joinpath(baustein_folder, "folien", "folien.qmd"), take!(qmd))
end

bausteine_folder = realpath(joinpath(@__DIR__, "../bausteine"))
for path ∈ readdir(bausteine_folder, join = true)
	isdir(joinpath(path, "folien", "notizen")) && make_slides_from_notes(path)
end
