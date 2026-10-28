using SHA
using YAML
using ZipArchives

# Published learning path, for absolute links (relative links do not work in PDF files)
const SITE_URL = "https://matthiasbaitsch.github.io/numPDE2/lernpfad"

# Quarto project and its output folder (output-dir in _quarto.yml)
const PROJECT_FOLDER = realpath(joinpath(@__DIR__, ".."))
const OUTPUT_FOLDER = joinpath(PROJECT_FOLDER, "__output")

# The work is done by make_learning_path, called at the end of this file

# -------------------------------------------------------------------------------------------------
# Building block
# -------------------------------------------------------------------------------------------------

struct BuildingBlock
    folder::String
    number::Int
    title::String
    part::String
    target::Union{Symbol,Nothing}    # target of the assignments notebook for the students (tinh-target)
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

# Number, part and title, e.g. "10-waermeleitung-instationaere-probleme"
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
    BuildingBlock(d) for d = readdir(source_folder, join=true) if isfile(joinpath(d, "about.yaml"))
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
    for f = readdir(source_folder)
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
    for sub = ("bilder", "notizen")
        copy_files(joinpath(source_folder, sub), joinpath(target_folder, sub))
    end
    zips_folder = joinpath(source_folder, "zip")
    isdir(zips_folder) || return
    for name = readdir(zips_folder)
        isdir(joinpath(zips_folder, name)) && zip_folder(joinpath(zips_folder, name), joinpath(target_folder, "$name.zip"))
    end
end

# _metadata.yml next to the target folder c and the bibliography from source_folder, because c is rendered
# on its own
function copy_common_files(source_folder::String, target_folder::String)
    metadata = joinpath(dirname(target_folder), "_metadata.yml")
    isfile(metadata) && cp(metadata, joinpath(target_folder, "_metadata.yml"))
    for f = ("bibliographie.bib", "style.csl")
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

# .qmd files directly in folder
qmd_files(folder::String) = filter(f -> endswith(f, ".qmd"), readdir(folder, join=true))

# Solutions are blocks ::: {.tinh-solution} in the assignments
has_solution(folder::String) = any(f -> occursin("{.tinh-solution}", read(f, String)), qmd_files(folder))

# Header and all .qmd files directly in source_folder as one text, with placeholders replaced; warns about
# placeholders that are left (unknown or no notebook)
function assemble_qmd(header::String, bb::BuildingBlock, source_folder::String)
    text = header
    text *= "\n"
    for f = qmd_files(source_folder)
        text *= read(f, String)
        text *= "\n\n"
    end
    text = substitute_text(text, make_dict(bb))
    for m = eachmatch(r"\$\{\w+\}", text)
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

# Notebook name.ipynb from the source .qmd for target (solution, scaffold or blank) with the format tinh-notebook-ipynb
# of the extension tinh (solution and scaffold, title cell), code is not executed. The source with header is
# rendered in target_folder (in a folder starting with _ Quarto does not find the extension) and then moved to
# target_folder/_qmd for checking (Quarto does not render folders starting with _). Returns the path of the .ipynb
# in the output folder. author: [] keeps the author from _quarto.yml out of the title cell
function render_notebook(
    source::String, title::String, subtitle::String, target::Symbol, target_folder::String, name::String
)
    header = """
        ---
        title: "$title"
        subtitle: "$subtitle"
        author: []
        engine: markdown
        tinh-target: $target
        ---

        """
    qmd = joinpath(target_folder, "$name.notebook.qmd")
    write(qmd, header * read(source, String))
    run(`quarto render $qmd --to tinh-notebook-ipynb --quiet`)
    mkpath(joinpath(target_folder, "_qmd"))
    mv(qmd, joinpath(target_folder, "_qmd", "$name.qmd"))
    return joinpath(OUTPUT_FOLDER, relpath(target_folder, PROJECT_FOLDER), "$name.notebook.ipynb")
end

# Notebook as zip with the name name.ipynb, then deleted from the output folder (would be published there). Zip
# because GitHub Pages serves .ipynb as text and browsers display it when linked from other sites (Moodle)
function zip_notebook(ipynb::String, zipfile::String, name::String)
    ZipWriter(zipfile) do w
        zip_newfile(w, "$name.ipynb"; compress=true)
        write(w, read(ipynb))
    end
    rm(ipynb)
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

    # Each notebook as zip, its source for checking in c/_qmd
    function render_and_zip(subtitle, target, zipfile, name)
        ipynb = render_notebook(source, title, subtitle, target, target_folder, name)
        zip_notebook(ipynb, joinpath(target_folder, zipfile), name)
    end

    solution = "$(slug(bb))-$kind-loesung"
    render_and_zip("$subtitle (Lösung)", :solution, "$solution-$(solution_hash(bb)).zip", solution)
    isnothing(target) && return nothing
    notebook = "$(slug(bb))-$kind"
    render_and_zip(subtitle, target, "$notebook.zip", notebook)
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

    # Sheet with assignments (tinh-target blank) or with solutions (tinh-target solution, of each assignment only
    # the title), number of the sheet is the number of the building block, assignments are numbered within the sheet
    header(title, target) = """
     ---
     title: "$title"
     subtitle: "$(bb.part): $(bb.title)"
     tinh-target: $target
     tinh-solution-task: title
     ---
     """

    write(
        joinpath(target_folder, slug(bb) * "-aufgaben.qmd"),
        assemble_qmd(header("Aufgabenblatt $(bb.number)", :blank), bb, assignments_folder)
    )

    # Solution sheet (paper and pencil) if there are solutions, with the hash of the solution notebook
    if has_solution(assignments_folder)
        write(
            joinpath(target_folder, "$(slug(bb))-aufgaben-loesung-$(solution_hash(bb)).qmd"),
            assemble_qmd(header("Lösungen zu Aufgabenblatt $(bb.number)", :solution), bb, assignments_folder)
        )
    end

    copy_resources(assignments_folder, target_folder)
end


function make_slides(blocks_folder::String, target_folder::String)
    for bb = building_blocks(blocks_folder)
        slides_folder = joinpath(bb.folder, "folien")
        isdir(slides_folder) && make_slides(bb, slides_folder, target_folder)
    end
end

function make_assignments(blocks_folder::String, target_folder::String)
    for bb = building_blocks(blocks_folder)
        assignments_folder = joinpath(bb.folder, "aufgaben")
        isdir(assignments_folder) && make_assignments(bb, assignments_folder, target_folder)
    end
end

function make_course(course_folder::String, target_folder::String)
    for course_slides_folder = filter(f -> isdir(f) && f != target_folder, readdir(course_folder, join=true))
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

    for (make, source_folder, part) = components
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
