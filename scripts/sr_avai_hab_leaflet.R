# Author: Mike Ackerman
# Purpose: Create leaflet map to view Snake River available habitat datasets (e.g., IP & QRF) 
#   along with TRT population boundaries.
# 
# Created: February 14, 2025
#   Last Modified: February 19, 2025
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
library(magrittr)

# set default crs
default_crs = st_crs(4326)

# -----------------------
# compile data
# populations
load(here("data/spatial/SR_pops.rda")) ; rm(fall_pop)
sthd_pops = sth_pop %>%
  select(TRT_POPID, POP_NAME, MPG) %>%
  st_transform(default_crs); rm(sth_pop)
chnk_pops = spsm_pop %>%
  select(TRT_POPID, POP_NAME, MPG) %>%
  st_transform(default_crs); rm(spsm_pop)

# major/minor spawning areas
sthd_spawn = load(here("data/spatial/steelhead_gis_data.rda")) %>%
  {sthd_spawn %>% st_transform(default_crs)} ; rm(sthd_critical, sthd_extant, sthd_ip, sthd_huc)
chnk_spawn = readRDS(here("data/spatial/spsm_spwn_areas.rds")) %>%
  st_transform(default_crs)

# prepped intrinsic potential and redd qrf datasets
load(file = here("data/spatial/prepped_snake_ip.rda"))
ip_sf %<>% st_transform(default_crs)
qrf_sf = get(load(file = here("data/spatial/snake_redd_qrf.rda"))) %>% st_transform(default_crs)

# prep sthd ip
sthd_ip_sf = ip_sf %>%
  # filter to steelhead spatial extent
  mutate(currsthd = if_else(currsthd > 0, TRUE, FALSE)) %>%
  filter(currsthd == TRUE) %>%
  # one more filter to remove stream reaches with ip of "none"
  filter(!sthdrate == 0) %>%
  mutate(ip_class = case_when(
    sthdrate == 3 ~ "High",
    sthdrate == 2 ~ "Med",
    sthdrate == 1 ~ "Low",
    TRUE ~ NA_character_
  )) %>%
  mutate(ip_class = factor(ip_class, levels = c("High", "Med", "Low"))) %>%
  select(ip_class)

# prep chnk ip
chnk_ip_sf = ip_sf %>%
  # filter to steelhead spatial extent
  mutate(currchnk = if_else(currchnk > 0, TRUE, FALSE)) %>%
  filter(currchnk == TRUE) %>%
  # one more filter to remove stream reaches with ip of "none"
  filter(!chinrate == 0) %>%
  mutate(ip_class = case_when(
    chinrate == 3 ~ "High",
    chinrate == 2 ~ "Med",
    chinrate == 1 ~ "Low",
    TRUE ~ NA_character_
  )) %>%
  mutate(ip_class = factor(ip_class, levels = c("High", "Med", "Low"))) %>%
  select(ip_class)

# prep sthd qrf
sthd_qrf_sf = qrf_sf %>%
  filter(sthd == TRUE,
         sthd_use == "Spawning and rearing") %>%
  mutate(redds_per_km = sthd_per_m * 1000) %>%
  mutate(redds_bin = cut(redds_per_km, breaks = c(0, 2, 4, 6, 8, Inf), 
                         labels = c("0-2", "2-4", "4-6", "6-8", "8+"), 
                         right = FALSE)) %>%
  select(redds_per_km, redds_bin)

# prep chnk qrf
chnk_qrf_sf = qrf_sf %>%
  filter(chnk == TRUE,
         chnk_use == "Spawning and rearing") %>%
  mutate(redds_per_km = chnk_per_m * 1000) %>%
  mutate(redds_bin = cut(redds_per_km, breaks = c(0, 2, 4, 6, 8, Inf), 
                         labels = c("0-2", "2-4", "4-6", "6-8", "8+"), 
                         right = FALSE)) %>%
  select(redds_per_km, redds_bin)

