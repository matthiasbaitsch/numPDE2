// Aufgaben mit aufrechtem Text und ohne Punkt hinter dem Titel. Ersetzt die
// Umgebung, die Quarto im Kopf definiert (theorem-appearance: simple setzt jeden
// Lehrsatz kursiv), steht daher in include-before-body.
#import "@preview/theorion:0.4.1": make-frame

#let (exercise-counter, exercise-box, exercise, show-exercise) = make-frame(
  "exercise",
  text(weight: "bold")[Aufgabe],
  inherited-levels: theorem-inherited-levels,
  numbering: theorem-numbering,
  render: (prefix: none, title: "", full-title: auto, body) => {
    if full-title != "" and full-title != auto and full-title != none {
      strong(full-title)
      h(0.5em)
    }
    body
    parbreak()
  },
)
