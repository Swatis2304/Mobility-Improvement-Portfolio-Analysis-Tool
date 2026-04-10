app_server <- function(input, output, session) {
  
  baseline_data <- load_baseline_data()
  app_data <- reactiveVal(baseline_data)
  
  study_area <- mod_study_area_server("study_area", app_data)
  baseline <- mod_baseline_server("baseline", app_data, study_area)
  scenarios <- mod_scenarios_server("scenarios", app_data, study_area, baseline)
  results <- mod_results_server("results", baseline)
  cba <- mod_cba_server("cba", scenarios)
  mod_export_server("export", scenarios, cba)
}