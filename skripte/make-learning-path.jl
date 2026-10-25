using SHA
using YAML
using ZipArchives

include("filter-notebook.jl")

# Published learning path, for absolute links (relative links do not work in PDF files)
const SITE_URL = "https://matthiasbaitsch.github.io/numPDE2/lernpfad"

# The work is done by make_learning_path, called at the end of this file

# -------------------------------------------------------------------------------------------------
# Building block
# -------------------------------------------------------------------------------------------------

struct BuildingBlock
    folder::String
    number::Int
    title::String
    part::String
    target::Union{Symbol,Nothing}    # target of the assignments notebook for the students (see filter-notebook.jl)
end

function BuildingBlock(folder::String)
    bn = basename(folder)
    about = YAML.load_file(joinpath(folder, "about.yaml"))
    target = haskey(about, "target") ? Symbol(about["target"]) : nothing
    target ∈ (:scaffold, :blank, nothing) || error("Unknown target '$target' in $bn")
    return BuildingBlock(
        folder,
        parse(Int, bn[1:2]), about["titel"], about["teil"], target,
    )
end

# Number, part and title, e.g. "09-waermeleitung-instationaere-probleme"
function slug(bb::BuildingBlock)
    s = lowercase(bb.part * " " * bb.title)
    s = replace(s, "ä" => "ae", "ö" => "oe", "ü" => "ue", "ß" => "ss")
    return lpad(bb.number, 2, '0') * "-" * strip(replace(s, r"[^a-z0-9]+" => "-"), '-')
end

# Placeholders ${slug} and, if there is an assignments notebook for the students, ${notebook} in the sources
function make_dict(bb::BuildingBlock)
    dict = Dict("slug" => slug(bb))
    isnothing(bb.target) || (dict["notebook"] = "$SITE_URL/aufgaben/c/$(slug(bb))-aufgaben.zip")
    return dict
end

# Hash in the name of the solutions: not guessable, but stable (depends only on the slug)
solution_hash(bb::BuildingBlock) = bytes2hex(sha1("87362-" * slug(bb)))[1:8]

# All folders with about.yaml in source_folder
building_blocks(source_folder::String) = [
    BuildingBlock(d) for d ∈ readdir(source_folder, join=true) if isfile(joinpath(d, "about.yaml"))
]


# -------------------------------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------------------------------

# Source files of drawing programs (Affinity, OmniGraffle), lock files and .DS_Store
is_auxiliary(f::String) = occursin(r"\.(afdesign|af|graffle)$|~lock~$|^\.DS_Store$", f)

# Files (not folders) from source_folder, except auxiliary files; existing target files are an error
function copy_files(source_folder::String, target_folder::String)
    isdir(source_folder) || return
    mkpath(target_folder)
    for f ∈ readdir(source_folder)
        source_path = joinpath(source_folder, f)
        target_path = joinpath(target_folder, f)
        if isfile(source_path) && !is_auxiliary(f)
            isfile(target_path) && error("Target file exists: ", target_path)
            cp(source_path, target_path)
        end
    end
end

# Images (bilder/) and handwritten notes (notizen/) of a source folder; each folder zip/<name> as <name>.zip
function copy_resources(source_folder::String, target_folder::String)
    for sub ∈ ("bilder", "notizen")
        copy_files(joinpath(source_folder, sub), joinpath(target_folder, sub))
    end
    zips_folder = joinpath(source_folder, "zip")
    isdir(zips_folder) || return
    for name ∈ readdir(zips_folder)
        isdir(joinpath(zips_folder, name)) && zip_folder(joinpath(zips_folder, name), joinpath(target_folder, "$name.zip"))
    end
end

# _metadata.yml next to the target folder c and the bibliography from source_folder, because c is rendered
# on its own
function copy_common_files(source_folder::String, target_folder::String)
    metadata = joinpath(dirname(target_folder), "_metadata.yml")
    isfile(metadata) && cp(metadata, joinpath(target_folder, "_metadata.yml"))
    for f ∈ ("bibliographie.bib", "style.csl")
        cp(joinpath(source_folder, f), joinpath(target_folder, f))
    end
