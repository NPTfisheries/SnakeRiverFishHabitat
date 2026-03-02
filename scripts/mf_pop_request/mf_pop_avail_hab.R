# -----------------------
# Author: Mike Ackerman
# Purpose: Summarize available spawning and rearing habitat in MF Salmon populations for sp/sum Chinook salmon
#   and steelhead.
# 
# Created: March 2, 2026
#   Last Modified: 
# 
# Notes: Largely based on 03_est_avail_habitat.R script from SnakeRiverIPTDS

# clear environment
rm(list = ls())

# load packages
library(sf)
library(tidyverse)
library(janitor)
library(ggrepel)
library(writexl)

# set default crs
default_crs = st_crs(32611) # WGS 84, UTM zone 11N

#--------------------
# load and prep data

# ictrt population polygons
load("data/spatial/SR_pops.rda") ; rm(fall_pop)
sthd_pops = sth_pop %>%
  st_transform(default_crs) ; rm(sth_pop)
chnk_pops = spsm_pop %>%
  st_transform(default_crs) ; rm(spsm_pop)

# list of middle fork salmon populations
mf_pops = sthd_pops %>%
  select(TRT_POPID,
         POP_NAME,
         ESU_DPS,
         geometry) %>%
  filter(TRT_POPID %in% c("MFUMA-s", "MFBIG-s")) %>%
  bind_rows(chnk_pops %>%
              select(TRT_POPID,
                     POP_NAME,
                     ESU_DPS,
                     geometry) %>%
              filter(TRT_POPID %in% c("MFBEA", "MFMAR", "MFSUL", "MFUMA", "MFLOO", "MFLMA", "MFCAM", "MFBIG"))) %>%
  mutate(spc_code = case_when(
    str_detect(ESU_DPS, "Steelhead") ~ "sthd",
    str_detect(ESU_DPS, "Chinook")   ~ "chnk",
    TRUE ~ NA_character_
  )) %>% 
  st_transform(default_crs)

# load the prepped redd qrf dataset
qrf_sf = get(load(file = "../SnakeRiverFishHabitat/output/prepped_snake_redd_qrf.rda")) %>%
  st_transform(default_crs)

# function to summarize qrf length for a given pop and life stage
summarise_qrf_len = function(pop_poly, 
                             spc_code, 
                             life_stage, 
                             qrf_sf) {
  
  # habitat filter values
  use_vals = if (life_stage == "spawning") { 
    "Spawning and rearing" 
  } else if (life_stage == "rearing") {  
    c("Spawning and rearing", "Rearing and migration") 
  } else { 
    stop("habitat_mode must be 'spawning' or 'rearing'") 
  }
  
  qrf_sf %>%
    st_intersection(pop_poly) %>%
    st_drop_geometry() %>%
    {
      if (spc_code == "chnk") {
        filter(., chnk == TRUE, chnk_use %in% use_vals)
      } else if (spc_code == "sthd") {
        filter(., sthd == TRUE, sthd_use %in% use_vals)
      } else {
        stop("spc_code must be 'chnk' or 'sthd'")
      }
    } %>%
    summarise(qrf_length_m = sum(reach_leng_m, na.rm = TRUE), .groups = "drop")
}

mf_pop_qrf_lengths = map_dfr(seq_len(nrow(mf_pops)), function(i) {
  
  popid    = mf_pops$TRT_POPID[i]
  spc_code = mf_pops$spc_code[i]
  
  # get polygon for population
  pop_poly <- mf_pops[i, ] %>%
    select(popid = TRT_POPID)
  
  bind_rows(
    summarise_qrf_len(pop_poly, spc_code, "spawning", qrf_sf) %>%
      mutate(popid = popid, spc_code = spc_code, life_stage = "spawning"),
    summarise_qrf_len(pop_poly, spc_code, "rearing", qrf_sf) %>%
      mutate(popid = popid, spc_code = spc_code, life_stage = "rearing")
  )
}) 

# final prep for export
mf_pop_summ = mf_pop_qrf_lengths %>%
  mutate(length_miles = round(qrf_length_m * 0.000621371),
         Species = case_when(
           spc_code == "chnk" ~ "Sp/Sum Chinook Salmon",
           spc_code == "sthd" ~ "Steelhead"
         )) %>%
  left_join(mf_pops %>%
              select(TRT_POPID, POP_NAME),
            by = c("popid" = "TRT_POPID")) %>%
  select(Species,
         TRT_POPID = popid,
         `Population Name` = POP_NAME,
         `Life Stage` = life_stage,
         `Length (mi)` = length_miles) %>%
  arrange(Species, TRT_POPID)

# create total rows
mf_totals = mf_pop_summ %>%
  group_by(Species, `Life Stage`) %>%
  summarise(
    `Length (mi)` = sum(`Length (mi)`, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    TRT_POPID = "Total",
    `Population Name` = "Total"
  ) %>%
  select(Species,
         TRT_POPID,
         `Population Name`,
         `Life Stage`,
         `Length (mi)`)

# bind totals back in
mf_pop_summ = bind_rows(mf_pop_summ, mf_totals) %>%
  arrange(Species, `Life Stage`, TRT_POPID)

# write to file
write_xlsx(mf_pop_summ, path = "output/mf_pop_request/mf_miles_avail_habitat.xlsx")

# save the important objects
save(site_avail_hab,
     pop_avail_hab,
     avail_hab_df,
     file = "output/available_habitat/snake_river_iptds_and_pop_available_habitat.rda")

### END SCRIPT