# Author: Mike Ackerman
# Purpose: Create leaflet map to view Snake River available habitat datasets (e.g., IP & QRF) 
#   along with TRT population boundaries.
# 
# Created: February 14, 2025
#   Last Modified:
# 
# Notes:
#

# clear environment
rm(list = ls())

# load packages
library(tidyverse)
library(here)
library(sf)
library(leaflet)
#library(readxl)
#library(htmlwidgets)

# -----------------------
# compile data

# populations
load(here("data/spatial/SR_pops.rda")) ; rm(fall_pop)
sthd_pops = sth_pop %>%
  select(TRT_POPID, POP_NAME, MPG) ; rm(sth_pop)
chnk_pops = spsm_pop %>%
  select(TRT_POPID, POP_NAME, MPG) ; rm(spsm_pop)
