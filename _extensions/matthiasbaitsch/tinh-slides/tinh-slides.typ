// Typst-Teil von tinh-slides: Theme und Befehle
// touying selbst importiert das Template der eingebetteten Bridge (gleiche Datei, steht davor)
#import "@preview/touying-quarto-clean:0.2.1": *

// Abschnittsfolie (Überschrift 1) wie bei clean, aber kleiner und leicht statt 2em fett
#let tinh-section-slide(self: none, body) = touying-slide-wrapper(self => {
  let main-body = {
    set align(left + horizon)
    set text(
      size: 1.6em,
      fill: self.colors.primary,
      weight: self.store.font-weight-heading,
      font: self.store.font-family-heading,
    )
    utils.display-current-heading(level: 1)
  }
  self = utils.merge-dicts(self, config-page(margin: (left: 2em, top: -0.25em)))
  touying-slide(self: self, main-body)
})

// clean mit Seitenzahl links, rechts unten ist Platz für das Logo (logo: in _extension.yml)
// Die Regel für Definitionen steht hier statt auf oberster Ebene, weil Quarto
// theorions show-definition (macht aus dem figure seinen Inhalt) erst danach
// im Header einbindet; das Theme wird später angewendet, die Regel greift so zuerst
#let tinh-clean-theme(..args) = {
  // Definition (::: {#def-...}) im Kasten wie bei tinh-notes
  // Titel nur regular statt fett: "Definition" setzt Quarto als text(weight: "bold"),
  // Nummer und Name per strong (light + 100 = regular)
  show figure.where(kind: "definition"): it => block(
    width: 100%,
    fill: rgb("#f5f5f5"),
    stroke: 1.5pt,
    radius: 5pt,
    inset: 0.6em,
    {
      show text.where(weight: "bold"): set text(weight: "regular")
      set strong(delta: 100)
      align(left, it)
    },
  )
  clean-theme(
    config-common(new-section-slide-fn: tinh-section-slide),
    hide-slide-numbers: true,
    footer: context utils.slide-counter.display() + " / " + utils.last-slide-number,
    ..args,
  )
}

// Befehle (Klassen per environment.lua der Bridge und commands: in _extension.yml, z. B. [Begriff]{.neuerbegriff})
#let neuerbegriff(body) = text(fill: rgb("#9a2515"), weight: "regular", body)
#let ja(body) = text(fill: rgb("#2e7d32"))[✓]
#let nein(body) = text(fill: red)[✗]

// Vertikaler Abstand wie .downN bei revealjs, z. B. []{.down20}
#let down(n) = body => { v(n * 1pt); body }
#let down10 = down(10)
#let down20 = down(20)
#let down30 = down(30)
#let down40 = down(40)
#let down50 = down(50)

// Tabellen ohne Typsts Standardraster
#set table(stroke: none)

// Abgesetzte Formeln linksbündig, 1em eingerückt
#show math.equation.where(block: true): set align(left)
#show math.equation.where(block: true): it => pad(left: 1em, it)

// Text in Code kleiner
#show raw.where(block: true): set text(size: 0.8em)

// Überschrift 3 aufrecht
#show heading.where(level: 3): it => text(style: "normal", it)
