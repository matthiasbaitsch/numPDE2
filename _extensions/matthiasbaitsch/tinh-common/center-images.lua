-- Zentriert Absätze, die nur aus Bildern bestehen (Bilder ohne Bildunterschrift). Bilder mit Bildunterschrift sind
-- Abbildungen und werden über fig-align zentriert. Bilder mit eigenem fig-align oder den revealjs-Klassen absolute
-- und r-stretch bleiben unverändert, ebenso Bilder in Layouts (layout, layout-ncol, layout-nrow), dort setzt Quarto
-- die Zellen selbst.
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

local function is_layout(el)
  return el.attributes["layout"] or el.attributes["layout-ncol"] or el.attributes["layout-nrow"]
end

return {
  {
    traverse = "topdown",
    Div = function(el)
      if is_layout(el) then
        return el, false
      end
    end,    Para = function(el)
      if not only_images(el.content) then
        return nil
      end
      if quarto.doc.is_format("latex") then
        return { pandoc.RawBlock("latex", "\\begin{center}"), el, pandoc.RawBlock("latex", "\\end{center}") }, false
      elseif quarto.doc.is_format("typst") then
        return { pandoc.RawBlock("typst", "#align(center)["), el, pandoc.RawBlock("typst", "]") }, false
      elseif quarto.doc.is_format("html") then
        return pandoc.Div(el, { style = "text-align: center" }), false
      end
    end,
  },
}
