# ============================================================
# 01_prep_baseline.R
# Run this ONCE to prepare all raw data into processed geopackages.
# Output goes to data/processed/ and is loaded by the Shiny app
# via fct_load_data.R
# ============================================================

library(sf)
library(dplyr)
library(readr)
library(stringr)

# ---- 0. Create output directory ----------------------------
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

# ============================================================
# 1. CDTA boundaries
# ============================================================
cdta <- st_read("data/raw/2020_Community_District_Tabulation_Areas_(CDTAs)_20260408.geojson",
                quiet = TRUE) %>%
  st_transform(6539)

cat("CDTA loaded:", nrow(cdta), "areas\n")
cat("Columns:", paste(names(cdta), collapse = ", "), "\n\n")

st_write(cdta, "data/processed/cdta.gpkg", delete_dsn = TRUE, quiet = TRUE)
cat("✓ cdta.gpkg saved\n\n")

# ============================================================
# 2. Roads (from GDB)
# ============================================================
layers <- st_layers("data/raw/AADT_2023.gdb")
print(layers)

roads_raw <- st_read("data/raw/AADT_2023.gdb", layer = "AADT_2023", quiet = TRUE) %>%
  st_transform(6539)

cat("Roads loaded:", nrow(roads_raw), "segments\n")
cat("Columns:", paste(names(roads_raw), collapse = ", "), "\n\n")

# Keep only columns needed for scoring
# Adjust column names here if yours differ
roads <- roads_raw %>%
  select(
    any_of(c(
      # AADT — primary demand signal
      "AADT_Stats_2023_Table_AADT",
      "AADT_Stats_2023_Table_Longitude",
      "AADT_Stats_2023_Table_Latitude",
      # Truck % — freight demand for EV
      "AADT_Stats_2023_Table_Truck_Percent",
      # Speed — dwell opportunity for EV, safety for bus
      "Traffic_Station_Locations_Speed",
      # Functional class — bus route suitability
      "AADT_Stats_2023_Table_Functional_Class",
      # geometry always kept automatically by sf
    ))
  )

cat("Roads columns kept:", paste(names(roads), collapse = ", "), "\n\n")

st_write(roads, "data/processed/roads.gpkg", delete_dsn = TRUE, quiet = TRUE)
cat("✓ roads.gpkg saved\n\n")

# ============================================================
# 3. Bus routes
# ============================================================
bus_routes <- st_read("data/raw/BUs routes shapefile/bus_routes_nyc_dec2019.shp",
                      quiet = TRUE) %>%
  st_transform(6539) %>%
  select(geometry)   # only geometry needed for gap scoring

cat("Bus routes loaded:", nrow(bus_routes), "routes\n\n")

st_write(bus_routes, "data/processed/bus_routes.gpkg", delete_dsn = TRUE, quiet = TRUE)
cat("✓ bus_routes.gpkg saved\n\n")

# ============================================================
# 4. Census tracts + ACS population
# ============================================================
pop <- read_csv(
  "data/raw/ACSDT5Y2024.B01003_2026-04-09T005055/ACSDT5Y2024.B01003-Data.csv",
  skip = 1,
  show_col_types = FALSE
)

pop_clean <- pop %>%
  select(
    GEO_ID   = Geography,
    NAME     = `Geographic Area Name`,
    population = `Estimate!!Total`
  ) %>%
  mutate(
    tract_id   = str_replace(GEO_ID, "1400000US", ""),
    population = as.numeric(population)
  ) %>%
  filter(!is.na(population))

cat("Population records loaded:", nrow(pop_clean), "\n")
cat("Population range:", min(pop_clean$population), "to", max(pop_clean$population), "\n\n")

tracts_raw <- st_read("data/raw/tl_2022_36_tract/tl_2022_36_tract.shp", quiet = TRUE) %>%
  st_transform(6539)

tracts <- tracts_raw %>%
  mutate(tract_id = as.character(GEOID)) %>%
  left_join(pop_clean %>% select(tract_id, population), by = "tract_id")

