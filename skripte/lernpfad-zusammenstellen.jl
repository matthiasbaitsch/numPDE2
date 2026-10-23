using Mmap
using YAML
using SHA
using ZipArchives

include("notebooks.jl")
using .Notebooks

# Published learning path, for absolute links (relative links do not work in PDF files)
const SITE_URL = "https://matthiasbaitsch.github.io/numPDE2/lernpfad"

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
	target::Union{Symbol, Nothing}    # target of the assignments notebook for the students (see notebooks.jl)
end

function BuildingBlock(path::String)
	bn = basename(path)
	about = YAML.load_file(joinpath(path, "about.yaml"))
	target = haskey(about, "target") ? Symbol(about["target"]) : nothing
	target ∈ (:scaffold, :blank, nothing) || error("Unknown target '$target' in $bn")
	return BuildingBlock(
		path,
		parse(Int, bn[1:2]), bn[4:end],
		about["titel"], about["teil"], about["inhalt"], about["dauer"], target,
	)
end

# Number, part and title, e.g. "09-waermeleitung-instationaere-probleme"
function slug(bb::BuildingBlock)
	s = lowercase(bb.part * " " * bb.title)
	s = replace(s, "ä" => "ae", "ö" => "oe", "ü" => "ue", "ß" => "ss")
	return lpad(bb.number, 2, '0') * "-" * strip(replace(s, r"[^a-z0-9]+" => "-"), '-')
end

