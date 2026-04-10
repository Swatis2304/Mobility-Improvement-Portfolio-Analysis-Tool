library(sf)
library(dplyr)
library(readr)
library(stringr)

cdta <- st_read("data/raw/2020_Community_District_Tabulation_Areas_(CDTAs)_20260408.geojson") %>%
  st_transform(6539)

library(sf)
# Check what layers are inside the gdb first
layers <- st_layers("data/raw/AADT_2023.gdb")
print(layers)

# Then read the roads layer by name
roads <- st_read("data/raw/AADT_2023.gdb", layer = "AADT_2023")%>%
  st_transform(6539)

# Print column names
names(roads)

roads <- roads %>%
  select(AADT_Stats_2023_Table_Longitude, AADT_Stats_2023_Table_Latitude, AADT_Stats_2023_Table_AADT,
         Traffic_Station_Locations_Speed,AADT_Stats_2023_Table_Functional_Class)

bus_routes <- st_read("data/raw/BUs routes shapefile/bus_routes_nyc_dec2019.shp")%>%
  st_transform(6539)

bus_routes <- bus_routes %>%
  select(geometry)

pop <- read_csv("data/raw/ACSDT5Y2024.B01003_2026-04-09T005055/ACSDT5Y2024.B01003-Data.csv",
                skip = 1)

pop_clean <- pop %>%
  select(
    GEO_ID = Geography,
    NAME = `Geographic Area Name`,
    population = `Estimate!!Total`
  ) %>%
  mutate(
    tract_id = str_replace(GEO_ID, "1400000US", ""),
    population = as.numeric(population)
  )

tracts <- st_read("data/raw/tl_2022_36_tract/tl_2022_36_tract.shp") %>%
  st_transform(6539)

tracts <- tracts %>%
  mutate(tract_id = as.character(GEOID)) %>%
  left_join(pop_clean, by = "tract_id")

ev <- read_csv("data/raw/alt_fuel_stations (Apr 9 2026).csv")

ev_sf <- st_as_sf(ev,
                  coords = c("Longitude", "Latitude"),
                  crs = 4326
) %>%
  st_transform(6539)

# 460V transformers
tx460 <- read_csv(
  "data/raw/460v Transformers - Summer Capacity.csv",
  show_col_types = FALSE
) %>%
  filter(!is.na(x), !is.na(y)) %>%
  mutate(source_kv = "460v")

tx460_sf <- st_as_sf(
  tx460,
  coords = c("x", "y"),
  crs = 6539,
  remove = FALSE
)

# 208V transformers
tx208 <- read_csv(
  "data/raw/208v Transformers - Summer Capacity.csv",
  show_col_types = FALSE
) %>%
  filter(!is.na(x), !is.na(y)) %>%
  mutate(source_kv = "208v")

tx208_sf <- st_as_sf(
  tx208,
  coords = c("x", "y"),
  crs = 6539,
  remove = FALSE
)

# combine both
transformers_sf <- dplyr::bind_rows(tx460_sf, tx208_sf) %>%
  st_transform(6539)

# save
st_write(
  transformers_sf,
  "data/processed/transformers.gpkg",
  delete_dsn = TRUE,
  quiet = TRUE
)

st_write(cdta, "data/processed/cdta.gpkg", delete_dsn = TRUE)
st_write(roads, "data/processed/roads.gpkg", delete_dsn = TRUE)
st_write(tracts, "data/processed/tracts.gpkg", delete_dsn = TRUE)
st_write(ev_sf, "data/processed/ev.gpkg", delete_dsn = TRUE)