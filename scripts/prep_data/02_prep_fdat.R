# -----------------------
# Author: Mike Ackerman
# Purpose: Read and prep the Fish Data Analysis Tool (FDAT) dataset for analysis.
# 
# Created: July 24, 2025
#   Last Modified:
# 
# Notes:

# clear environment
rm(list = ls())

# load packages
library(tidyverse)
library(janitor)
library(sf)
library(here)

# set default crs
default_crs = st_crs(32611) # WGS 84, UTM zone 11N

# ictrt population polygons
load(here("data/spatial/SR_pops.rda")) ; rm(fall_pop, spsm_pop)
sthd_pops = sth_pop %>%
  st_transform(default_crs) ; rm(sth_pop)

# load chinook observation points dataset
load(here("data/spatial/FDAT/fdat_chnk_obs_pts.rda")) 
fdat_chnk_obs_pts %<>%
  clean_names() %>%
  st_transform(default_crs) %>%
  select(gnis_name,
         site_id,
         year,
         ch_density,
         comid,
         source,
         ch_pop,
         point_x,
         point_y) %>%
  # trim to snake river basin (includes some pts in John Day River)
  st_intersection(sthd_pops %>%
                    st_union() %>%
                    nngeo::st_remove_holes())
  
# save to file
save(fdat_chnk_obs_pts, file = here("output/prepped_fdat_chnk_obs_pts.rda"))
#st_write(fdat_chnk_obs_pts, here("output/prepped_fdat_chnk_obs_pts.gpkg"), layer = "prepped_ip", delete_dsn = T)

# load chinook prediction points dataset
load(here("data/spatial/FDAT/fdat_chnk_pred_pts.rda"))
fdat_chnk_pred_pts %<>%
  clean_names() %>%
  st_transform(default_crs) %>%
  select(gnis_name,
         comid,
         ch_pop,
         s1_00_18:s24_3c) %>%
  # trim to snake river basin (includes some pts in John Day River)
  st_intersection(sthd_pops %>%
                    st_union() %>%
                    nngeo::st_remove_holes())

# save to file
save(fdat_chnk_pred_pts, file = here("output/prepped_fdat_chnk_pred_pts.rda"))
#st_write(fdat_chnk_pred_pts, here("output/prepped_fdat_chnk_pred_pts.gpkg"), layer = "prepped_ip", delete_dsn = T)

# load chinook prediction stream segments dataset
load(here("data/spatial/FDAT/fdat_chnk_pred_ss.rda"))
fdat_chnk_pred_ss %<>%
  clean_names() %>%
  st_transform(default_crs) %>%
  # trim to snake river basin (includes some pts in John Day River)
  st_intersection(sthd_pops %>%
                    st_union() %>%
                    nngeo::st_remove_holes())

# save to file
save(fdat_chnk_pred_ss, file = here("output/prepped_fdat_chnk_pred_ss.rda"))
#st_write(fdat_chnk_pred_ss, here("output/prepped_fdat_chnk_pred_ss.gpkg"), layer = "prepped_ip", delete_dsn = T)

fdat_chnk_pred_ss %>%
  ggplot() +
  geom_sf(data = sthd_pops, fill = "lightgray", color = "black") +
  geom_sf(aes(color = s1_00_18), size = 2) +
  theme_minimal() +
  labs(color = "Pred CH Density (juv/100m)")

### END SCRIPT