end

# Replace the placeholders ${key} in text
function substitute_text(text::String, dict::Dict)
    for (key, value) in dict
        text = replace(text, "\${$(key)}" => string(value))
    end
    return text
end

is_solution(f::String) = endswith(f, ".sol.qmd")

# Only the title of an assignment: opening line of the div ::: {#exr-…} and heading, so the number stays the same
function assignment_title(text::String)
    lines = split(text, '\n')
    return join([first(filter(l -> startswith(l, ":::"), lines)), first(filter(l -> startswith(l, "## "), lines)), ":::"], "\n")
end

# Header and all .qmd files directly in source_folder (except solutions x.sol.qmd) as one text, with placeholders
# replaced; with_solution: instead of each assignment its title followed by the solution x.sol.qmd (each paper
# assignment has one) or a note on the solution notebook; warns about placeholders that are left (unknown or no
# notebook)
function assemble_qmd(header::String, bb::BuildingBlock, source_folder::String; with_solution::Bool=false)
    text = header
    text *= "\n"
    for f ∈ filter(f -> endswith(f, ".qmd") && !is_solution(f), readdir(source_folder, join=true))
        if with_solution
            solution = replace(f, r"\.qmd$" => ".sol.qmd")
            text *= assignment_title(read(f, String)) * "\n\n"
            text *= isfile(solution) ? read(solution, String) : "Lösung im Lösungs-Notebook\n"
        else
            text *= read(f, String)
        end
        text *= "\n\n"
    end
    text = substitute_text(text, make_dict(bb))
    for m ∈ eachmatch(r"\$\{\w+\}", text)
        @warn "Placeholder $(m.match) not replaced in $source_folder"
    end
    return text
end

# Zip folder recursively, empty folders (with .gitkeep in the repo) are kept
function zip_folder(source_folder::String, zipfile::String)
    ignore(f) = f ∈ (".DS_Store", ".gitkeep")
    ZipWriter(zipfile) do w
        for (root, dirs, files) in walkdir(source_folder)
            path_in_zip = relpath(root, dirname(source_folder))
            files = filter(!ignore, files)
            isempty(files) && isempty(dirs) && zip_mkdir(w, path_in_zip * "/")
            for f in files
                zip_newfile(w, joinpath(path_in_zip, f); compress=true)
                write(w, read(joinpath(root, f)))
            end
        end
    end
end

# Notebook from .qmd (see filter-notebook.jl) as zip. Zip because GitHub Pages serves .ipynb as text and browsers
# display it when linked from other sites (Moodle)
function zip_notebook(
    source::String, title::String, subtitle::String, target::Symbol, zipfile::String,
    name::String=replace(basename(zipfile), r"\.zip$" => ".ipynb")
)
    ipynb = joinpath(mktempdir(), name)
    filter_notebook(source, title, subtitle, target, ipynb)
    mkpath(dirname(zipfile))
    ZipWriter(zipfile) do w
        zip_newfile(w, name; compress=true)
        write(w, read(ipynb))
    end
end

# Notebooks from projekt/notebook.qmd: always the solution, for the students if target is set (returns the
# name of their zip file, otherwise nothing)
function zip_project_notebooks(
    bb::BuildingBlock, source_folder::String, target_folder::String, kind::String, target::Union{Symbol,Nothing}
)
    source = joinpath(source_folder, "projekt", "notebook.qmd")
    isfile(source) || return nothing
    title = "$(bb.part): $(bb.title)"
    subtitle = titlecase(kind)

    # Each notebook as zip and, for checking, as .qmd in c/_qmd (Quarto does not render folders starting with _)
    function zip_with_check(subtitle, target, zipfile, name)
        zip_notebook(source, title, subtitle, target, joinpath(target_folder, zipfile), name)
        mkpath(joinpath(target_folder, "_qmd"))
        filter_notebook(source, title, subtitle, target, joinpath(target_folder, "_qmd", replace(name, r"\.ipynb$" => ".qmd")))
    end

    solution = "$(slug(bb))-$kind-loesung"
    zip_with_check("$subtitle (Lösung)", :solution, "$solution-$(solution_hash(bb)).zip", "$solution.ipynb")
    isnothing(target) && return nothing
    notebook = "$(slug(bb))-$kind"
    zip_with_check(subtitle, target, "$notebook.zip", "$notebook.ipynb")
    return "$notebook.zip"
