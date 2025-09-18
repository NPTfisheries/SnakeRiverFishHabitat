# -----------------------
# Author: Mike Ackerman
# Purpose: Read and prep the quantile random forest - juvenile summer rearing dataset for analysis.
# 
# Created: September 18, 2025
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
library(readxl)

# set default crs
default_crs = st_crs(32611) # WGS 84, UTM zone 11N

# ictrt population polygons
load(here("data/spatial/SR_pops.rda")) ; rm(fall_pop)
sthd_pops = sth_pop %>%
  st_transform(default_crs) ; rm(sth_pop)

# load original qrf juvenile summer rearing dataset
qrf_juv_sum_sf = st_read("D:/NAS/data/qrf/gitrepo_data/output/gpkg/Rch_Cap_RF_No_elev_juv_summer.gpkg") %>%
  clean_names() %>%
  st_transform(default_crs) %>%
  select(unique_id,
         gnis_name,
         reach_leng_m = reach_leng,
         chnk,
         chnk_use,
         sthd,
         sthd_use,
         chnk_per_m,
         chnk_per_m_se,
         sthd_per_m,
         sthd_per_m_se) %>%
  # trim to only reaches used by either sp/sum chinook or steelhead (according to StreamNet)
  #filter(chnk == TRUE | sthd == TRUE) %>%
  # trim to extent of snake river steelhead populations
  st_intersection(sthd_pops %>%
                    st_union() %>%
                    nngeo::st_remove_holes())
  
# NOTE: Consider some updates to species extents and use and additional cleaning and prep, similar to what is done in prep_redd_qrf.R 

# save the prepped qrf dataset
save(qrf_juv_sum_sf, file = here("output/prepped_snake_juv_sum_qrf.rda"))
#st_write(qrf_juv_sum_sf, here("output/gpkg/prepped_snake_juv_sum_qrf.gpkg"), layer = "juv_sum_qrf", delete_dsn = T)

### END SCRIPT