-- Scaffold, solution and given code marked in HTML, for documents with the step `show-markers`
function Meta(meta)
  if quarto.doc.is_format("html") then
    quarto.doc.add_html_dependency({ name = "loimoi-markers", stylesheets = { "loimoi-markers.css" } })
  end
  return meta
end
