-- Logo der Brand auf jeder Folie wie Quartos eingebautes Logo (Klasse slide-logo, Größen small, medium, large).
-- Ersatz, weil Quarto den Pfad bei Dokumenten in Unterordnern ab Wurzel schreibt (/_brand/...) und die Datei nicht
-- kopiert. Hier wird die Datei als Daten-URI eingebettet, Quartos Logo ist abgeschaltet (logo: false).
local mime_types = { svg = "image/svg+xml", png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg" }

local function data_uri(file)
  local ext = file:match("%.(%w+)$")
  local mime = ext and mime_types[ext:lower()]
  local f = mime and io.open(file, "rb")
  if not f then
    return nil
  end
  local data = f:read("a")
  f:close()
  local encoded = data:gsub("[^%w%-%._~]", function(c)
    return string.format("%%%02X", c:byte())
  end)
  return "data:" .. mime .. "," .. encoded
end

function Pandoc(doc)
  local logo
  for _, size in ipairs({ "small", "medium", "large" }) do
    logo = quarto.brand.get_logo("light", size)
    if logo then
      break
    end
  end
  if logo == nil or logo.path == nil then
    return doc
  end
  local src = logo.path
  if not src:match("^%w+:") then
    local dir = quarto.project.directory or pandoc.path.directory(quarto.doc.input_file)
    src = data_uri(pandoc.path.join({ dir, logo.path }))
    if src == nil then
      quarto.log.warning("tinh-slides: Logo nicht gefunden: " .. logo.path)
      return doc
    end
  end
  local alt = logo.alt and (' alt="' .. logo.alt .. '"') or ""
  doc.blocks:insert(pandoc.RawBlock("html", '<img src="' .. src .. '"' .. alt .. ' class="slide-logo">'))
  return doc
end
