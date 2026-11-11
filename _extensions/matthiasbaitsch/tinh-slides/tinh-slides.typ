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
  // Definition (::: {#def-...}) im Kasten wie bei tinh-notes, ohne Nummer
  // Titel und Inhalt aus theorions Metadaten im figure, Aufbau wie Quartos simple-theorem-render
  // Titel nur regular statt fett: "Definition" setzt Quarto als text(weight: "bold"),
  // Name per strong (light + 100 = regular)
  show figure.where(kind: "definition"): it => {
    let frame = it.body.children.find(c => c.func() == metadata).value
    block(
      width: 100%,
      fill: rgb("#f5f5f5"),
      stroke: 1.5pt,
      radius: 5pt,
      inset: 0.6em,
      {
        show text.where(weight: "bold"): set text(weight: "regular")
        set strong(delta: 100)
        set align(left)
        strong[#it.supplement#if frame.title != "" [ (#frame.title)]]
        h(0.5em)
        emph(frame.body)
      },
    )
  }
  // Beispiel (::: {#exm-...}) mit Balken links wie bei tinh-notes, ohne Nummer
  // Titel "Beispiel: Name" in einer eigenen Zeile, Inhalt aufrecht
  show figure.where(kind: "example"): it => {
    let frame = it.body.children.find(c => c.func() == metadata).value
    block(
      width: 100%,
      stroke: (left: 5pt + rgb("#e9967a")), // darksalmon
      inset: (left: 0.6em, y: 0.2em),
      {
        show text.where(weight: "bold"): set text(weight: "regular")
        set strong(delta: 100)
        set align(left)
        strong[#it.supplement#if frame.title != "" [: #frame.title]]
        parbreak()
        frame.body
      },
    )
  }
  clean-theme(
    config-common(new-section-slide-fn: tinh-section-slide),
    hide-slide-numbers: true,
    footer: context utils.slide-counter.display() + " / " + utils.last-slide-number,
    ..args,
  )
}

// Befehle (Klassen per environment.lua der Bridge und commands: in _extension.yml, z. B. [Begriff]{.neuerbegriff})
#let neuerbegriff(body) = text(fill: rgb("#9a2515"), weight: "regular", body)
#let eng(body) = emph(body)
// Abschnitte (Überschriften 1) als Aufzählung, z. B. []{.inhalt} auf einer Inhaltsfolie
#let inhalt(body) = context list(tight: false, ..query(heading.where(level: 1)).map(h => h.body))
#let ja(body) = text(fill: rgb("#2e7d32"))[✓]
#let nein(body) = text(fill: red)[✗]

// Vertikaler Abstand wie .downN und .upN bei revealjs, z. B. []{.down20}
#let down(n) = body => { v(n * 1pt); body }
#let down5 = down(5)
#let down10 = down(10)
#let down20 = down(20)
#let down30 = down(30)
#let down40 = down(40)
#let down50 = down(50)
#let up5 = down(-5)
#let up10 = down(-10)
#let up20 = down(-20)
#let up30 = down(-30)
#let up40 = down(-40)
#let up50 = down(-50)

// Tabellen ohne Typsts Standardraster, Text kleiner
#set table(stroke: none)
#show table: set text(size: 0.75em)

// Abgesetzte Formeln linksbündig, 1em eingerückt
#show math.equation.where(block: true): set align(left)
#show math.equation.where(block: true): it => pad(left: 1em, it)

// Text in Code kleiner
#show raw.where(block: true): set text(size: 0.8em)

// Überschrift 3 aufrecht
#show heading.where(level: 3): it => text(style: "normal", it)
