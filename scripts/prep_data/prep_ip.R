# -----------------------
# Author: Mike Ackerman
# Purpose: Read and prep the intrinsic potential dataset for analysis.
# 
# Created: July 23, 2025
#   Last Modified: August 6, 2025
# 
# Notes:

# clear environment
rm(list = ls())

# load packages
library(tidyverse)
library(sf)
library(here)
library(janitor)

# set default crs
default_crs = st_crs(32611) # WGS 84, UTM zone 11N

# prep intrinsic potential layer; already been clipped using snake river steelhead dps
ip_sf = readRDS(here("data/spatial/IP/ip.rds")) %>%
  clean_names() %>%
  st_transform(default_crs) %>%
  # trim down to only useful columns
  select(name,                # Unique segment identifier
         llid,                # water course longitude/latitude identifier number; derived unique water course route identifier from PNW Framework Hydrography (100k scale)
         strmname,            # common name of watercourse from the PNW Framework Hydrography (100k scale)
         length_m = length,   # segment length (m)
         elev_m = elev,       # mean elevation of stream segment (m), calculated from USGS 10m DEM
         wide_ww,             # modeled wetted width of stream (summer minimum) (m)
         wide_bf,             # modeled bankfull width of stream, (m)
         gradient,            # % gradient of stream segment, calculated from USGS DEM
         sthdrate,            # Steelhead IP habitat rating value; 0 = none/very low, 1 = low, 2 = moderate, 3 = high quality
         chinrate,            # Spring/Summer Chinook IP habitat rating value; 0 = none/very low, 1 = low, 2 = moderate, 3 = high quality
         currsthd = currsush, # if value > 0 = current summer steelhead spawning, from state agencies, streamnet, observation, and expert opinion
         currspch,            # if value > 0 = current Spring Chinook spawning, from state agencies, streamnet, observation, and expert opinion
         currsuch) %>%        # if value > 0 = current Summer Chinook spawning, from state agencies, streamnet, observation, and expert opinion
  # merge current spring and summer chinook spawning into a single column
  mutate(currchnk = currspch + currsuch) %>%
  select(-currspch,-currsuch) %>%
  # potential habitat weights based on recommendations from Cooney and Holzer (2006) Appendix C
  mutate(sthd_wt = case_when(sthdrate == 3 ~ 1,
                             sthdrate == 2 ~ 0.5,
                             sthdrate == 1 ~ 0.25,
                             TRUE ~ 0)) %>%
  mutate(chnk_wt = case_when(chinrate == 3 ~ 1,
                             chinrate == 2 ~ 0.5,
                             chinrate == 1 ~ 0.25,
                             TRUE ~ 0)) %>%
  # calculate some potentially useful metrics; matches calculations done by ip group
  mutate(area_ww = length_m * wide_ww,
         area_bf = length_m * wide_bf,
         length_w_sthd = length_m * sthd_wt,
         length_w_chnk = length_m * chnk_wt,
         # note that sthd uses bankfull width; chnk uses wetted width to reflect time of occupancy
         area_w_sthd = area_bf * sthd_wt,
         area_w_chnk = area_ww * chnk_wt) %>%
  # move geometry to the end
  select(everything(), geometry) %>%
  # finally, remove stream reaches with "negligible" habitat for both species; just to reduce file size
  filter(!(chnk_wt == 0 & sthd_wt == 0))

# save the prepped intrinsic potential layer
save(ip_sf, file = here("output/prepped_snake_ip.rda"))
#st_write(ip_sf, here("output/gpkg/prepped_snake_ip.gpkg"), layer = "prepped_ip", delete_dsn = T)

### END SCRIPT