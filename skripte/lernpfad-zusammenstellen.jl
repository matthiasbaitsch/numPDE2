using Mmap
using YAML
using SHA
using ZipArchives

# -------------------------------------------------------------------------------------------------
# Building block
# -------------------------------------------------------------------------------------------------

struct BuildingBlock
	path::String
	number::Int
	name::String
	title::String
	part::String
	content::Vector{String}
	duration::Number
end

function BuildingBlock(path::String)
	bn = basename(path)
	about = YAML.load_file(joinpath(path, "about.yaml"))
	return BuildingBlock(
		path,
		parse(Int, bn[1:2]), bn[4:end],
		about["titel"], about["teil"], about["inhalt"], about["dauer"],
	)
end

# Nummer, Teil und Titel, z.B. "09-waermeleitung-instationaere-probleme"
function slug(bb::BuildingBlock)
	s = lowercase(bb.part * " " * bb.title)
	s = replace(s, "ä" => "ae", "ö" => "oe", "ü" => "ue", "ß" => "ss")
	return lpad(bb.number, 2, '0') * "-" * strip(replace(s, r"[^a-z0-9]+" => "-"), '-')
end

function make_dict(bb::BuildingBlock)
	return Dict(
		"title" => bb.title,
		"slug" => slug(bb),
	)
end


# -------------------------------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------------------------------

function substitute_text(text::String, dict::Dict)
	for (key, value) in dict
		text = replace(text, "\${$(key)}" => string(value))
	end
	return text
end

function resolve_includes(text::String, base_folder::String)
	result = IOBuffer()
	pos = 1
	for m in eachmatch(r"\{\{<\s*include\s+(.*?)\s*>\}\}", text)
		write(result, text[pos:(m.offset-1)])
		path = strip(m.captures[1])
		full_path = joinpath(base_folder, path)
		if isfile(full_path)
			write(result, read(full_path, String))
		else
			@warn "Include not found: $full_path"
			write(result, m.match)
		end
		pos = m.offset + ncodeunits(m.match)
	end
	write(result, text[pos:end])
	return String(take!(result))
end

function copy_qmd(header::String, bb::BuildingBlock, from_folder::String, to_file::String)
	text = header
	text *= "\n"
	for f ∈ filter(f -> endswith(f, ".qmd"), readdir(from_folder, join = true))
		content = read(f, String)
		content = resolve_includes(content, from_folder)
		text *= content
		text *= "\n\n"
	end
	text = substitute_text(text, make_dict(bb))
	write(to_file, text)
end

function copy_files(from_folder::String, to_folder::String, allow_duplicates::Bool = false)
	if isdir(from_folder)
		!isdir(to_folder) && mkpath(to_folder)
		for f ∈ readdir(from_folder)
			source_path = joinpath(from_folder, f)
			target_path = joinpath(to_folder, f)
			if isfile(source_path) && f != ".DS_Store"
				if !isfile(target_path)
					cp(source_path, target_path)
				else
					if allow_duplicates
						if mmap(open(source_path)) != mmap(open(target_path))
							error("Files not identical: ", source_path, " != ", target_path)
						end
					else
						error("Target file exists: ", target_path)
					end
				end
			end
		end
	end
end

function copy_images_folder(from_folder::String, to_folder::String)
	copy_files(joinpath(from_folder, "bilder"), joinpath(to_folder, "bilder"))
end

# Jedes Projekt enthält genau ein Notebook mit generischem Namen (folien.ipynb, aufgaben.ipynb),
# das hier unter dem Slug-Namen gezippt wird: x.zip enthält x.ipynb. Zip, weil GitHub Pages
# .ipynb als Text ausliefert und der Browser sie bei Links von anderen Seiten (Moodle) anzeigt
function try_zip_notebook(folder, name, zipfile)
	from_file = joinpath(folder, name)
	!isfile(from_file) && return false
	mkpath(dirname(zipfile))
	ZipWriter(zipfile) do w
		zip_newfile(w, replace(basename(zipfile), r"\.zip$" => ".ipynb"); compress = true)
		write(w, read(from_file))
	end
	return true
end

# Ordner für die Musterlösung: Nicht zu erraten, aber stabil (hängt nur vom Slug ab)
musterloesung_folder(bb::BuildingBlock) = bytes2hex(sha1("87362-" * slug(bb)))[1:8]

# Ordner rekursiv zippen, leere Ordner (im Repo mit .gitkeep) bleiben als leere Ordner erhalten
function zip_folder(folder, zipfile)
	ignore(f) = f ∈ (".DS_Store", ".gitkeep", "Manifest.toml")
	ZipWriter(zipfile) do w
		for (root, dirs, files) in walkdir(folder)
			path_in_zip = relpath(root, dirname(folder))
			files = filter(!ignore, files)
			isempty(files) && isempty(dirs) && zip_mkdir(w, path_in_zip * "/")
			for f in files
				zip_newfile(w, joinpath(path_in_zip, f); compress = true)
				write(w, read(joinpath(root, f)))
			end
		end
	end
end


# -------------------------------------------------------------------------------------------------
# Make stuff
# -------------------------------------------------------------------------------------------------

