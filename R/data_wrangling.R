
# Baja Ranching -- Data Wrangling

##############################.
#     CONTENTS
# 01. Preamble
# 02. Baja Califonia Sur
# 03. Ranches
# 04. Project Window
# 05. Watersheds
# 06. Springs
# 07. Roads
# 08. Digital Elevation Model (DEM)
# 09. Cities
##############################.

# 01) PREAMBLE ------------------------------------------------------------

# Load libraries
library(dplyr)
library(FedData)
library(rgeoboundaries)
library(here)
library(lwgeom)
library(osmdata)
library(readr)
library(sf)
library(terra)

gpkg <- here("data", "choyero.gpkg")

# coordinate reference system
# epsg: 4485 (Mexico ITRF92 / UTM zone 12N)
# see https://epsg.io/4485

# 02) BAJA CALIFORNIA SUR --------------------------------------------------

mexico <- geoboundaries("mexico", "adm1") |> 
  select(shapeName, shapeISO) |> 
  rename_with(gsub, pattern = "shape", replacement = "") |> 
  rename_with(tolower) |> 
  st_transform(4485)

bcs <- mexico |> filter(name == "Baja California Sur")

write_sf(
  mexico,
  dsn = gpkg,
  layer = "mexico"
)

write_sf(
  bcs,
  dsn = gpkg,
  layer = "baja"
)

# 03) RANCHES -------------------------------------------------------------

ranches <- here("data", "ranches.csv") |> 
  read_csv() |>
  # one ranch is missing coordinates
  filter(!is.na(lat) | !is.na(long)) |> 
  select(id, ranch, cluster, community, occupied, population, land, notes, lat, long) |> 
  mutate(
    community = case_when(
      community == ''      ~ "Abandoned",
      community == 'LH'    ~ "La Higuera",
      community == 'LS'    ~ "La Soledad",
      community == 'SMDT'  ~ "Santa Maria de Toris",
      community == 'SPDLP' ~ "San Pedro de la Presa",
      TRUE                 ~ community
    )
  ) |>
  st_as_sf(coords = c("long", "lat"), crs = 4326) |>
  st_transform(4485)

# clusters are defined as the center point of its ranches
clusters <- ranches |> 
  group_by(cluster) |> 
  summarize(
    occupied = ifelse(sum(occupied) > 0, 1, 0),
    population = sum(population)
  ) |> 
  st_centroid()

write_sf(
  ranches,
  dsn = gpkg,
  layer = "ranches"
)

write_sf(
  clusters,
  dsn = gpkg,
  layer = "clusters"
)

# 04) PROJECT WINDOW ------------------------------------------------------

window <-
  ranches |>
  st_buffer(2000) |>
  st_bbox() |>
  st_as_sfc() |>
  st_as_sf() |>
  st_intersection(bcs) |>
  rename("geometry" = x) |>
  select(geometry)

write_sf(
  window,
  dsn = gpkg,
  layer = "window"
)

# 05) WATERSHEDS ----------------------------------------------------------

watersheds <- here("data", "watersheds.geojson") |> 
  read_sf() |>
  select(COV_ID, TOPONIMO) |>
  rename(
    "id" = COV_ID,
    "name" = TOPONIMO
  )

watersheds <- watersheds |>
  st_transform(4485) |>
  st_crop(window) |> 
  # cast everything to MULTIPOLYGON first, so it doesn't drop POLYGONs
  st_cast("MULTIPOLYGON") |> 
  st_cast("POLYGON")

write_sf(
  watersheds,
  dsn = gpkg,
  layer = "watersheds"
)

# 06) SPRINGS -------------------------------------------------------------

springs <- here("data", "springs.csv") |> 
  read_csv() |>
  st_as_sf(coords = c("Long", "Lat"), crs = 4326) |>
  st_transform(4485)

write_sf(
  springs,
  dsn = gpkg,
  layer = "springs"
)

# 07) ROADS ---------------------------------------------------------------

# these were digitized using Google Earth
roads <- here("data", "roads.geojson") |> 
  read_sf() |>
  st_transform(4485) |>
  st_intersection(watersheds)

write_sf(
  roads,
  dsn = gpkg,
  layer = "roads"
)

# data model is a little complicated, so had to do some finagling
highways <- opq(bbox = "Baja California Sur, Mexico") |>
  add_osm_feature(
    key = "highway",
    value = c(
      "motorway",
      "motorway_link",
      "trunk",
      "trunk_link",
      "tertiary",
      "tertiary_link",
      "unclassified"
    )
  ) |>
  osmdata_sf()

bb8 <- st_bbox(window)
bb8['xmin'] <- 420000
bb8['ymin'] <- 2690000
bb8['ymax'] <- bb8['ymax'] - 5000
bb8 <- bb8 |> st_as_sfc(crs = 4485)

hwy <- highways[["osm_lines"]] |>
  filter(highway == "trunk") |>
  st_transform(4485) |>
  st_intersection(bb8)

bb8 <- lwgeom::st_split(bb8, hwy)[[1]][[2]]

is_in_box <- function(x, y) {
  
  mm <- st_within(x, y)
  
  lengths(mm) > 0
  
}

highways <- highways[["osm_lines"]] |>
  st_transform(4485) |>
  st_intersection(bcs) |>
  select(osm_id, name, highway, maxspeed, paved) |>
  filter(
    highway %in% c("motorway", 
                   "motorway_link", 
                   "trunk", 
                   "trunk_link") | 
      is_in_box(geometry, bb8)
  ) |>
  filter(
    highway %in% c(
      "motorway",
      "motorway_link",
      "trunk",
      "trunk_link",
      "tertiary",
      "tertiary_link"
    )  |
      osm_id %in% c(
        537264247,
        366657331,
        537264246,
        537264223,
        537264240,
        537264226,
        537264227,
        537264225
      )
  ) |>
  st_make_valid()

remove(bb8, hwy, is_in_box)

write_sf(
  highways,
  dsn = gpkg,
  layer = "highways"
)

# 08) DEM -----------------------------------------------------------------

# download DEM raster for study region
# technically 29-m x 29-m resolution
dem <- get_ned(
  window,
  label = "choyero",
  res = "1",
  raw.dir = tempdir(),
  extraction.dir = tempdir()
)

dem <- dem |> 
  rast() |>
  crop(st_transform(window, crs = 4326)) |>
  project("epsg:4485")

dem <- mask(dem, vect(st_union(watersheds)))

names(dem) <- "elevation"

writeRaster(
  dem,
  filename = here("data", "dem_30m.tif"),
  overwrite = TRUE
)

# 09) CITIES --------------------------------------------------------------

# just road endpoints on the way to the cities
terminus <- matrix(
    c(489978.0, 2741725,
      514320.2, 2741725),
    ncol = 2,
    byrow = TRUE
  ) |>
  st_multipoint() |>
  st_sfc(crs = 4485) |>
  st_sf() |>
  st_cast("POINT") |> 
  mutate(name = c("Constitucion", "La Paz"))

write_sf(
  terminus,
  dsn = gpkg,
  layer = "terminus"
)

# for map making, we want the locations of the actual cities
cities <- 
  matrix(
    c(-111.670278, 25.032222,
      -110.310833, 24.142222),
    ncol = 2,
    byrow = TRUE
  ) |>
  st_multipoint() |>
  st_sfc(crs = 4326)

cities <- st_sf(geometry = cities) |>
  st_cast("POINT") |>
  mutate(name = c("Ciudad Constitucion", "La Paz"), .before = "geometry") |>
  st_transform(4485)

write_sf(
  cities,
  dsn = gpkg,
  layer = "cities"
)
