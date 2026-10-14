using Mmap
using YAML
using Random
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

function copy_qmd(header::String, bb::BuildingBlock, from_folder::String, to_file::String;
	transform = identity)
	text = header
	text *= "\n"
	for f ∈ filter(f -> endswith(f, ".qmd"), readdir(from_folder, join = true))
		content = read(f, String)
		content = resolve_includes(content, from_folder)
		text *= content
		text *= "\n\n"
	end
	text = substitute_text(text, make_dict(bb))
	write(to_file, transform(text))
end

function demote_headings(text::String)
	lines = String.(split(text, '\n'))
	in_code_block = false
	for (i, line) ∈ enumerate(lines)
		if startswith(lstrip(line), "```")
			in_code_block = !in_code_block
		elseif !in_code_block && occursin(r"^#{1,5}\s", line)
			lines[i] = "#" * line
		end
	end
	return join(lines, "\n")
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

function try_zip_folder(folder, folder_in_zipfile, zipfile)
	!isdir(folder) && return
	ZipWriter(zipfile) do w
		for (root, _, files) in walkdir(folder)
			for file in files
				if !occursin(r"/obj\b|/bin\b", root) && file != ".DS_Store"
					file_path = joinpath(root, file)
					zip_path = joinpath(folder_in_zipfile, relpath(file_path, folder))
					zip_newfile(w, zip_path; compress = true)
					write(w, read(file_path))
				end
			end
		end
	end
end

function try_zip_folien_projekt(folder, folder_in_zipfile, zipfile)
	!isdir(folder) && return
	allowed = r"\.(jl|ipynb|toml|qmd|code-workspace)$"
	ZipWriter(zipfile) do w
		for entry in readdir(folder)
			full = joinpath(folder, entry)
			if isfile(full) && occursin(allowed, entry)
				zip_newfile(w, joinpath(folder_in_zipfile, entry); compress = true)
				write(w, read(full))
			elseif isdir(full)
				for (root, _, files) in walkdir(full)
					# TODO: More flexible
					occursin(r"/obj\b|/bin\b", root) && continue
					in_assets = occursin(r"/Assets\b"i, root)
					for f in files
						if (occursin(allowed, f) || in_assets) && f != ".DS_Store"
							file_path = joinpath(root, f)
							zip_path = joinpath(folder_in_zipfile, entry, relpath(file_path, full))
							zip_newfile(w, zip_path; compress = true)
							write(w, read(file_path))
						end
					end
				end
			end
		end
	end
end


# -------------------------------------------------------------------------------------------------
# Make stuff
# -------------------------------------------------------------------------------------------------

function make_slides(bb::BuildingBlock, path_input, path_output)
	zipname = slug(bb) * "-folien.zip"
	zipname_done = slug(bb) * "-folien-fertig.zip"
	project_folder = joinpath(path_input, "projekt")
	project_done_folder = joinpath(path_input, "projekt-fertig")
	h = """
	---
	title: "$(bb.part): \${title}"
	---
	"""
	h *= "\n[]{.down150}\n"
	if isdir(project_folder)
		h *= "[⬇ Projekt zu den Folien herunterladen]($(zipname)){target=\"_blank\"}\n\n"
	end
	# Zip von projekt-fertig wird erzeugt, aber nicht auf den Folien verlinkt (Link z.B. in Moodle)
	# PDF erzeugt make render-slides-pdf
	h *= "[⬇ Folien als PDF]($(slug(bb)).pdf){download=\"$(slug(bb)).pdf\"}\n"
	copy_qmd(h, bb, path_input, joinpath(path_output, slug(bb) * ".qmd"))
	copy_images_folder(path_input, path_output)
	try_zip_folien_projekt(
		project_folder,
		slug(bb) * "-folien",
		joinpath(path_output, zipname),
	)
	try_zip_folien_projekt(
		project_done_folder,
		slug(bb) * "-folien-fertig",
		joinpath(path_output, zipname_done),
	)
end

function make_book_chapter(bb::BuildingBlock, path_input, path_output)
	h = """
	---
	title: "\${title}"
	---
	"""
	copy_qmd(h, bb, path_input, joinpath(path_output, slug(bb) * ".qmd"), transform = demote_headings)
	copy_images_folder(path_input, path_output)
end

# chapters: Paare (Teil, Datei), Kapitel mit gleichem Teil folgen aufeinander
function make_book_config(path_output, chapters::Vector{Tuple{String, String}})
	write(joinpath(path_output, "index.qmd"), "Unterlagen zur Vorlesung Numerik partieller Differentialgleichungen.\n")
	chapter_lines = ""
	for part ∈ unique(first.(chapters))
		chapter_lines *= "    - part: \"$(part)\"\n      chapters:\n"
		for (p, file) ∈ chapters
			p == part && (chapter_lines *= "        - $(file)\n")
		end
	end
	write(joinpath(path_output, "_quarto.yml"), """
	lang: de

	project:
	  type: book
	  output-dir: ../../__output/lernpfad/folien-alle

	book:
	  title: Numerik partieller Differentialgleichungen
	  subtitle: Master Bau- und Umweltingenieurwesen
	  author: Matthias Baitsch
	  date: today
	  chapters:
	    - index.qmd
	$(chapter_lines)

	number-sections: false

	format:
	  html:
	    theme: cosmo
	""")
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

	# Zip project folder
	try_zip_folder(
		joinpath(path_input, "projekt"),
		slug(bb),
		joinpath(path_output, slug(bb) * ".zip"),
	)
	try_zip_folder(
		joinpath(path_input, "projekt-musterloesung"),
		slug(bb) * "-musterloesung",
		joinpath(path_output, slug(bb) * "-musterloesung-$(join(rand('a':'z', 5))).zip"),
	)
end


# -------------------------------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------------------------------

Random.seed!(87362)
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
			copy_files(bausteine_folder, output_folder, true)
			make_function(bb, path_input, output_folder)
		end
	end
end

# Book with all slides
book_folder = joinpath(lernpfad_folder, "folien-alle")
book_output_folder = joinpath(book_folder, "c")
rm(book_output_folder, force = true, recursive = true)
mkpath(book_output_folder)
chapters = Tuple{String, String}[]
for path ∈ paths
	bb = BuildingBlock(path)
	path_input = joinpath(path, "folien")
	if isdir(path_input)
		copy_files(bausteine_folder, book_output_folder, true)
		make_book_chapter(bb, path_input, book_output_folder)
		push!(chapters, (bb.part, "c/" * slug(bb) * ".qmd"))
	end
end
make_book_config(book_folder, chapters)

# Folien, die nur zu dieser Veranstaltung gehören (Quellen liegen in lernpfad/veranstaltung/<name>)
veranstaltung_parts = ["einfuehrung"]
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
end
