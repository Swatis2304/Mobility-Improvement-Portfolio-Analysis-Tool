mod_instructions_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    h2("Urban Improvement Portfolio Analysis Tool"),
    p("This tool evaluates EV, bike, bus, and mixed infrastructure portfolios.")
  )
}