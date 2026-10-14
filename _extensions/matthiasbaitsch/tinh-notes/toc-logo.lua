-- Logo der Brand (logo.medium) über dem Titel des Inhaltsverzeichnisses (toc-title), nur HTML und nur, wenn das
-- Dokument einen toc-title hat und kein Buch bzw. keine Website ist (dort steht das Logo in der Seitenleiste).
-- Eine URL wird direkt verwendet, eine lokale Datei als Daten-URI eingebettet.
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
  if not quarto.doc.is_format("html") or meta["toc-title"] == nil then
    return meta
  end
  -- Bücher und Websites zeigen das Logo der Brand schon in der Seitenleiste
  if meta["book"] ~= nil or meta["website"] ~= nil then
    return meta
  end
  local logo = quarto.brand.get_logo("light", "medium")
  if logo == nil or logo.path == nil then
    return meta
  end
  local uri = logo.path:match("^https?://") and logo.path
    or data_uri(pandoc.path.join({ quarto.project.directory or ".", logo.path }))
  if uri == nil then
    quarto.log.warning("tinh-notes: Logo nicht gefunden: " .. logo.path)
    return meta
  end
  local blocks = pandoc.Blocks({ pandoc.Para({ pandoc.Image({}, uri, "", pandoc.Attr("", { "toc-logo" })) }) })
  local title = meta["toc-title"]
  if pandoc.utils.type(title) == "Blocks" then
    blocks:extend(title)
  else
    blocks:insert(pandoc.Plain(pandoc.Inlines(title)))
  end
  meta["toc-title"] = blocks
  return meta
end
