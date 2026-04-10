mod_baseline_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    leafletOutput(ns("baseline_map"), height = "650px", width = "100%"),
    br(),
    DTOutput(ns("baseline_table"))
  )
}

mod_baseline_server <- function(id, app_data, study_area) {
  moduleServer(id, function(input, output, session) {
    
    filtered_data <- reactive({
      req(app_data())
      req(study_area())
      req(study_area()$study_geom)
      
      data <- app_data()
      geom <- study_area()$study_geom
      
      roads <- suppressWarnings(sf::st_intersection(data$roads, geom))
      tracts <- suppressWarnings(sf::st_intersection(data$tracts, geom))
      ev <- suppressWarnings(sf::st_intersection(data$ev, geom))
      transformers <- suppressWarnings(sf::st_intersection(data$transformers, geom))
      
      ev_service_area <- buffer_and_union(ev, dist_ft = 2640)
      
      total_pop <- sum(tracts$population, na.rm = TRUE)
      ev_served_pop <- calc_population_served(tracts, ev_service_area)
      
      ev_scored_roads <- score_ev_roads(
        roads = roads,
        tracts = tracts,
        ev = ev,
        transformers = transformers
      )
      
      list(
        area = geom,
        roads = roads,
        tracts = tracts,
        ev = ev,
        transformers = transformers,
        ev_service_area = ev_service_area,
        total_pop = total_pop,
        ev_served_pop = ev_served_pop,
        ev_scored_roads = ev_scored_roads
      )
    })
    
    output$baseline_map <- renderLeaflet({
      fd <- filtered_data()
      
      area_map <- sf::st_transform(fd$area, 4326) %>% sf::st_make_valid()
      roads_map <- sf::st_transform(fd$roads, 4326) %>% sf::st_make_valid()
      ev_map <- sf::st_transform(fd$ev, 4326) %>% sf::st_make_valid()
      transformers_map <- sf::st_transform(fd$transformers, 4326) %>% sf::st_make_valid()
      
      bbox <- sf::st_bbox(area_map)
      
      m <- leaflet() %>%
        addTiles() %>%
        addPolygons(
          data = area_map,
          fillColor = "yellow",
          fillOpacity = 0.15,
          color = "red",
          weight = 3
        )
      
      if (nrow(roads_map) > 0) {
        m <- m %>%
          addPolylines(
            data = roads_map,
            color = "gray40",
            weight = 1,
            opacity = 0.6
          )
      }
      
      if (!is.null(fd$ev_service_area)) {
        ev_service_area_map <- sf::st_transform(fd$ev_service_area, 4326) %>% sf::st_make_valid()
        
        m <- m %>%
          addPolygons(
            data = ev_service_area_map,
            fillColor = "green",
            fillOpacity = 0.10,
            color = "green",
            weight = 1
          )
      }
      
      if (nrow(ev_map) > 0) {
        m <- m %>%
          addCircleMarkers(
            data = ev_map,
            color = "green",
            radius = 4,
            stroke = FALSE,
            fillOpacity = 0.9
          )
      }
      
      if (nrow(transformers_map) > 0) {
        m <- m %>%
          addCircleMarkers(
            data = transformers_map,
            color = "purple",
            radius = 3,
            stroke = FALSE,
            fillOpacity = 0.8
          )
      }
      
      m %>%
        fitBounds(
          lng1 = as.numeric(bbox["xmin"]),
          lat1 = as.numeric(bbox["ymin"]),
          lng2 = as.numeric(bbox["xmax"]),
          lat2 = as.numeric(bbox["ymax"])
        )
    })
    
    outputOptions(output, "baseline_map", suspendWhenHidden = FALSE)
    
    output$baseline_table <- renderDT({
      fd <- filtered_data()
      
      DT::datatable(
        data.frame(
          Metric = c(
            "Road Segments",
            "Census Tracts",
            "EV Stations",
            "Transformers",
            "Total Population",
            "Population Served by EV",
            "EV Service Share (%)",
            "Average EV Road Score",
            "Top EV Road Score"
          ),
          Value = c(
            nrow(fd$roads),
            nrow(fd$tracts),
            nrow(fd$ev),
            nrow(fd$transformers),
            fd$total_pop,
            fd$ev_served_pop,
            round(100 * fd$ev_served_pop / ifelse(fd$total_pop == 0, 1, fd$total_pop), 1),
            round(mean(fd$ev_scored_roads$ev_score, na.rm = TRUE), 1),
            round(max(fd$ev_scored_roads$ev_score, na.rm = TRUE), 1)
          )
        ),
        options = list(dom = "t"),
        rownames = FALSE
      )
    })
    
    reactive({
      filtered_data()
    })
  })
}