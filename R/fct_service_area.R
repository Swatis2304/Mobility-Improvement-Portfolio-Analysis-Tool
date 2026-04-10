buffer_and_union <- function(x, dist_ft) {
  if (nrow(x) == 0) {
    return(NULL)
  }
  
  x %>%
    sf::st_buffer(dist_ft) %>%
    sf::st_union() %>%
    sf::st_as_sf()
}

calc_population_served <- function(tracts_sf, service_area_sf, pop_col = "population") {
  if (is.null(service_area_sf) || nrow(tracts_sf) == 0) {
    return(0)
  }
  
  served <- suppressWarnings(sf::st_intersection(tracts_sf, service_area_sf))
  sum(served[[pop_col]], na.rm = TRUE)
}