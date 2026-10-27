-- Notebook aus einer .qmd (Lösung und Gerüst wählt solution-scaffold.lua aus tinh-common, das vorher läuft).
--
-- Mit engine: markdown (nichts wird ausgeführt) bleiben Zellen wie ```{julia} einfache Codeblöcke mit der Klasse
-- "{julia}". Sie werden zu Codeblöcken der Sprache, bei ipynb zu Code-Zellen; die Sprache der ersten Zelle
-- bestimmt den Kernel. Bei ipynb stehen Titel und Untertitel in der ersten Zelle.

-- Sprache eines Codeblocks aus einer nicht ausgeführten Zelle (Klasse "{julia}"), sonst nil
local function cell_language(el)
  return el.classes[1] and el.classes[1]:match("^{(%w+)")
end

local function code_cells(blocks)
  return blocks:walk({
    CodeBlock = function(el)
      local lang = cell_language(el)
      if lang == nil then
        return nil
      end
      local code = pandoc.CodeBlock(el.text, { class = lang })
      if FORMAT == "ipynb" then
        return pandoc.Div(code, { class = "cell code" })
      end
      return code
    end,
  })
end

local function language(blocks)
  local lang
  blocks:walk({
    CodeBlock = function(el)
      lang = lang or cell_language(el) or el.classes[1]
    end,
  })
  return lang or "julia"
end

function Pandoc(doc)
  local lang = language(doc.blocks)
  doc.blocks = code_cells(doc.blocks)

  if FORMAT == "ipynb" then
    -- Titel und Untertitel als erste Zelle (pandoc setzt den Untertitel nicht kursiv)
    local head = pandoc.Blocks({})
    if doc.meta.title then
      head:insert(pandoc.Header(1, doc.meta.title))
    end
    if doc.meta.subtitle then
      head:insert(pandoc.Para(pandoc.Emph(doc.meta.subtitle)))
    end
    doc.blocks = head .. doc.blocks
    doc.meta.title = nil
    doc.meta.subtitle = nil
    doc.meta.jupyter = doc.meta.jupyter or {
      kernelspec = { name = lang, language = lang, display_name = lang:gsub("^%l", string.upper) },
    }
  end
  return doc
end
