# -----------------------
# Author: Mike Ackerman
# Purpose: Read and prep the quantile random forest - redd dataset for analysis.
# 
# Created: July 23, 2025
#   Last Modified: August 7, 2025
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
load(here("data/spatial/SR_pops.rda")) ; rm(fall_pop, spsm_pop)
sthd_pops = sth_pop %>%
  st_transform(default_crs) ; rm(sth_pop)

# load original qrf dataset (consider switching to og qrf and programatically fixing sfsr, among other things)
qrf_sf = st_read("D:/NAS/data/qrf/gitrepo_data/output/gpkg/Rch_Cap_RF_No_elev_redds.gpkg") %>%
#qrf_sf = st_read("D:/NAS/data/qrf/gitrepo_data/output/gpkg/Rch_Cap_RF_No_elev_redds_sfsr_fixed.gpkg") %>%
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
  filter(chnk == TRUE | sthd == TRUE) %>%
  # trim to extent of snake river steelhead populations
  st_intersection(sthd_pops %>%
                    st_union() %>%
                    nngeo::st_remove_holes())

# additional updates to species extents and use based on disparate datasets, expert opinion, etc.
extent_use_updates = read_excel(path = here("data/qrf_spatial_extents_updates.xlsx"))

# remaining cleaning and prep
qrf_sf %<>%
  # if chnk or sthd is FALSE (0), change use to NA
  mutate(chnk_use = if_else(chnk == 0, NA_character_, chnk_use),
         sthd_use = if_else(sthd == 0, NA_character_, sthd_use)) %>%
  # if chnk or sthd is TRUE (1) & use is NA, change to "Reconnected, unknown use" (these seem to be primarily restored or reconnected streams)
  mutate(
    chnk_use = case_when(
      chnk == 1 & is.na(chnk_use) ~ "Restored, unknown use",
      TRUE ~ chnk_use
    ),
    sthd_use = case_when(
      sthd == 1 & is.na(sthd_use) ~ "Restored, unknown use",
      TRUE ~ sthd_use
    )
  ) %>%
  # update species extents and uses for records in extent_use_updates
  left_join(extent_use_updates, by = c("unique_id", "gnis_name")) %>%
  mutate(
    chnk = coalesce(chnk_update, chnk),
    chnk_use = coalesce(chnk_use_update, chnk_use),
    sthd = coalesce(sthd_update, sthd),
    sthd_use = coalesce(sthd_use_update, sthd_use)
  ) %>%
  select(-ends_with("_update"), notes)

# save the prepped qrf dataset
save(qrf_sf, file = here("output/prepped_snake_redd_qrf.rda"))
#st_write(qrf_sf, here("output/gpkg/prepped_snake_redd_qrf.gpkg"), layer = "prepped_ip", delete_dsn = T)

### END SCRIPT