function make_dict(bb::BuildingBlock)
	return Dict(
		"title" => bb.title,
		"slug" => slug(bb),
		# absolute URL of the assignments notebook, relative links do not work in PDF files
		"notebook" => "$SITE_URL/aufgaben/c/$(slug(bb))-aufgaben.zip",
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

# Hash in the name of the solution: not guessable, but stable (depends only on the slug)
solution_hash(bb::BuildingBlock) = bytes2hex(sha1("87362-" * slug(bb)))[1:8]

# Zip folder recursively, empty folders (with .gitkeep in the repo) are kept as empty folders
function zip_folder(folder, zipfile)
	ignore(f) = f ∈ (".DS_Store", ".gitkeep")
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


# Zip notebook from .qmd (see notebooks.jl) under the slug name: x.zip contains x.ipynb. Zip because
# GitHub Pages serves .ipynb as text and browsers display it when linked from other sites (Moodle)
function zip_notebook(source, zipfile, name = replace(basename(zipfile), r"\.zip$" => ".ipynb"); kwargs...)
	ipynb = joinpath(mktempdir(), name)
	make_notebook(source, ipynb; kwargs...)
	mkpath(dirname(zipfile))
	ZipWriter(zipfile) do w
		zip_newfile(w, name; compress = true)
		write(w, read(ipynb))
	end
	# For checking, the same target as .qmd in c/_qmd (Quarto does not render folders starting with _)
	qmd_folder = joinpath(dirname(zipfile), "_qmd")
	mkpath(qmd_folder)
	make_notebook(source, joinpath(qmd_folder, replace(name, r"\.ipynb$" => ".qmd")); kwargs...)
end


# -------------------------------------------------------------------------------------------------
# Make stuff
# -------------------------------------------------------------------------------------------------

function make_slides(bb::BuildingBlock, path_input, path_output)
	notebook = slug(bb) * "-folien.zip"
	source = joinpath(path_input, "projekt", "folien.qmd")
	has_notebook = isfile(source)
	if has_notebook
		title = "$(bb.part): $(bb.title)"
		zip_notebook(source, joinpath(path_output, notebook); title, subtitle = "Folien", target = :scaffold)
		# Finished notebook is zipped but not linked on the slides (link e.g. in Moodle)
		zip_notebook(
			source, joinpath(path_output, slug(bb) * "-folien-fertig.zip");
			title, subtitle = "Folien (fertig)", target = :solution)
	end
	h = """
	---
	title: "$(bb.part): \${title}"
	subtitle: Numerik partieller Differentialgleichungen
	---
	"""
	if has_notebook
		h *= "\n## Material\n\n"
		h *= "[⬇ Notebook zu den Folien herunterladen]($SITE_URL/folien/c/$(notebook))\n\n"
	end
	copy_qmd(h, bb, path_input, joinpath(path_output, slug(bb) * ".qmd"))
	copy_images_folder(path_input, path_output)
	# Handwritten notes, included with #notiz (see lernpfad/folien/_metadata.yml)
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
	# $(bb.part): $(bb.title) (Aufgaben)
	"""

	# Copy
	copy_qmd(header, bb, path_input, joinpath(path_output, slug(bb) * "-aufgaben.qmd"))
	copy_images_folder(path_input, path_output)

	# Notebooks, the assignments link to the scaffold via ${slug}-aufgaben.zip
	source = joinpath(path_input, "projekt", "aufgaben.qmd")
	if isfile(source)
		title = "$(bb.part): $(bb.title)"
		isnothing(bb.target) || zip_notebook(
			source, joinpath(path_output, slug(bb) * "-aufgaben.zip");
			title, subtitle = "Aufgaben", target = bb.target)
		zip_notebook(
			source, joinpath(path_output, slug(bb) * "-musterloesung-" * solution_hash(bb) * ".zip"),
			slug(bb) * "-musterloesung.ipynb";
			title, subtitle = "Musterlösung", target = :solution)
	end
end


# -------------------------------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------------------------------

blocks_folder = realpath(joinpath(@__DIR__, "../bausteine"))
learning_path_folder = realpath(joinpath(@__DIR__, "../lernpfad"))

components = [
	(make_slides, "folien"),
	(make_assignments, "aufgaben"),
]

paths = readdir(blocks_folder, join = true) |>
		filter(d -> isdir(d) && !occursin(r"\.DS_Store|00-templates", d))

# Clean
for path ∈ paths
	bb = BuildingBlock(path)
	for (_, folder) ∈ components
		output_folder = joinpath(learning_path_folder, folder, "c")
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
			output_folder = joinpath(learning_path_folder, folder, "c")
			# No bibliography (_metadata.yml, .bib, .csl) for the slides: Typst would otherwise create an
			# empty slide for the (empty) reference list at the end
			folder != "folien" && copy_files(blocks_folder, output_folder, true)
			make_function(bb, path_input, output_folder)
		end
	end
end

# Slides that belong only to this course (sources in lernpfad/veranstaltung/<name>)
course_parts = ["einfuehrung", "ordner-einrichten"]
course_folder = joinpath(learning_path_folder, "veranstaltung")
course_output_folder = joinpath(course_folder, "c")
rm(course_output_folder, force = true, recursive = true)
mkpath(course_output_folder)
for (idx, name) ∈ enumerate(course_parts)
	part_folder = joinpath(course_folder, name)
	cp(joinpath(part_folder, "folien.qmd"),
		joinpath(course_output_folder, lpad(idx, 2, '0') * "-" * name * ".qmd"))
	for sub ∈ ["bilder", "daten", "skripte"]
		from_folder = joinpath(part_folder, sub)
		isdir(from_folder) || continue
		to_folder = joinpath(course_output_folder, sub)
		mkpath(to_folder)
		for f ∈ readdir(from_folder)
			source_path = joinpath(from_folder, f)
			if isfile(source_path) && !occursin(r"\.(afdesign|af|graffle)$|~lock~$|^\.DS_Store$", f)
				cp(source_path, joinpath(to_folder, f))
			end
		end
	end
	# Each folder zip/<name> is delivered as <name>.zip (e.g. folder structure for the students)
	zip_input = joinpath(part_folder, "zip")
	isdir(zip_input) || continue
	for name ∈ readdir(zip_input)
		isdir(joinpath(zip_input, name)) || continue
		zip_folder(joinpath(zip_input, name), joinpath(course_output_folder, name * ".zip"))
	end
end
