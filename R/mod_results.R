mod_results_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    h3("Top EV Candidate Roads"),
    leafletOutput(ns("ev_score_map"), height = "600px", width = "100%"),
    br(),
    DTOutput(ns("ev_top_table"))
  )
}

mod_results_server <- function(id, scenarios) {
  moduleServer(id, function(input, output, session) {
    
    output$ev_score_map <- renderLeaflet({
      fd <- scenarios()
      req(fd)
      req(!is.null(fd$ev_scored_roads))
      req(nrow(fd$ev_scored_roads) > 0)
      
      roads_map <- sf::st_transform(fd$ev_scored_roads, 4326) %>% sf::st_make_valid()
      bbox <- sf::st_bbox(roads_map)
      
      pal <- colorNumeric(
        palette = "YlOrRd",
        domain = roads_map$ev_score,
        na.color = "transparent"
      )
      
      leaflet(roads_map) %>%
        addTiles() %>%
        addPolylines(
          color = ~pal(ev_score),
          weight = 3,
          opacity = 0.9,
          popup = ~paste0(
            "<b>EV Score:</b> ", ev_score,
            "<br><b>Nearby Population:</b> ", round(near_pop, 0),
            "<br><b>Distance to EV (ft):</b> ", round(dist_to_ev, 0),
            "<br><b>Distance to Transformer (ft):</b> ", round(dist_to_tx, 0)
          )
        ) %>%
        addLegend(
          "bottomright",
          pal = pal,
          values = ~ev_score,
          title = "EV Suitability Score"
        ) %>%
        fitBounds(
          lng1 = as.numeric(bbox["xmin"]),
          lat1 = as.numeric(bbox["ymin"]),
          lng2 = as.numeric(bbox["xmax"]),
          lat2 = as.numeric(bbox["ymax"])
        )
    })
    
    output$ev_top_table <- renderDT({
      fd <- scenarios()
      req(fd)
      req(!is.null(fd$ev_scored_roads))
      req(nrow(fd$ev_scored_roads) > 0)
      
      top_roads <- fd$ev_scored_roads %>%
        sf::st_drop_geometry() %>%
        dplyr::mutate(road_id = dplyr::row_number()) %>%
        dplyr::select(
          road_id,
          ev_score,
          near_pop,
          dist_to_ev,
          dist_to_tx,
          pop_score,
          ev_gap_score,
          tx_score
        ) %>%
        dplyr::arrange(dplyr::desc(ev_score)) %>%
        head(20)
      
      DT::datatable(
        top_roads,
        options = list(pageLength = 10, scrollX = TRUE),
        rownames = FALSE
      )
    })
    
    reactive({
      scenarios()
    })
  })
}