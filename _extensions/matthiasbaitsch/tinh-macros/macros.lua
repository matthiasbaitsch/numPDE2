-- Setzt die Makros aus math.tex und units.tex in Formeln ein, damit sie in allen Formaten ankommen (HTML, Typst).
-- Formeln mit einem der Makros liest pandoc zusammen mit den Definitionen neu ein und ersetzt dabei die Makros
-- (latex_macros). Makros im Fließtext (RawInline/RawBlock, z.B. \SI{20}{\metre}) werden zu Inline-Formeln.
-- Bei LaTeX nur math.tex, die Einheiten setzt dort siunitx.
local function read_macros(name)
  local file = io.open(pandoc.path.join({ pandoc.path.directory(PANDOC_SCRIPT_FILE), name }))
  local text = file:read("a")
  file:close()
  return text
end

local macros = read_macros("math.tex")
if not FORMAT:match("latex") then
  macros = macros .. read_macros("units.tex")
end

local names = {}
for name in macros:gmatch("\\newcommand{\\(%a+)}") do
  table.insert(names, name)
end

local function uses_macro(text)
  for _, name in ipairs(names) do
    if text:find("\\" .. name .. "%f[%A]") then
      return true
    end
  end
  return false
end

local function expand(text)
  local doc = pandoc.read(macros .. "\n\n$$" .. text .. "$$", "markdown")
  local result
  doc:walk({
    Math = function(el)
      result = result or el.text
    end,
  })
  return result
end

local function is_tex(format)
  return format == "tex" or format == "latex"
end

function Math(el)
  if uses_macro(el.text) then
    local text = expand(el.text)
    if text then
      return pandoc.Math(el.mathtype, text)
    end
  end
end

function RawInline(el)
  if is_tex(el.format) and uses_macro(el.text) then
    local text = expand(el.text)
    if text then
      return pandoc.Math("InlineMath", text)
    end
  end
end

function RawBlock(el)
  if is_tex(el.format) and uses_macro(el.text) then
    local text = expand(el.text)
    if text then
      return pandoc.Para({ pandoc.Math("InlineMath", text) })
    end
  end
end
