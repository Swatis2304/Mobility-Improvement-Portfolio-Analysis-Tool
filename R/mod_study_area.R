mod_study_area_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    sidebarLayout(
      sidebarPanel(
        selectInput(
          ns("area_mode"),
          "Study Area Mode",
          choices = c("CDTA", "Upload Corridor", "Upload Area")
        ),
        
        uiOutput(ns("cdta_select_ui")),
        
        fileInput(
          ns("upload_file"),
          "Upload Custom Geometry",
          accept = c(".geojson", ".zip")
        ),
        
        checkboxInput(
          ns("clip_to_cdta"),
          "If upload is used, clip it to selected CDTA",
          value = FALSE
        ),
        
        sliderInput(
          ns("analysis_years"),
          "Analysis Period (Years)",
          min = 5, max = 30, value = 15, step = 5
        ),
        
        sliderInput(
          ns("budget_millions"),
          "Budget ($M)",
          min = 5, max = 500, value = 50, step = 5
        )
      ),
      
      mainPanel(
        h3("Study Area Preview"),
        verbatimTextOutput(ns("study_area_info"))
      )
    )
  )
}

mod_study_area_server <- function(id, app_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    cdta_name_col <- "cdtaname"   
    
    output$cdta_select_ui <- renderUI({
      req(app_data())
      req("cdta" %in% names(app_data()))
      
      cdta <- app_data()$cdta
      req(nrow(cdta) > 0)
      
      selectInput(
        ns("cdta_name"),
        "CDTA",
        choices = sort(unique(as.character(cdta[[cdta_name_col]])))
      )
    })
    
    uploaded_sf <- reactive({
      req(input$upload_file)
      
      ext <- tolower(tools::file_ext(input$upload_file$name))
      
      if (ext %in% c("geojson", "json")) {
        sf::st_read(input$upload_file$datapath, quiet = TRUE) %>%
          sf::st_make_valid() %>%
          sf::st_transform(6539)
      } else {
        NULL
      }
    })
    
    study_geom <- reactive({
      req(app_data())
      cdta <- app_data()$cdta
      
      if (input$area_mode == "CDTA") {
        req(input$cdta_name)
        
        cdta %>%
          dplyr::filter(.data[[cdta_name_col]] == input$cdta_name)
      } else {
        req(uploaded_sf())
        up <- uploaded_sf()
        
        if (isTRUE(input$clip_to_cdta) && !is.null(input$cdta_name)) {
          cdta_geom <- cdta %>%
            dplyr::filter(.data[[cdta_name_col]] == input$cdta_name)
          
          sf::st_intersection(up, cdta_geom)
        } else {
          up
        }
      }
    })
    
    output$study_area_info <- renderPrint({
      list(
        area_mode = input$area_mode,
        cdta_name = input$cdta_name,
        analysis_years = input$analysis_years,
        budget_millions = input$budget_millions
      )
    })
    
    reactive({
      list(
        area_mode = input$area_mode,
        cdta_name = input$cdta_name,
        study_geom = study_geom(),
        analysis_years = input$analysis_years,
        budget_millions = input$budget_millions
      )
    })
  })
}