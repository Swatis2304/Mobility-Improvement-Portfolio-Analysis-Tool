app_ui <- function() {
  bslib::page_navbar(
    id = "main_nav",
    title = "Urban Improvement Portfolio Analysis Tool",
    
    bslib::nav_panel(
      title = "Instructions",
      value = "instructions",
      mod_instructions_ui("instructions")
    ),
    bslib::nav_panel(
      title = "Study Area",
      value = "study_area",
      mod_study_area_ui("study_area")
    ),
    bslib::nav_panel(
      title = "Baseline",
      value = "baseline",
      mod_baseline_ui("baseline")
    ),
    bslib::nav_panel(
      title = "Scenarios",
      value = "scenarios",
      mod_scenarios_ui("scenarios")
    ),
    bslib::nav_panel(
      title = "Results",
      value = "results",
      mod_results_ui("results")
    ),
    bslib::nav_panel(
      title = "CBA",
      value = "cba",
      mod_cba_ui("cba")
    ),
    bslib::nav_panel(
      title = "Export",
      value = "export",
      mod_export_ui("export")
    )
  )
}