# -----------------------
# set some colors
sthd_mpg_col = colorFactor(palette = "Dark2", domain = sthd_pops$MPG)
sthd_spawn_col = colorFactor(palette = c("skyblue", "navy"), domain = sthd_spawn$TYPE, reverse = TRUE)
chnk_mpg_col = colorFactor(palette = "Set1", domain = chnk_pops$MPG)
chnk_spawn_col = colorFactor(palette = c("springgreen", "darkgreen"), domain = chnk_spawn$TYPE, reverse = TRUE)
ip_col = colorFactor(palette = c("#E3F2FD", "#64B5F6", "#0D47A1"), 
                     domain = sthd_ip_sf$ip_class,
                     levels = c("Low", "Med", "High"))
qrf_col = colorFactor(palette = c("white", "lightpink", "salmon", "firebrick", "darkred"),
                      domain = sthd_ip_sf$ip_class,
                      levels = c("0-2", "2-4", "4-6", "6-8", "8+"))

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
  addLegend(group = "Steelhead Populations",
            position = "bottomleft",
            pal = sthd_mpg_col,
            values = sthd_pops$MPG,
            title = "Steelhead MPGs",
            opacity = 0.2) %>%
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
  addLegend(group = "Sp/Sum Chinook Populations",
            position = "bottomleft",
            pal = chnk_mpg_col,
            values = chnk_pops$MPG,
            title = "Sp/Sum Chinook MPGs",
            opacity = 0.2) %>%
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
  # steelhead intrinsic potential
  addPolylines(data = sthd_ip_sf,
               group = "Steelhead IP",
               color = ~ip_col(ip_class),
               weight = 2,
               opacity = 1,
               label = ~paste0("IP Class: ", ip_class)) %>%
  addLegend(group = "Steelhead IP",
            position = "topleft",
            pal = ip_col,
            values = factor(c("High", "Med", "Low"), levels = c("High", "Med", "Low")),
            title = "Intrinsic Potential",
            opacity = 1) %>%
  # chinook intrinsic potential
  addPolylines(data = chnk_ip_sf,
               group = "Sp/Sum Chinook IP",
               color = ~ip_col(ip_class),
               weight = 2,
               opacity = 1,
               label = ~paste0("IP Class: ", ip_class)) %>%
  addLegend(group = "Sp/Sum Chinook IP",
            position = "topleft",
            pal = ip_col,
            values = factor(c("High", "Med", "Low"), levels = c("High", "Med", "Low")),
            title = "Intrinsic Potential",
            opacity = 1) %>%
  # steelhead qrf redd capacity
  addPolylines(data = sthd_qrf_sf,
               group = "Steelhead QRF Redd Capacity",
               color = ~qrf_col(redds_bin),
               weight = 2,
               opacity = 1) %>%
  addLegend(group = "Steelhead QRF Redd Capacity",
            position = "topleft",
            pal = qrf_col,
            values = factor(c("8+", "6-8", "4-6", "2-4", "0-2"), levels = c("8+", "6-8", "4-6", "2-4", "0-2")),
            title = "Capacity (redds/km)",
            opacity = 1) %>%
  # chinook qrf redd capacity
  addPolylines(data = chnk_qrf_sf,
               group = "Sp/Sum Chinook QRF Redd Capacity",
               color = ~qrf_col(redds_bin),
               weight = 2,
               opacity = 1) %>%
  addLegend(group = "Sp/Sum Chinook QRF Redd Capacity",
            position = "topleft",
            pal = qrf_col,
            values = factor(c("8+", "6-8", "4-6", "2-4", "0-2"), levels = c("8+", "6-8", "4-6", "2-4", "0-2")),
            title = "Capacity (redds/km)",
            opacity = 1) %>%
  addLayersControl(baseGroups = c("Steelhead Populations",
                                  "Steelhead Spawning Areas",
                                  "Sp/Sum Chinook Populations",
                                  "Sp/Sum Chinook Spawning Areas"),
                   overlayGroups = c("Steelhead IP",
                                     "Sp/Sum Chinook IP",
                                     "Steelhead QRF Redd Capacity",
                                     "Sp/Sum Chinook QRF Redd Capacity"),
                   options = layersControlOptions(collapsed = FALSE)) %>%
  hideGroup("Sp/Sum Chinook IP") %>%
  hideGroup("Steelhead QRF Redd Capacity") %>%
  hideGroup("Sp/Sum Chinook QRF Redd Capacity")

sr_hab_leaflet

# save leaflet
saveWidget(sr_hab_leaflet, file = here("shiny/leaflet/sr_available_habitat_leaflet.html"))

### END SCRIPT  
  
