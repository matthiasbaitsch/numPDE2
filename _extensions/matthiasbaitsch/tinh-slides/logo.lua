-- Logo der Brand (logo.medium) auf der Titelfolie.
-- revealjs: Bild vor dem Titel (siehe titlepage.scss). Eine URL wird direkt verwendet, eine lokale Datei (SVG, PNG,
-- JPG) als Daten-URI eingebettet, damit es ohne Pfade und Kopieren funktioniert (Unterordner, output-dir, Zips).
-- typst: Pfad relativ zum Dokument in der Variable tinh-logo (siehe typst-show.typ und tinh-slides.typ), nur lokale
-- Dateien (Typst lädt keine Bilder aus dem Netz).
local mime_types = { svg = "image/svg+xml", png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg" }

local function base64(data)
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  return ((data:gsub(".", function(x)
    local r, b = "", x:byte()
    for i = 8, 1, -1 do
      r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
    end
    return r
  end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
    if #x < 6 then
      return ""
    end
    local c = 0
    for i = 1, 6 do
      c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
    end
    return chars:sub(c + 1, c + 1)
  end) .. ({ "", "==", "=" })[#data % 3 + 1])
end

-- Lokale Bilddatei als Daten-URI (SVG, PNG, JPG)
local function data_uri(file)
  local ext = file:match("%.(%w+)$")
  local mime = ext and mime_types[ext:lower()]
  if mime == nil then
    return nil
  end
  local f = io.open(file, "rb")
  if f == nil then
    return nil
  end
  local data = f:read("a")
  f:close()
  return "data:" .. mime .. ";base64," .. base64(data)
end

function Meta(meta)
  local logo = quarto.brand.get_logo("light", "medium")
  if logo == nil or logo.path == nil then
    return meta
  end
  local is_url = logo.path:match("^https?://") ~= nil
  if is_url and quarto.doc.is_format("typst") then
    quarto.log.warning("tinh-slides: Typst kann das Logo nicht aus dem Netz laden: " .. logo.path)
    return meta
  end
  local file = pandoc.path.join({ quarto.project.directory or ".", logo.path })
  if quarto.doc.is_format("typst") then
    local dir = pandoc.path.directory(quarto.doc.input_file)
    meta["tinh-logo"] = pandoc.RawInline("typst", pandoc.path.make_relative(file, dir, true))
    return meta
  end
  local uri = is_url and logo.path or data_uri(file)
  if uri == nil then
    quarto.log.warning("tinh-slides: Logo nicht gefunden: " .. logo.path)
    return meta
  end
  local title = meta["title"] and pandoc.Inlines(meta["title"]) or pandoc.Inlines({})
  title:insert(1, pandoc.Image({}, uri, "", pandoc.Attr("", { "title-logo" })))
  meta["title"] = title
  return meta
end
