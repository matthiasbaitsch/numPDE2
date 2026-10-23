# Notebooks are maintained as .qmd in folien/projekt (slides) and aufgaben/projekt (assignments)
# and converted to .ipynb only when the learning path is assembled. The scaffold for the students is
# created from the same file. Blocks (text, headings or code) can be marked, similar to Quarto's
# conditional content:
#
#   no marker           in all targets
#   ::: {.solution}     only in target :solution
#   ::: {.scaffold}     only in target :scaffold
#
# Target :blank keeps only the unmarked content.

module Notebooks

using JSON

export make_notebook

# Write notebook source input (.qmd) for target (:solution, :scaffold or :blank) to output, format
# according to the extension of output (.ipynb, or .qmd for checking)
function make_notebook(input, output; title, subtitle, target)
	target ∈ (:solution, :scaffold, :blank) || error("Unknown target $target")
	qmd = "# $title\n\n*$subtitle*\n\n" * select_blocks(readlines(input), target)
	if endswith(output, ".ipynb")
		write(output, to_ipynb(qmd))
	elseif endswith(output, ".qmd")
		write(output, qmd)
	else
		error("Unknown format: $output")
	end
end

# Remove the blocks for the other target and the marker lines; a YAML header is dropped
function select_blocks(lines, target)
	if !isempty(lines) && lines[1] == "---"
		lines = lines[(findnext(==("---"), lines, 2)+1):end]
	end
	result = String[]
	flag = :none
	for line ∈ lines
		if (m = match(r"^:::+\s*\{\.(solution|scaffold)\}", line)) !== nothing
			flag = Symbol(m[1])
		elseif flag != :none && startswith(line, ":::")
			flag = :none
		elseif flag == :none || flag == target
			push!(result, line)
		end
	end
	return join(result, "\n")
end

# Code blocks ```{julia} become code cells, the text in between markdown cells
function to_ipynb(qmd)
	cells = []
	function add_cell(type, source)
		lines = split(source, '\n')
		cell = Dict(
			"cell_type" => type,
			"id" => string(length(cells) + 1),
			"metadata" => Dict(),
			"source" => isempty(source) ? String[] : [lines[1:(end-1)] .* "\n"; lines[end]],
		)
		if type == "code"
			cell["execution_count"] = nothing
			cell["outputs"] = []
		end
		push!(cells, cell)
	end

	pos = 1
	for m ∈ eachmatch(r"^```\{julia\}\n(.*?)^```$"ms, qmd)
		text = strip(qmd[pos:(m.offset-1)])
		isempty(text) || add_cell("markdown", text)
		add_cell("code", strip(m[1], '\n'))
		pos = m.offset + ncodeunits(m.match)
	end
	text = strip(qmd[pos:end])
	isempty(text) || add_cell("markdown", text)

	return JSON.json(Dict(
			"cells" => cells,
			"metadata" => Dict(
				"kernelspec" => Dict("name" => "julia", "language" => "julia", "display_name" => "Julia"),
				"language_info" => Dict("name" => "julia")),
			"nbformat" => 4, "nbformat_minor" => 5,
		); pretty = true)
end

end
