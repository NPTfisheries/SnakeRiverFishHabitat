# -----------------------
# Author: Mike Ackerman
# Purpose: Read in the FDAT datasets from an external drive and save to .rda files.
# 
# Created: July 23, 2025
#   Last Modified:
# 
# Notes:

# clear environment
rm(list = ls())

# load packages
library(sf)
library(here)
library(magrittr)

fdat_chnk_obs_pts = "D:/NAS/data/FDAT/FDAT_Phase2_Chinook_FinalShapefiles&Metadata/Chinook/FDAT_Phase2_Chinook_ObservationPoints.shp" %>%
  st_read() %T>%
  { save(., file = here("output/fdat_chnk_obs_pts.rda")) }

load(here("output/fdat_chnk_obs_pts.rda"))

fdat_chnk_obs_pts = st_read("D:/NAS/data/FDAT/FDAT_Phase2_Chinook_FinalShapefiles&Metadata/Chinook/FDAT_Phase2_Chinook_ObservationPoints.shp") %>%
  save(file = here("output/fdat_chnk_obs_pts.rda"))