cat("Tracts loaded:", nrow(tracts), "\n")
cat("Tracts with population:", sum(!is.na(tracts$population)), "\n")
cat("Tracts missing population:", sum(is.na(tracts$population)), "\n\n")

st_write(tracts, "data/processed/tracts.gpkg", delete_dsn = TRUE, quiet = TRUE)
cat("✓ tracts.gpkg saved\n\n")

# ============================================================
# 5. EV stations
# ============================================================
ev_raw <- read_csv("data/raw/alt_fuel_stations (Apr 9 2026).csv",
                   show_col_types = FALSE)

cat("EV stations loaded:", nrow(ev_raw), "\n")
cat("EV columns:", paste(names(ev_raw), collapse = ", "), "\n\n")

ev_sf <- ev_raw %>%
  filter(!is.na(Longitude), !is.na(Latitude)) %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326) %>%
  st_transform(6539)

cat("EV stations with valid coordinates:", nrow(ev_sf), "\n\n")

st_write(ev_sf, "data/processed/ev.gpkg", delete_dsn = TRUE, quiet = TRUE)
cat("✓ ev.gpkg saved\n\n")

# ============================================================
# 6. Transformers (460v + 208v)
# ============================================================

# -- 460v --
tx460 <- read_csv("data/raw/460v Transformers - Summer Capacity.csv",
                  show_col_types = FALSE) %>%
  filter(!is.na(x), !is.na(y)) %>%
  mutate(source_kv = "460v")

cat("460v transformers loaded:", nrow(tx460), "\n")
cat("460v columns:", paste(names(tx460), collapse = ", "), "\n")

# -- 208v --
tx208 <- read_csv("data/raw/208v Transformers - Summer Capacity.csv",
                  show_col_types = FALSE) %>%
  filter(!is.na(x), !is.na(y)) %>%
  mutate(source_kv = "208v")

cat("208v transformers loaded:", nrow(tx208), "\n")
cat("208v columns:", paste(names(tx208), collapse = ", "), "\n\n")

# Combine — bind_rows handles mismatched columns gracefully
transformers_sf <- bind_rows(tx460, tx208) %>%
  st_as_sf(coords = c("x", "y"), crs = 6539, remove = FALSE) %>%
  st_transform(6539)

cat("Combined transformers:", nrow(transformers_sf), "\n")
cat("Source breakdown:\n")
print(table(transformers_sf$source_kv))

# Check the capacity column is present
cap_col <- intersect(
  names(transformers_sf),
  c("Summer Capacity Range (MW)",
    "Summer.Capacity.Range..MW.",
    "SummerCapacity", "kva", "KVA")
)[1]

if (!is.na(cap_col)) {
  cat("\nCapacity column found:", cap_col, "\n")
  print(table(transformers_sf[[cap_col]], useNA = "always"))
} else {
  warning("Capacity column NOT found — transformer kVA weighting will be disabled. ",
          "Check column names above and update fct_scoring.R detection list.")
}

cat("\n")

st_write(transformers_sf, "data/processed/transformers.gpkg",
         delete_dsn = TRUE, quiet = TRUE)
cat("✓ transformers.gpkg saved\n\n")

# ============================================================
# 7. Quick validation — check all files exist and have rows
# ============================================================
cat("============================================================\n")
cat("VALIDATION CHECK\n")
cat("============================================================\n")

files <- c("cdta", "roads", "tracts", "ev", "transformers", "bus_routes")

for (f in files) {
  path <- paste0("data/processed/", f, ".gpkg")
  if (file.exists(path)) {
    layer <- st_read(path, quiet = TRUE)
    cat(sprintf("✓ %-15s %d rows | CRS: %s\n",
                paste0(f, ".gpkg"),
                nrow(layer),
                st_crs(layer)$input))
  } else {
    cat(sprintf("✗ %-15s FILE MISSING\n", paste0(f, ".gpkg")))
  }
}

cat("\n✓ Prep complete. Run the Shiny app with: shiny::runApp('.')\n")
