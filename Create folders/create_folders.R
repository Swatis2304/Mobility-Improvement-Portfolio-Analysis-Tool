dirs <- c(
  +     "R",
  +     "data/raw",
  +     "data/processed",
  +     "data/lookup",
  +     "sql",
  +     "templates",
  +     "outputs/maps",
  +     "outputs/tables",
  +     "outputs/reports",
  +     "www"
  + )
> 
  > for (d in dirs) dir.create(d, recursive = TRUE, showWarnings = FALSE)
> 
  > files <- c(
    +     "app.R",
    +     "global.R",
    +     "README.md",
    +     ".gitignore",
    +     "R/app_ui.R",
    +     "R/app_server.R",
    +     "R/mod_instructions.R",
    +     "R/mod_study_area.R",
    +     "R/mod_baseline.R",
    +     "R/mod_scenarios.R",
    +     "R/mod_results.R",
    +     "R/mod_cba.R",
    +     "R/mod_export.R",
    +     "R/fct_load_data.R",
    +     "R/fct_validation.R",
    +     "R/fct_service_area.R",
    +     "R/fct_scoring.R",
    +     "R/fct_cba.R",
    +     "R/fct_export.R",
    +     "R/utils_formatting.R",
    +     "sql/schema.sql",
    +     "sql/load_tables.sql",
    +     "sql/queries.sql",
    +     "templates/portfolio_results_template.xlsx",
    +     "www/custom.css"
    + )
  > 