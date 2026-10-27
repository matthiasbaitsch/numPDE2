-- Zentriert Absätze, die nur aus Bildern bestehen (Bilder ohne Bildunterschrift). Bilder mit Bildunterschrift sind
-- Abbildungen und werden über fig-align zentriert. Bilder mit eigenem fig-align oder den revealjs-Klassen absolute
-- und r-stretch bleiben unverändert.
local function only_images(content)
  local found = false
  for _, el in ipairs(content) do
    if el.t == "Image" then
      if el.attributes["fig-align"] or el.classes:includes("absolute") or el.classes:includes("r-stretch") then
        return false
      end
      found = true
    elseif el.t ~= "Space" and el.t ~= "SoftBreak" then
      return false
    end
  end
  return found
end

function Para(el)
  if not only_images(el.content) then
    return nil
  end
  if quarto.doc.is_format("latex") then
    return { pandoc.RawBlock("latex", "\\begin{center}"), el, pandoc.RawBlock("latex", "\\end{center}") }
  elseif quarto.doc.is_format("typst") then
    return { pandoc.RawBlock("typst", "#align(center)["), el, pandoc.RawBlock("typst", "]") }
  elseif quarto.doc.is_format("html") then
    return pandoc.Div(el, { style = "text-align: center" })
  end
end
