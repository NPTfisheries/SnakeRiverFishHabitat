# -----------------------
# Author: Mike Ackerman
# Purpose: Compare two prepped QRF datasets to identify where chnk & chnk_use differ
# 
# Created: August 7, 2025
#   Last Modified:
# 
# Notes:

# clear environment
rm(list = ls())

# load packages
library(tidyverse)
library(sf)
library(here)
library(writexl)

# load the redd qrf dataset where some spatial extents were modified in the south for salmon river, and rename it
load(here("output/prepped_snake_redd_qrf_sfsr_fixed.rda"))
qrf_sf_sfsr_fixed = get("qrf_sf") ; rm(qrf_sf)

# load the redd qrf dataset w/ original spatial extents
load(here("output/prepped_snake_redd_qrf.rda"))

# identify records where sthd and sthd_use differ (no differences)
# diffs_sthd = qrf_sf %>%
#   st_drop_geometry() %>%
#   select(unique_id, gnis_name, sthd, sthd_use) %>%
#   rename(sthd_og = sthd, sthd_use_og = sthd_use) %>%
#   left_join(
#     qrf_sf_sfsr_fixed %>%
#       st_drop_geometry() %>%
#       select(unique_id, sthd, sthd_use) %>%
#       rename(sthd_fixed = sthd, sthd_use_fixed = sthd_use),
#     by = "unique_id"
#   ) %>%
#   filter(sthd_og != sthd_fixed | sthd_use_og != sthd_use_fixed)

# identify records where chnk and chnk_use differ
diffs_chnk = qrf_sf %>%
  st_drop_geometry() %>%
  select(unique_id, gnis_name, chnk, chnk_use) %>%
  rename(chnk_og = chnk, chnk_use_og = chnk_use) %>%
  left_join(
    qrf_sf_sfsr_fixed %>%
      st_drop_geometry() %>%
      select(unique_id, chnk, chnk_use) %>%
      rename(chnk_update = chnk, chnk_use_update = chnk_use),
    by = "unique_id"
  ) %>%
  filter(chnk_og != chnk_update | chnk_use_og != chnk_use_update) %>%
  select(-chnk_og, -chnk_use_og) %>%
  mutate(sthd_update = "NA",
         sthd_use_update = "NA")

# write out to a .xlsx file for further editing
write_xlsx(diffs_chnk,
           path = here("data/qrf_spatial_extents_updates.xlsx"))

### END SCRIPT