end


# -------------------------------------------------------------------------------------------------
# Make things
# -------------------------------------------------------------------------------------------------

function make_slides(bb::BuildingBlock, slides_folder::String, target_folder::String)

    notebook = zip_project_notebooks(bb, slides_folder, target_folder, "folien", :scaffold)

    header = """
     ---
     title: "$(bb.part): $(bb.title)"
     subtitle: Numerik partieller Differentialgleichungen
     ---
     """

    if !isnothing(notebook)
        header *= "\n## Material\n\n"
        header *= "[⬇ Notebook zu den Folien]($SITE_URL/folien/c/$(notebook))\n\n"
    end

    write(joinpath(target_folder, slug(bb) * ".qmd"), assemble_qmd(header, bb, slides_folder))
    copy_resources(slides_folder, target_folder)
end

function make_assignments(bb::BuildingBlock, assignments_folder::String, target_folder::String)

    zip_project_notebooks(bb, assignments_folder, target_folder, "aufgaben", bb.target)

    header(kind) = """
     ---
     number-offset: $(bb.number - 1)
     format:
       tinh-assignments-typst:
         include-in-header:
           text: |
             #counter(heading).update($(bb.number - 1))
     ---
     # $(bb.part): $(bb.title) ($kind)
     """

    write(joinpath(target_folder, slug(bb) * "-aufgaben.qmd"), assemble_qmd(header("Aufgaben"), bb, assignments_folder))

    # Solution sheet (paper and pencil) if there are solutions, with the hash of the solution notebook
    if any(is_solution, readdir(assignments_folder))
        write(
            joinpath(target_folder, "$(slug(bb))-aufgaben-loesung-$(solution_hash(bb)).qmd"),
            assemble_qmd(header("Lösungen"), bb, assignments_folder; with_solution=true)
        )
    end

    copy_resources(assignments_folder, target_folder)
end


function make_slides(blocks_folder::String, target_folder::String)
    for bb ∈ building_blocks(blocks_folder)
        slides_folder = joinpath(bb.folder, "folien")
        isdir(slides_folder) && make_slides(bb, slides_folder, target_folder)
    end
end

function make_assignments(blocks_folder::String, target_folder::String)
    for bb ∈ building_blocks(blocks_folder)
        assignments_folder = joinpath(bb.folder, "aufgaben")
        isdir(assignments_folder) && make_assignments(bb, assignments_folder, target_folder)
    end
end

function make_course(course_folder::String, target_folder::String)
    for course_slides_folder ∈ filter(f -> isdir(f) && f != target_folder, readdir(course_folder, join=true))
        name = basename(course_slides_folder)
        cp(joinpath(course_slides_folder, "folien.qmd"), joinpath(target_folder, "$name.qmd"))
        copy_resources(course_slides_folder, target_folder)
    end
end

function make_learning_path(source::String, target::String)
    building_blocks_folder = realpath(joinpath(@__DIR__, "..", source))
    learning_path_folder = realpath(joinpath(@__DIR__, "..", target))

    components = [
        (make_slides, building_blocks_folder, "folien"),
        (make_assignments, building_blocks_folder, "aufgaben"),
        (make_course, joinpath(learning_path_folder, "veranstaltung"), "veranstaltung"),
    ]

    for (make, source_folder, part) ∈ components
        target_folder = joinpath(learning_path_folder, part, "c")
        rm(target_folder, force=true, recursive=true)
        mkpath(target_folder)
        copy_common_files(building_blocks_folder, target_folder)
        make(source_folder, target_folder)
    end
end

# -------------------------------------------------------------------------------------------------
# Do the work
# -------------------------------------------------------------------------------------------------
make_learning_path("bausteine", "lernpfad")
