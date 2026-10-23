// Ersetzt Quartos article-Funktion durch eine schlanke Fassung für Aufgabenblätter:
// Titel und Untertitel linksbündig, mehr Abstand unter Überschriften. Weitere
// Argumente aus Quartos typst-show.typ (Autoren, Datum, Inhaltsverzeichnis, ...)
// werden ignoriert.
#let article(
  title: none,
  subtitle: none,
  lang: "de",
  region: "DE",
  font: none,
  fontsize: 11pt,
  ..rest,
  doc,
) = {
  set document(title: title)
  set text(lang: lang, region: region, size: fontsize)
  set text(font: font) if font != none
  set par(justify: true, leading: 0.65em)
  show heading: set block(below: 1em)

  if title != none {
    block(inset: (y: 0em), below: 3em)[
      #set par(leading: 0.65em, spacing: 0.75em)
      #text(size: 1.5em, weight: "bold", title)
      #if subtitle != none {
        parbreak()
        text(size: 1.25em, subtitle)
      }
    ]
  }

  doc
}

#set table(
  inset: 4pt,
  stroke: none
)

// gt-Tabellen kommen über Quartos CSS-Übersetzung mit fest 12pt (16px) an
#show table: it => context {
  if text.size == 12pt { set text(size: 0.8em); it } else { it }
}

