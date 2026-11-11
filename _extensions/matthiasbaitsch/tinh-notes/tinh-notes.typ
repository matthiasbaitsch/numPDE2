// Typst-Teil von tinh-notes (include-before-body: steht nach Quartos Template, damit die Regeln nach denen von
// orange-book und theorion kommen und zuerst greifen)

// Absätze ohne Einzug, mit Abstand von etwa einer halben Zeile (wie KOMA parskip=half), statt Einzug von orange-book
#set par(first-line-indent: 0em, spacing: 1.2em)

// Nummern nur bis Ebene 3 (number-depth aus _extension.yml kommt bei Typst nicht an), Ebene 4 wie \paragraph
#show heading.where(level: 4): set heading(numbering: none)
#show heading.where(level: 5): set heading(numbering: none)

// Befehle (Klassen per commands.lua, z. B. [Begriff]{.neuerbegriff}), Farben wie tinh-notes.css
#let neuerbegriff(body) = text(fill: rgb("#b13434"), weight: "semibold", body)
#let eng(body) = emph(body)
#let ja(body) = text(fill: rgb("#2e7d32"))[✓]
#let nein(body) = text(fill: red)[✗]

// Nummern nur für Gleichungen mit Label ({#eq-...}), wie in HTML. Quarto setzt diese als math.equation mit
// numbering, orange-book nummeriert aber alle; die übrigen ohne Nummer und ohne den Zähler zu erhöhen
#show math.equation.where(block: true): it => {
  if it.numbering == none or it.has("label") {
    it
  } else {
    counter(math.equation).update(n => n - 1)
    math.equation(block: true, numbering: none, it.body)
  }
}

// Definitionen (#def-) und Beispiele (#exm-) wie .definition und .example in tinh-notes.css, mit Nummer.
// Titel, Nummer und Inhalt aus theorions Metadaten im figure (wie bei tinh-slides); der Zähler wird hier
// weitergezählt, weil theorions Inhalt (render und step) nicht ausgegeben wird
#let tinh-frame(it, separator, box) = {
  let frame = it.body.children.find(c => c.func() == metadata).value
  let prefix = (frame.get-prefix)(here, number: frame.number, supplement: frame.supplement)
  box({
    set align(left)
    // Ohne Erstzeileneinzug von orange-book, wie im HTML
    set par(first-line-indent: 0pt)
    strong[#prefix#if frame.title != "" [#separator#frame.title]]
    parbreak()
    frame.body
  })
  if frame.numbering != none and frame.number == auto {
    (frame.counter.step)()
  }
}

#show figure.where(kind: "definition"): it => tinh-frame(it, " – ", body => block(
  width: 100%,
  fill: rgb("#f5f5f5"),
  stroke: 1.5pt,
  radius: 5pt,
  inset: 0.6em,
  breakable: true,
  body,
))

#show figure.where(kind: "example"): it => tinh-frame(it, ": ", body => block(
  width: 100%,
  stroke: (left: 5pt + rgb("#e9967a")), // darksalmon
  inset: (left: 0.6em, y: 0.2em),
  breakable: true,
  body,
))