function make_slides(bb::BuildingBlock, path_input, path_output)
	notebook = slug(bb) * "-folien.zip"
	has_notebook = try_zip_notebook(
		joinpath(path_input, "projekt"), "folien.ipynb", joinpath(path_output, notebook))
	# Notebook aus projekt-fertig wird gezippt, aber nicht auf den Folien verlinkt (Link z.B. in Moodle)
	try_zip_notebook(
		joinpath(path_input, "projekt-fertig"), "folien.ipynb",
		joinpath(path_output, slug(bb) * "-folien-fertig.zip"))
	h = """
	---
	title: "$(bb.part): \${title}"
	subtitle: Numerik partieller Differentialgleichungen
	---
	"""
	if has_notebook
		h *= "\n## Material\n\n"
		h *= "[⬇ Notebook zu den Folien herunterladen]($(notebook))\n\n"
	end
	copy_qmd(h, bb, path_input, joinpath(path_output, slug(bb) * ".qmd"))
	copy_images_folder(path_input, path_output)
	# Handschriftliche Notizen, eingebunden mit #notiz (siehe lernpfad/folien/_metadata.yml)
	copy_files(joinpath(path_input, "notizen"), joinpath(path_output, "notizen"))
end

function make_assignments(bb::BuildingBlock, path_input, path_output)

	# Header for qmd file
	header = """
	---
	number-offset: $(bb.number - 1)
	format:
	  tinh-assignments-typst:
	    include-in-header:
	      text: |
	        #counter(heading).update($(bb.number - 1))
	---
	# $(bb.title) (Aufgaben)
	"""

	# Copy
	copy_qmd(header, bb, path_input, joinpath(path_output, slug(bb) * "-aufgaben.qmd"))
	copy_images_folder(path_input, path_output)

	# Notebooks, Link auf das Gerüst in den Aufgaben über ${slug}-aufgaben.zip
	try_zip_notebook(
		joinpath(path_input, "projekt"), "aufgaben.ipynb",
		joinpath(path_output, slug(bb) * "-aufgaben.zip"))
	try_zip_notebook(
		joinpath(path_input, "projekt-musterloesung"), "aufgaben.ipynb",
		joinpath(path_output, "musterloesungen", musterloesung_folder(bb), slug(bb) * "-musterloesung.zip"))
end


# -------------------------------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------------------------------

bausteine_folder = realpath(joinpath(@__DIR__, "../bausteine"))
lernpfad_folder = realpath(joinpath(@__DIR__, "../lernpfad"))

components = [
	(make_slides, "folien"),
	(make_assignments, "aufgaben"),
]

paths = readdir(bausteine_folder, join = true) |>
		filter(d -> isdir(d) && !occursin(r"\.DS_Store|00-templates", d))

# Clean
for path ∈ paths
	bb = BuildingBlock(path)
	for (_, folder) ∈ components
		output_folder = joinpath(lernpfad_folder, folder, "c")
		rm(output_folder, force = true, recursive = true)
		mkpath(output_folder)
	end
end

# Make
for path ∈ paths
	bb = BuildingBlock(path)
	for (make_function, folder) ∈ components
		path_input = joinpath(path, folder)
		if isdir(path_input)
			output_folder = joinpath(lernpfad_folder, folder, "c")
			# Literatur (_metadata.yml, .bib, .csl) nicht bei den Folien: Typst erzeugt für die (leere)
			# Literaturliste sonst eine leere Folie am Ende
			folder != "folien" && copy_files(bausteine_folder, output_folder, true)
			make_function(bb, path_input, output_folder)
		end
	end
end

# Folien, die nur zu dieser Veranstaltung gehören (Quellen liegen in lernpfad/veranstaltung/<name>)
veranstaltung_parts = ["einfuehrung", "ordner-einrichten"]
veranstaltung_folder = joinpath(lernpfad_folder, "veranstaltung")
veranstaltung_output_folder = joinpath(veranstaltung_folder, "c")
rm(veranstaltung_output_folder, force = true, recursive = true)
mkpath(veranstaltung_output_folder)
for (idx, name) ∈ enumerate(veranstaltung_parts)
	part_folder = joinpath(veranstaltung_folder, name)
	cp(joinpath(part_folder, "folien.qmd"),
		joinpath(veranstaltung_output_folder, lpad(idx, 2, '0') * "-" * name * ".qmd"))
	for sub ∈ ["bilder", "daten", "skripte"]
		from_folder = joinpath(part_folder, sub)
		isdir(from_folder) || continue
		to_folder = joinpath(veranstaltung_output_folder, sub)
		mkpath(to_folder)
		for f ∈ readdir(from_folder)
			source_path = joinpath(from_folder, f)
			if isfile(source_path) && !occursin(r"\.(afdesign|af|graffle)$|~lock~$|^\.DS_Store$", f)
				cp(source_path, joinpath(to_folder, f))
			end
		end
	end
	# Jeder Ordner zip/<name> wird als <name>.zip ausgeliefert (z.B. Ordnerstruktur für die Studierenden)
	zip_input = joinpath(part_folder, "zip")
	isdir(zip_input) || continue
	for name ∈ readdir(zip_input)
		isdir(joinpath(zip_input, name)) || continue
		zip_folder(joinpath(zip_input, name), joinpath(veranstaltung_output_folder, name * ".zip"))
	end
end
