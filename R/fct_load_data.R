load_baseline_data <- function() {
  list(
    cdta = sf::st_read("data/processed/cdta.gpkg", quiet = TRUE),
    roads = sf::st_read("data/processed/roads.gpkg", quiet = TRUE),
    tracts = sf::st_read("data/processed/tracts.gpkg", quiet = TRUE),
    ev = sf::st_read("data/processed/ev.gpkg", quiet = TRUE),
    transformers = sf::st_read("data/processed/transformers.gpkg", quiet = TRUE)
  )
}