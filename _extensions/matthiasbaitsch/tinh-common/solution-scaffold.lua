-- Lösung und Gerüst aus einer Quelle, gesteuert über die Variable tinh-target:
--
--                        ohne tinh-target   solution       scaffold   blank
--   ohne Markierung      ja                 ja             ja         ja
--   ::: {.tinh-solution} ja, markiert       ja, markiert*  nein       nein
--   ::: {.tinh-scaffold} ja, markiert       nein           ja         nein
--   ::: {.tinh-work}     ja                 nein           nein       nein
--
-- * im ipynb nicht markiert, das ganze Notebook ist die Lösung.
--
-- .tinh-work ist für die Arbeitsfassung, z.B. Code, der Pakete und Daten lädt, damit sich Lösungen testen lassen.
-- Code darin läuft aber auch bei gesetztem tinh-target (vor dem Filter), soll er das nicht, muss die Zelle vorher
-- deaktiviert werden.
--
-- Bei scaffold steht nach einem .tinh-solution-Block mit Code ohne folgenden .tinh-scaffold-Block eine Code-Zelle
-- "# ...". Markiert heißt: in HTML und Typst ein Block mit farbigem Rand und Beschriftung, sonst (z.B. ipynb) eine
-- fette Beschriftung davor. Aufeinanderfolgende markierte Blöcke derselben Art werden zu einem zusammengefasst.
--
-- Mit tinh-target: solution und tinh-solution-task: title bleibt von jeder Aufgabe (::: {#exr-…}) nur der Titel und
-- die Lösung, Aufgaben ohne Lösung bekommen eine Lösung "Keine Lösung." (Voreinstellung full: ganze Aufgabe).
-- Läuft vor Quartos Filtern (pre-ast).
local TARGETS = { solution = true, scaffold = true, blank = true }
local TASKS = { full = true, title = true }
local KINDS = { ["tinh-solution"] = "solution", ["tinh-scaffold"] = "scaffold", ["tinh-work"] = "work" }
local LABELS = {
  de = { solution = "Lösung", scaffold = "Gerüst", none = "Keine Lösung." },
  en = { solution = "Solution", scaffold = "Scaffold", none = "No solution." },
}
local COLORS = { solution = "#4a8c4a", scaffold = "#107895" }

local function kind_of(block)
  if block.t == "Div" then
    for class, kind in pairs(KINDS) do
      if block.classes:includes(class) then
        return kind
      end
    end
  end
end

local function has_solution(block)
  if kind_of(block) == "solution" then
    return true
  end
  local found = false
  if block.t == "Div" then
    block:walk({
      Div = function(el)
        found = found or kind_of(el) == "solution"
      end,
    })
  end
  return found
end

-- Aufgabe auf Titel und Lösung kürzen
local function title_only(exercise, none)
  local content = pandoc.Blocks({})
  for _, block in ipairs(exercise.content) do
    if block.t == "Header" or has_solution(block) then
      content:insert(block)
    end
  end
  if not exercise.content:find_if(has_solution) then
    content:insert(pandoc.Div(pandoc.Para(pandoc.Emph(none)), { class = "tinh-solution" }))
  end
  exercise.content = content
  return exercise
end

local function has_code(block)
  local found = false
  block:walk({
    CodeBlock = function()
      found = true
    end,
  })
  return found
end

-- Sprache der ersten Code-Zelle (```{julia} wird bei engine: markdown zur Klasse "{julia}")
local function language(blocks)
  local lang
  blocks:walk({
    CodeBlock = function(el)
      local class = el.classes[1]
      lang = lang or (class and (class:match("^{(%w+)") or class))
    end,
  })
  return lang or "julia"
end

local function marked(content, kind, label)
  if quarto.doc.is_format("html") then
    quarto.doc.add_html_dependency({
      name = "tinh-solution-scaffold",
      version = "0.1.0",
      stylesheets = { quarto.utils.resolve_path("solution-scaffold.css") },
    })
    return { pandoc.Div(content, { class = "tinh-" .. kind, ["data-label"] = label }) }
  elseif quarto.doc.is_format("typst") then
    local color = 'rgb("' .. COLORS[kind] .. '")'
    local open = "#block(width: 100%, stroke: (left: 1.5pt + " .. color .. "), inset: (left: 0.8em, y: 0.3em))["
      .. "#block(below: 0.6em, text(size: 0.85em, weight: \"bold\", fill: " .. color .. ")[" .. label .. "])"
    return pandoc.Blocks({ pandoc.RawBlock("typst", open) }) .. content .. { pandoc.RawBlock("typst", "]") }
  end
  return pandoc.Blocks({ pandoc.Para(pandoc.Strong(label)) }) .. content
end

function Pandoc(doc)
  local target = doc.meta["tinh-target"] and pandoc.utils.stringify(doc.meta["tinh-target"])
  if target and not TARGETS[target] then
    error("tinh-target muss solution, scaffold oder blank sein, nicht " .. target)
  end
  local task = doc.meta["tinh-solution-task"] and pandoc.utils.stringify(doc.meta["tinh-solution-task"]) or "full"
  if not TASKS[task] then
    error("tinh-solution-task muss full oder title sein, nicht " .. task)
  end
  local lang = doc.meta.lang and pandoc.utils.stringify(doc.meta.lang):match("^en") and "en" or "de"
  if target == "solution" and task == "title" then
    doc = doc:walk({
      Div = function(el)
        if el.identifier:match("^exr%-") then
          return title_only(el, LABELS[lang].none)
        end
      end,
    })
  end
  local placeholder = pandoc.CodeBlock("# ...", { class = "{" .. language(doc.blocks) .. "}" })

  local mark_solution = target == nil or (target == "solution" and not quarto.doc.is_format("ipynb"))

  local function select(blocks)
    local result = pandoc.Blocks({})
    -- offene Gruppe markierter Blöcke derselben Art, wird erst beim nächsten anderen Block ausgegeben
    local group_kind, group = nil, pandoc.Blocks({})
    local function flush()
      if group_kind then
        result:extend(marked(group, group_kind, LABELS[lang][group_kind]))
        group_kind, group = nil, pandoc.Blocks({})
      end
    end

    for i, block in ipairs(blocks) do
      local kind = kind_of(block)
      if kind == "work" then
        if target == nil then
          flush()
          result:extend(block.content)
        end
      elseif kind == nil then
        flush()
        result:insert(block)
      elseif target == nil or (kind == "solution" and mark_solution) then
        if kind ~= group_kind then
          flush()
          group_kind = kind
        end
        group:extend(block.content)
      else
        if kind == target then
          flush()
          result:extend(block.content)
        end
        local next_kind = blocks[i + 1] and kind_of(blocks[i + 1])
        if target == "scaffold" and kind == "solution" and next_kind ~= "scaffold" and has_code(block) then
          result:insert(placeholder)
        end
      end
    end
    flush()
    return result
  end

  return doc:walk({ Blocks = select })
end
