# Author: Mike Ackerman
# Purpose: Create leaflet map to view Snake River available habitat datasets (e.g., IP & QRF) 
#   along with TRT population boundaries.
# 
# Created: February 14, 2025
#   Last Modified:
# 
# Notes:
#

# clear environment
rm(list = ls())

# load packages
library(tidyverse)
library(here)
library(sf)
library(leaflet)
library(htmlwidgets)
#library(readxl)

# -----------------------
# compile data
# populations
load(here("data/spatial/SR_pops.rda")) ; rm(fall_pop)
sthd_pops = sth_pop %>%
  select(TRT_POPID, POP_NAME, MPG) ; rm(sth_pop)
chnk_pops = spsm_pop %>%
  select(TRT_POPID, POP_NAME, MPG) ; rm(spsm_pop)

# major/minor spawning areas
sthd_spawn = load(here("data/spatial/steelhead_gis_data.rda")) %>%
  {sthd_spawn %>% st_transform("EPSG:4326")} ; rm(sthd_critical, sthd_extant, sthd_ip, sthd_huc)
chnk_spawn = readRDS(here("data/spatial/spsm_spwn_areas.rds")) %>%
  st_transform("EPSG:4326")

# prepped intrinsic potential and redd qrf datasets
load(file = here("data/spatial/prepped_snake_ip.rda"))
qrf_sf = get(load(file = here("data/spatial/snake_redd_qrf.rda")))

# -----------------------
# set some colors
sthd_mpg_col = colorFactor(palette = "Dark2", domain = sthd_pops$MPG)
sthd_spawn_col = colorFactor(palette = c("skyblue", "navy"), domain = sthd_spawn$TYPE, reverse = TRUE)
chnk_mpg_col = colorFactor(palette = "Set1", domain = chnk_pops$MPG)
chnk_spawn_col = colorFactor(palette = c("springgreen", "darkgreen"), domain = chnk_spawn$TYPE, reverse = TRUE)

# -----------------------
# build leaflet
base = leaflet() %>%
  # base map
  setView(lng = -116, lat = 45.35, zoom = 7.5) %>%
  addProviderTiles(providers$Esri.WorldTopoMap)

sr_hab_leaflet = base %>%
  # steelhead populations
  addPolygons(data = sthd_pops,
              group = "Steelhead Populations",
              fillColor = ~sthd_mpg_col(MPG),
              fillOpacity = 0.2,
              stroke = T,
              weight = 2,
              color = "black",
              opacity = 1,
              label = ~paste0(TRT_POPID, ": ", POP_NAME),
              popup = paste("<b>Steelhead</b></br>",
                            "<b>Pop ID:</b>", sthd_pops$TRT_POPID, "</br>",
                            "<b>Pop Name:</b>", sthd_pops$POP_NAME, "</br>",
                            "<b>MPG:</b>", sthd_pops$MPG, "</br>")) %>%
  # steelhead major/minor spawning areas
  addPolygons(data = sthd_spawn,
              group = "Steelhead Spawning Areas",
              fillColor = ~sthd_spawn_col(TYPE),
              fillOpacity = 0.2,
              stroke = T,
              weight = 1,
              color = "black",
              opacity = 1,
              label = ~paste0(POP_NAME, ": ", MSA_NAME, ", ", TYPE)) %>%
  # chinook salmon populations
  addPolygons(data = chnk_pops,
              group = "Sp/Sum Chinook Populations",
              fillColor = ~chnk_mpg_col(MPG),
              fillOpacity = 0.2,
              stroke = T,
              weight = 2,
              color = "black",
              opacity = 1,
              label = ~paste0(TRT_POPID, ": ", POP_NAME),
              popup = paste("<b>sp/sum Chinook salmon</b></br>",
                            "<b>Pop ID:</b>", chnk_pops$TRT_POPID, "</br>",
                            "<b>Pop Name:</b>", chnk_pops$POP_NAME, "</br>",
                            "<b>MPG:</b>", chnk_pops$MPG, "</br>")) %>%
  # chinook major/minor spawning areas
  addPolygons(data = chnk_spawn,
              group = "Sp/Sum Chinook Spawning Areas",
              fillColor = ~chnk_spawn_col(TYPE),
              fillOpacity = 0.2,
              stroke = T,
              weight = 1,
              color = "black",
              opacity = 1,
              label = ~paste0(POP_NAME, ": ", MSA_NAME, ", ", TYPE)) %>%
  addLayersControl(baseGroups = c("Steelhead Populations",
                                  "Steelhead Spawning Areas",
                                  "Sp/Sum Chinook Populations",
                                  "Sp/Sum Chinook Spawning Areas"),
                   options = layersControlOptions(collapsed = FALSE))

sr_hab_leaflet

# save leaflet
saveWidget(sr_hab_leaflet, file = here("shiny/leaflet/sr_available_habitat_leaflet.html"))

### END SCRIPT  
  
