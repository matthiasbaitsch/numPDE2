# Setup for executed {julia} cells in assignments and slides, loaded in the first cell with
# include(joinpath(dirname(Base.active_project()), "_setup.jl"))
import QuartoNotebookWorker
using CairoMakie
using MMJMesh.Plots
using MMJMesh.Mathematics

# Output format of the document being rendered
is_typst() = QuartoNotebookWorker.notebook_options()["format"]["pandoc"]["to"] == "typst"

# Typst places the SVG at its natural size, which is too large on the page
set_theme!(theme_minimal())
CairoMakie.activate!(type = "svg", pt_per_unit = is_typst() ? 0.5 : 0.75)
