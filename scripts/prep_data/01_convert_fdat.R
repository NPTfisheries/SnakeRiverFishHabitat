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

# path to fdat files
chnk_path = "D:/NAS/data/FDAT/FDAT_Phase2_Chinook_FinalShapefiles&Metadata/Chinook/"
sthd_path = "D:/NAS/data/FDAT/FDAT_Phase2_Steelhead_FinalShapefiles&Metadata/Steelhead/"

#----------
# Chinook

# emipirical observation points
fdat_chnk_obs_pts = st_read(paste0(chnk_path, "FDAT_Phase2_Chinook_ObservationPoints.shp"))
save(fdat_chnk_obs_pts, file = here("output/fdat_chnk_obs_pts.rda"))

# prediction points
fdat_chnk_pred_pts = st_read(paste0(chnk_path, "FDAT_Phase2_Chinook_PredictionPoints_DensityResults.shp"))
save(fdat_chnk_pred_pts, file = here("output/fdat_chnk_pred_pts.rda"))  

# prediction stream segments
fdat_chnk_pred_ss = st_read(paste0(chnk_path, "FDAT_Phase2_Chinook_StreamSegmentScenarios_DensityResults.shp"))
save(fdat_chnk_pred_ss, file = here("output/fdat_chnk_pred_ss.rda"))  

#----------
# Steelhead

# emipirical observation points
fdat_sthd_obs_pts = st_read(paste0(sthd_path, "FDAT_Phase2_Steelhead_ObservationPoints.shp"))
save(fdat_sthd_obs_pts, file = here("output/fdat_sthd_obs_pts.rda"))

# prediction points
fdat_sthd_pred_pts = st_read(paste0(sthd_path, "FDAT_Phase2_Steelhead_PredictionPoints_DensityResults.shp"))
save(fdat_sthd_pred_pts, file = here("output/fdat_sthd_pred_pts.rda"))  

# prediction stream segments
fdat_sthd_pred_ss = st_read(paste0(sthd_path, "FDAT_Phase2_Steelhead_StreamSegmentScenarios_DensityResults.shp"))
save(fdat_sthd_pred_ss, file = here("output/fdat_sthd_pred_ss.rda"))  

### END SCRIPT
