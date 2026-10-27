# Input, use functions to be able to have input on top
SOURCE_CONTENT() = [
    "bausteine/00-templates/Project.toml" => keep_name,
    "bausteine/00-templates/Manifest.toml" => keep_name,
    "bausteine/00-templates/instantiate.jl" => keep_name,
    "bausteine/00-templates/projekt.code-workspace" => workspace_name
]

TARGET_ROOTS() = ["bausteine", "lernpfad/veranstaltung"]

# Transform names
function workspace_name(path, _)
    if startswith(path, "lernpfad")
        return basename(path) * ".code-workspace"
    end
    # e.g. bausteine/01-grundlagen/aufgaben/projekt -> aufgaben-grundlagen
    m = match(r"bausteine/\d\d-([\w-]+)/(\w+)/", path)
    s = replace(basename(path), r"^projekt" => "")
    return m[2] * "-" * m[1] * s * ".code-workspace"
end

keep_name(_, source) = basename(source)

# Do the work
for bd = TARGET_ROOTS(), (path, dirs, files) = walkdir(bd)
    if endswith(path, r"projekt|projekt\-[\w-]+")
        for (source, transform) = SOURCE_CONTENT()
            target = joinpath(path, transform(path, source))
            println(target)
            cp(source, target, force=true)
        end
    end
end

# Julia environment for executed {julia} cells in the project root, found from bausteine and lernpfad/*/c
# via --project=@. (not checked in)
for f = ("Project.toml", "Manifest.toml")
    println(f)
    cp(joinpath("bausteine/00-templates", f), f, force=true)
end
