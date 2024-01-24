
# project area overview map

# R preamble --------------------------------------------------------------

library(here)
library(ggrepel)
library(ggspatial)
library(patchwork)
library(sf)
library(tidyverse)
library(viridis)

# plot defaults -----------------------------------------------------------

theme_set(theme_bw(12))

theme_update(
  axis.text = element_blank(),
  axis.ticks = element_blank(),
  axis.title = element_blank(),
  legend.background = element_blank(),
  legend.key.height = grid::unit(0.5, "cm"),
  legend.spacing = unit(2, "pt"),
  legend.text = element_text(margin = margin()),
  legend.title = element_text(margin = margin()),
  panel.background = element_rect(fill = "skyblue"),
  panel.grid = element_blank(),
  plot.margin = margin()
)

# data --------------------------------------------------------------------

gpkg <- here("data", "choyero.gpkg")

mexico <- read_sf(gpkg, layer = "mexico")

bcs <- read_sf(gpkg, layer = "baja")

window <- read_sf(gpkg, layer = "window")

cities <- read_sf(gpkg, layer = "cities")

roads <- read_sf(gpkg, layer = "roads")

highways <- read_sf(gpkg, layer = "highways")

watersheds <- read_sf(gpkg, layer = "watersheds")

ranches <- read_sf(gpkg, layer = "ranches")

clusters <- read_sf(gpkg, layer = "clusters")

# regional overview -------------------------------------------------------

bb8 <- st_bbox(bcs) + c(-30000, -15000, 60000, 30000)

region <- mexico |> 
  filter(name != "Baja California Sur") |> 
  st_transform(4485) |> 
  st_intersection(st_as_sfc(bb8)) |> 
  st_union()

city_labels <- cities |> 
  st_coordinates() |> 
  as_tibble() |> 
  bind_cols(st_drop_geometry(cities)) |> 
  mutate(name = c("Ciudad Constitucion ", " La Paz"))

overview <- ggplot() +
  geom_sf(
    data = region, 
    fill = "gray95",
    size = 0.3
  ) +
  geom_sf(
    data = bcs, 
    fill = "#A8A076",
    size = 0.3
  ) +
  geom_sf(
    data = highways |> st_buffer(1750) |> st_union(), 
    fill = "white",
    color = "black",
    size = 0.2
  ) +
  geom_sf(
    data = window, 
    fill = alpha("#B80000", 0.45),
    color = "#B80000",
    size = 0.65
  ) + 
  geom_label_repel(
    data = city_labels, 
    aes(X, Y, label = name),
    size = 10/.pt,
    nudge_x = c(-100000, 70000),
    nudge_y = 80000
  ) +
  geom_sf(
    data = cities, 
    shape = 21, 
    fill = "#fffbc9", 
    color = "black",
    size = 3,
    stroke = 0.3
  ) +
  annotation_scale(
    aes(location = "bl"),
    pad_x = unit(0.4, "npc"),
    height = unit(0.25, "cm"),
    text_cex = 0.85
  ) +
  coord_sf(
    crs = 4485, 
    xlim = bb8[c("xmin", "xmax")],
    ylim = bb8[c("ymin", "ymax")],
    expand = FALSE
  )

# local basemap -----------------------------------------------------------

bb8 <- st_bbox(window)

region <- st_crop(bcs, st_as_sfc(bb8))

base <- ggplot() +
  geom_sf(
    data = region, 
    fill = "#A8A076",
    size = 0.3
  ) +
  geom_sf(
    data = watersheds,
    fill = alpha("gray95", alpha = 0.5), 
    color = "gray50",
    size = 0.3
  ) +
  geom_sf(
    data = roads |> filter(level != "T"),
    color = "white",
    linewidth = 0.1
  )

# population map ----------------------------------------------------------

population <- base +
  geom_sf(
    data = clusters |> 
      mutate(
        population = cut(
          population, 
          breaks = c(-Inf, 0, 10, 20, 30, Inf), 
          labels = c("0", "1-10", "11-20", "21-30", "31+")
        )),
    aes(fill = population, size = population),
    shape = 21
  ) +
  scale_fill_viridis(
    name = "Population (A)",
    option = "magma",
    discrete = TRUE,
    alpha = 0.8
  ) +
  scale_size_manual(
    name = "Population (A)",
    values = seq(1, 4.5, length.out = 5)
  ) +
  annotate(
    "text",
    x = bb8[["xmin"]] + 1000,
    y = bb8[["ymax"]] - 1300,
    label = "A",
    size = 18/.pt,
    hjust = 0,
    vjust = 1
  ) +
  annotation_scale(
    aes(location = "tl", width_hint = 0.15),
    pad_x = grid::unit(0.9, "cm"),
    pad_y = grid::unit(0.4, "cm"),
    height = grid::unit(0.25, "cm"),
    text_cex = 0.85
  ) +
  coord_sf(crs = 4485, expand = FALSE)

# land security -----------------------------------------------------------

set.seed(123)
jittered_ranches <- ranches |> st_jitter()

land <- base +
  geom_sf(
    data = jittered_ranches |> filter(population > 0),
    aes(fill = land, shape = land),
    size = 2.5
  ) +
  scale_fill_manual(
    name = "Land Status (B)",
    values = c("#F24C00", "#00B6F2")
  ) +
  scale_shape_manual(
    name = "Land Status (B)",
    values = 22:21,
    na.value = 16
  ) +
  annotate(
    "text",
    x = bb8[["xmin"]] + 1000,
    y = bb8[["ymax"]] - 1300,
    label = "B",
    size = 18/.pt,
    hjust = 0,
    vjust = 1
  ) +
  coord_sf(crs = 4485, expand = FALSE)

# collect and save --------------------------------------------------------

population + overview + land + guide_area() + plot_layout(guides = 'collect')

ggsave(
  here("figures", "overview-map.png"),
  dpi = 800,
  width = 5.75,
  height = 5.75
)
