mod_export_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    h3("Export Results"),
    downloadButton(ns("download_excel"), "Download Excel")
  )
}

mod_export_server <- function(id, scenarios, cba) {
  moduleServer(id, function(input, output, session) {
    output$download_excel <- downloadHandler(
      filename = function() {
        paste0("urban_portfolio_results_", Sys.Date(), ".xlsx")
      },
      content = function(file) {
        wb <- openxlsx2::wb_workbook()
        wb$add_worksheet("Summary")
        wb$add_data("Summary", data.frame(Message = "Placeholder export"))
        wb$save(file)
      }
    )
  })
}