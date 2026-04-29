#let paper(
  author: "Jann Fricke",
  abstract: none,
  date: "",
  cols: 1,
  gaps: 1em,
  bib: none,
  doc,
) = {

  let margin = 3.2cm
  if cols > 1 {
    margin = 2cm
  }
  set page(paper: "a4", margin: margin, columns: cols)
  set text(font: "Latin Modern Roman", size: 10pt)
  set par(leading: gaps, justify: true)

  show title: set text(weight: "regular")
  show title: set par(justify: false)
  show smallcaps: set text(font: "Latin Modern Roman Caps")

  // HEADINGS

  set heading(numbering: "I.A.a")
  show heading: it => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).get()
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }
    set text(weight: "regular")
    if it.level == 1 {
      // First-level headings are centered smallcaps.
      set align(center)
      show: block.with(above: 15pt, below: 13.75pt, sticky: true)
      show: smallcaps
      if it.numbering != none and it.body != [References]{
        numbering("I.", deepest)
        h(7pt, weak: true)
      }
      it.body
    } else if it.level == 2 {
      show: block.with(above: 15pt, below: 13.75pt, sticky: true)
      if it.numbering != none {
        numbering("A.", deepest)
        h(7pt, weak: true)
      }
      it.body
    }
  }

  show heading: set text(
    weight: "regular"
  )
  show heading.where(level: 1): smallcaps
  show heading.where(level: 1): set align(center)
  show heading.where(level: 1): set heading(numbering: "I.")
  show heading.where(level: 2): emph

  set std.bibliography(title: text()[References], style: "ieee")
  
  
  place(
    top + center,
    float: true,
    scope: "parent",
    clearance: 2em,
    {
      title()
      par(text(size: 1.1em, author + "\n" + date))
      if abstract != none {
        par(justify: false, leading: 1em)[
          #text(size: 13pt)[#smallcaps[*Abstract*]] \
          #abstract
        ]
      } else {
        v(2em)
      }
    }
  )

  doc
  bib
}

#set document(title: [
  A Fluid Dynamic Model for
  Glacier Flow
])

#show: paper.with(
  date: "Febuary 2026",
  abstract: none,
  cols: 1
)

= Introduction
#lorem(90)

== Motivation
#lorem(140)

==== hello
#lorem(20)

== Problem Statement
#lorem(50)

= Related Work
#lorem(200)


