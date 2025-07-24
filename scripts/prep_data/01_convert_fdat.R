# -----------------------
# Author: Mike Ackerman
# Purpose: Read in the FDAT datasets from an external drive and save to .rda files.
# 
# Created: July 23, 2025
#   Last Modified: July 24, 2025
# 
# Notes:

# clear environment
rm(list = ls())

# load packages
library(sf)
library(here)
library(magrittr)

# define base paths to fdat files, by species
paths = list(chnk = "D:/NAS/data/FDAT/FDAT_Phase2_Chinook_FinalShapefiles&Metadata/Chinook/",
             sthd = "D:/NAS/data/FDAT/FDAT_Phase2_Steelhead_FinalShapefiles&Metadata/Steelhead/")

# define shapefile names and object/output names
files = list(obs_pts  = "ObservationPoints.shp",
             pred_pts = "PredictionPoints_DensityResults.shp",
             pred_ss  = "StreamSegmentScenarios_DensityResults.shp")

# read and save each file
for (spc in names(paths)) {
  for (key in names(files)) {
    shp_file = paste0("FDAT_Phase2_", ifelse(spc == "chnk", "Chinook", "Steelhead"), "_", files[[key]])
    obj_name = paste0("fdat_", spc, "_", key)
    file_path = file.path(paths[[spc]], shp_file)
    assign(obj_name, st_read(file_path))
    save(list = obj_name, file = here::here("data/spatial/FDAT/", paste0(obj_name, ".rda")))
  }
}

### END SCRIPT
