mod_scenarios_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        checkboxGroupInput(
          ns("scenario_types"),
          "Scenarios to Evaluate",
          choices = c("EV Charging", "Bike/Subway Connectivity", "Bus/Subway Connectivity", "Mixed Portfolio"),
          selected = c("EV Charging")
        ),
        sliderInput(ns("pop_growth"), "Population Growth Rate (%)", min = 0, max = 5, value = 1.5, step = 0.1),
        sliderInput(ns("discount_rate"), "Discount Rate (%)", min = 2, max = 10, value = 4, step = 0.5),
        actionButton(ns("run_scenarios"), "Run Scenarios")
      ),
      mainPanel(
        verbatimTextOutput(ns("scenario_info"))
      )
    )
  )
}

mod_scenarios_server <- function(id, app_data, study_area, baseline) {
  moduleServer(id, function(input, output, session) {
    
    output$scenario_info <- renderPrint({
      list(
        scenarios = input$scenario_types,
        pop_growth = input$pop_growth,
        discount_rate = input$discount_rate
      )
    })
    
    eventReactive(input$run_scenarios, {
      list(
        scenarios = input$scenario_types,
        pop_growth = input$pop_growth,
        discount_rate = input$discount_rate,
        status = "scenario_placeholder"
      )
    }, ignoreInit = FALSE)
  })
}