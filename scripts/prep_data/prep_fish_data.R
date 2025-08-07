# -----------------------
# Author: Mike Ackerman
# Purpose: Prep various raw fish (e.g., redd survey) datasets for further use.
# 
# Created: August 7, 2025
#   Last Modified: 
# 
# Notes:

# clear environment
rm(list = ls())

# load necessary packages
library(here)
library(tidyverse)
library(sf)
library(janitor)

# idfg sp/sum chnk spatial redd data
ifwis_chnk_redd_sf = read_csv(file = here("data/ifwis_redd_detail_export_20250807.csv"), show_col_types = F) %>%
  clean_names() %>%
  filter(!is.na(latitude) & !is.na(longitude)) %>%
  # remove some earlier years where there was less effort
  filter(survey_year >= 2000) %>%
  # focus on chinook, limited data for other species
  filter(species == "SP/SU Chinook") %>%
  select(waypoint_id,
         waterbody,
         trt_pop,
         trt_mpg,
         survey_id,
         transect_id,
         survey_year,
         start_date,
         species,
         sample_method,
         drainage,
         agency,
         collector,
         longitude,
         latitude) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# write to .gpkg
st_write(ifwis_chnk_redd_sf, here("output/gpkg/ifwis_chnk_redd_export_20250807.gpkg"), layer = "redd_pts", delete_layer = T)

### END SCRIPT
