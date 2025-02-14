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
#library(readxl)
#library(htmlwidgets)

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

