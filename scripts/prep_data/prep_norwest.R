# -----------------------
# Author: Mike Ackerman
# Purpose: A brief script to prep the 200m linear network layer for the Columbia River basin which
#   contains various GAAs, habitat attributes, and recent, 2040, and 2080 NorWeST temperature predictions
#   joined to it.
#
# Created: December 19, 2024
#   Last Modified: October 31, 2025
#
# Notes:

# clear environment
rm(list = ls())

# load packages
library(tidyverse)
library(sf)
library(here)

# set default crs for project
default_crs = st_crs(32611) # WGS 84, UTM zone 11N

#--------------------
# load and prep data
load("D:/NAS/data/qrf/gitrepo_data/input/rch_200.rda")

# ictrt population polygons
load(here("data/spatial/SR_pops.rda")) ; rm(fall_pop, spsm_pop)
sthd_pops = sth_pop %>%
  st_transform(default_crs) ; rm(sth_pop)

# trim the 200m reach layer
srb_rch_sf = rch_200 %>%
  # transform to WGS 84, UTM zone 11
  st_transform(default_crs) %>%
  # trim the data to the extent of snake river steelhead populations
  st_intersection(sthd_pops %>%
                    st_union() %>%
                    nngeo::st_remove_holes())

# plot the data
ggplot() +
  geom_sf(data = srb_rch_sf %>%
            filter(S2_02_11 != -9999.00),
          aes(color = S2_02_11),
          size = 1) +
  scale_color_gradient(low = "deepskyblue", high = "red") +
  theme_minimal() +
  labs(color = "S2_02_11")

# save prepped data
save(srb_rch_sf,
     file = "output/prepped_snake_200m_rch_norwest.rda")

### END SCRIPT
