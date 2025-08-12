# -----------------------
# Author: Mike Ackerman
# Purpose: Prep various raw fish (e.g., redd survey) datasets for further use.
# 
# Created: August 7, 2025
#   Last Modified: 
# 
# Notes:

# clear environment
rm(list = ls())

# load necessary packages
library(here)
library(tidyverse)
library(sf)
library(janitor)

# install cdmsR and cuyem
remotes::install_github("ryankinzer/cdmsR")
library(cdmsR)
remotes::install_github("ryankinzer/cuyem")
library(cuyem)

# idfg sp/sum chnk spatial redd data
ifwis_chnk_redd_sf = read_csv(file = here("data/ifwis_redd_detail_export_20250807.csv"), show_col_types = F) %>%
  clean_names() %>%
  filter(!is.na(latitude) & !is.na(longitude)) %>%
  # remove some earlier years where there was less effort
  filter(survey_year >= 2000) %>%
  # focus on chinook, limited data for other species
  filter(species == "SP/SU Chinook") %>%
  select(waypoint_id,
         waterbody,
         trt_pop,
         trt_mpg,
         survey_id,
         transect_id,
         survey_year,
         start_date,
         species,
         sample_method,
         drainage,
         agency,
         collector,
         longitude,
         latitude) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# write to .gpkg
st_write(ifwis_chnk_redd_sf, here("output/gpkg/ifwis_chnk_redd_export_20250807.gpkg"), layer = "redd_pts", delete_layer = T)

# login to cdms
pw = readLines("cdms_pw/ma_cdms_pw.txt")
cdmsLogin(username = "mikea", api_key = pw) ; rm(pw)

# get npt redd data from cdms
cdms_redd_raw = cdmsR::get_ReddData()
cdms_redd_df = cuyem::clean_reddData(cdms_redd_raw) %>%
  # quick fixes to make columns match
  select(-RowId) %>%
  rename(Year = CalendarYear) %>%
  mutate(SurveyDate = as.Date(SurveyDate))

cdms_redd_neor_raw = cdmsR::get_ReddData_NEOR(GRSME_ONLY = F)
cdms_redd_neor_df = cuyem::clean_reddData_NEOR(cdms_redd_neor_raw)

# which columns are different from cdms datasets
setdiff(names(cdms_redd_df), names(cdms_redd_neor_df))
setdiff(names(cdms_redd_neor_df), names(cdms_redd_df))

# now join cdms redd datasets, clean, and make spatial
cdms_chnk_redd_sf = bind_rows(cdms_redd_df, cdms_redd_neor_df) %>%
  clean_names() %>%
  # just focus on sp/sum Chinook, for now
  filter(esu_dps == "Snake River Spring/Summer-run Chinook Salmon ESU") %>%
  select(species,
         esu_dps,
         mpg,
         trt_popid,
         stream_name,
         location_label,
         survey_year,
         survey_date,
         survey_method,
         latitude,
         longitude) %>%
  filter(!(is.na(latitude) | latitude == "" | is.na(longitude) | longitude == "")) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) 

# write to .gpkg
st_write(cdms_chnk_redd_sf, here("output/gpkg/cdms_chnk_redd_export_20250807.gpkg"), layer = "redd_pts", delete_layer = T)

# idfg sp/sum chnk and steelhead juvenile fish survey data
ifwis_juv_sf = read_csv(file = here("data/ifwis_juv_chnk_sthd_survey_export_20250812.csv"), show_col_types = F) %>%
  clean_names() %>%
  filter(!is.na(new_lat) & !is.na(new_long)) %>%
  select(stream,
         year,
         survey_date,
         fish_pres_desc,
         pname,
         agency,
         program,
         method,
         s_name,
         sci_name,
         length_group,
         sum_number_counted,
         age_class,
         new_lat,
         new_long) %>%
  # create a spc_code column for easy filtering
  mutate(spc_code = case_when(
    str_detect(s_name, "Chinook") ~ "chnk",
    str_detect(s_name, "Steelhead") ~ "sthd",
    TRUE ~ NA
  )) %>%
  st_as_sf(coords = c("new_long", "new_lat"), crs = 4326)

# just export one species at a time using spc_code
ifwis_juv_sf %>%
  filter(spc_code == "chnk") %>%
  st_write(here("output/gpkg/ifwis_juv_chnk_export_20250812.gpkg"), layer = "obs_pts", delete_layer = T)

### END SCRIPT
