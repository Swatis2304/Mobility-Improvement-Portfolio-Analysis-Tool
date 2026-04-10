mod_cba_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    h3("Cost Benefit Analysis"),
    plotOutput(ns("npv_plot")),
    DTOutput(ns("cba_table"))
  )
}

mod_cba_server <- function(id, scenarios) {
  moduleServer(id, function(input, output, session) {
    
    output$npv_plot <- renderPlot({
      ggplot(data.frame(x = 1:5, y = c(0, 1, 2, 1.5, 3)), aes(x, y)) +
        geom_line() +
        theme_minimal()
    })
    
    output$cba_table <- renderDT({
      datatable(
        data.frame(
          Scenario = c("EV Charging", "Bike/Subway", "Bus/Subway", "Mixed"),
          Cost = c(NA, NA, NA, NA),
          Benefit = c(NA, NA, NA, NA),
          NPV = c(NA, NA, NA, NA),
          BCR = c(NA, NA, NA, NA)
        )
      )
    })
    
    reactive(list(status = "cba_placeholder"))
  })
}