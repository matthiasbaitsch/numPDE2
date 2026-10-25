# Notebooks are maintained as .qmd in folien/projekt (slides) and aufgaben/projekt (assignments)
# and converted to .ipynb only when the learning path is assembled. The scaffold for the students is
# created from the same file. Blocks (text, headings or code) can be marked, similar to Quarto's
# conditional content:
#
#   no marker           in all targets
#   ::: {.solution}     only in target :solution
#   ::: {.scaffold}     only in target :scaffold
#
# A .solution block with code that is not followed by a .scaffold block becomes a code cell "# ..." in
# the scaffold. Target :blank keeps only the unmarked content.

using JSON

const TARGETS = (:solution, :scaffold, :blank)


# -------------------------------------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------------------------------------

# Part of a notebook source: unmarked text (:all) or the content of a block ::: {.solution} or ::: {.scaffold}
struct Block
    text::String
    target::Symbol    # :all, :solution or :scaffold
end

has_code(b::Block) = occursin("```{julia}", b.text)

# Adds a block for the lines unless they are empty
function push_block!(blocks::Vector{Block}, lines::Vector{String}, target::Symbol)
    text = strip(join(lines, "\n"))
    isempty(text) || push!(blocks, Block(text, target))
end

# Blocks of a notebook source (.qmd); a YAML header is skipped
function read_blocks(path::String)
    lines = readlines(path)
    if !isempty(lines) && lines[1] == "---"
        lines = lines[(findnext(==("---"), lines, 2)+1):end]
    end
    blocks = Block[]
    text = String[]
    target = :all
    for line ∈ lines
        m = match(r"^:::+\s*\{\.(solution|scaffold)\}", line)
        if !isnothing(m)
            push_block!(blocks, text, :all)
            empty!(text)
            target = Symbol(m[1])
        elseif target != :all && startswith(line, ":::")
            push_block!(blocks, text, target)
            empty!(text)
            target = :all
        else
            push!(text, line)
        end
    end
    push_block!(blocks, text, target)
    return blocks
end

# Behind each solution block with code that is not followed by a scaffold block, a scaffold block with the
# code cell "# ..."
function add_placeholders(blocks::Vector{Block})
    placeholder = Block("```{julia}\n# ...\n```", :scaffold)
    result = Block[]
    for (i, b) ∈ enumerate(blocks)
        push!(result, b)
        followed_by_scaffold = i < length(blocks) && blocks[i+1].target == :scaffold
        b.target == :solution && has_code(b) && !followed_by_scaffold && push!(result, placeholder)
    end
    return result
end

# Text of the blocks for target (unmarked blocks and blocks marked with target)
function select_blocks(blocks::Vector{Block}, target::Symbol)
    target ∈ TARGETS || error("Unknown target $target")
    return join([b.text for b ∈ blocks if b.target ∈ (:all, target)], "\n\n")
end

# Notebook from qmd with quarto convert. Quarto needs the Julia kernel in a YAML header to recognize the
# code cells and puts that header into the first cell, from where it is removed again
function write_ipynb(qmd::String, target_path::String)
    header = "---\njupyter:\n  kernelspec:\n    name: julia\n    language: julia\n    display_name: Julia\n---\n\n"
    source = tempname() * ".qmd"
    write(source, header * qmd)
    run(pipeline(`quarto convert $source --output $target_path`, stdout=devnull, stderr=devnull))
    notebook = JSON.parsefile(target_path)
    cell = notebook["cells"][1]
    lines = split(replace(join(cell["source"]), r"^---\n.*?\n---\n+"s => ""), '\n')
    cell["source"] = [lines[1:(end-1)] .* "\n"; lines[end]]
    write(target_path, JSON.json(notebook; pretty=true))
end


# -------------------------------------------------------------------------------------------------
# Notebook
# -------------------------------------------------------------------------------------------------

# Notebook source (.qmd) for target, with title and subtitle, written to target_path; format according to
# the extension of target_path (.ipynb, or .qmd for checking)
function filter_notebook(
    source_path::String, title::String, subtitle::String, target::Symbol, target_path::String
)
    blocks = add_placeholders(read_blocks(source_path))
    qmd = "# $title\n\n*$subtitle*\n\n" * select_blocks(blocks, target)

    if endswith(target_path, ".ipynb")
        write_ipynb(qmd, target_path)
    elseif endswith(target_path, ".qmd")
        write(target_path, qmd)
    else
        error("Unknown format: $target_path")
    end
end
