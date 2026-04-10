rescale_01 <- function(x) {
  rng <- range(x, na.rm = TRUE)
  
  if (!is.finite(rng[1]) || !is.finite(rng[2]) || diff(rng) == 0) {
    return(rep(0.5, length(x)))
  }
  
  (x - rng[1]) / (rng[2] - rng[1])
}

score_ev_roads <- function(roads, tracts, ev, transformers = NULL) {
  
  if (nrow(roads) == 0) {
    roads$near_pop <- numeric(0)
    roads$pop_score <- numeric(0)
    roads$dist_to_ev <- numeric(0)
    roads$ev_gap_score <- numeric(0)
    roads$dist_to_tx <- numeric(0)
    roads$tx_score <- numeric(0)
    roads$ev_score <- numeric(0)
    return(roads)
  }
  
  road_centroids <- sf::st_centroid(roads)
  
  # Population proximity score
  if (nrow(tracts) > 0) {
    tract_centroids <- sf::st_centroid(tracts)
    nearest_tract <- sf::st_nearest_feature(road_centroids, tract_centroids)
    roads$near_pop <- tracts$population[nearest_tract]
    roads$pop_score <- rescale_01(roads$near_pop)
  } else {
    roads$near_pop <- 0
    roads$pop_score <- 0
  }
  
  # EV gap score: farther from existing EV stations = higher need
  if (nrow(ev) > 0) {
    nearest_ev <- sf::st_nearest_feature(road_centroids, ev)
    roads$dist_to_ev <- as.numeric(
      sf::st_distance(road_centroids, ev[nearest_ev, ], by_element = TRUE)
    )
    roads$ev_gap_score <- rescale_01(roads$dist_to_ev)
  } else {
    roads$dist_to_ev <- NA_real_
    roads$ev_gap_score <- 1
  }
  
  # Transformer proximity score: closer to transformer = better
  if (!is.null(transformers) && nrow(transformers) > 0) {
    nearest_tx <- sf::st_nearest_feature(road_centroids, transformers)
    roads$dist_to_tx <- as.numeric(
      sf::st_distance(road_centroids, transformers[nearest_tx, ], by_element = TRUE)
    )
    roads$tx_score <- 1 - rescale_01(roads$dist_to_tx)
  } else {
    roads$dist_to_tx <- NA_real_
    roads$tx_score <- 0.5
  }
  
  roads$ev_score <- round(
    100 * (
      0.4 * roads$pop_score +
        0.3 * roads$ev_gap_score +
        0.3 * roads$tx_score
    ),
    1
  )
  
  roads
}