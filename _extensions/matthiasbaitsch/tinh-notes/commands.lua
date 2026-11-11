-- Klassen wie [Begriff]{.neuerbegriff} als Aufrufe der Typst-Funktionen aus tinh-notes.typ, z. B.
-- #neuerbegriff[Begriff]. Pandoc lässt die Klassen bei Typst sonst weg.
local commands = { neuerbegriff = true, eng = true, ja = true, nein = true }

function Span(el)
  for _, class in ipairs(el.classes) do
    if commands[class] then
      local result = pandoc.Inlines({ pandoc.RawInline("typst", "#" .. class .. "[") })
      result:extend(el.content)
      result:insert(pandoc.RawInline("typst", "]"))
      return result
    end
  end
end
