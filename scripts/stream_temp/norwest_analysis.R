# -----------------------
# Author: Mike Ackerman
# Purpose:
#
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

# ictrt population polygons
load(here("data/spatial/SR_pops.rda")) ; rm(fall_pop)
sthd_pops = sth_pop %>%
  st_transform(default_crs) ; rm(sth_pop)
chnk_pops = spsm_pop %>%
  st_transform(default_crs) ; rm(spsm_pop)

# snake river basin 200m reach stream network w/ habitat and norwest attributes
load(here("output/prepped_snake_200m_rch_norwest.rda"))

# trim down but include norwest, data
srb_norwest_sf = srb_rch_sf %>%
  select(gnis_name = GNIS_Name,
         strm_order,
         reach_leng_m = reach_leng,
         chnk,
         chnk_use,
         sthd,
         sthd_use,
         rec_hist = S2_02_11,
         proj_2040 = S30_2040D,
         proj_2080 = S32_2080D) %>%
  # keep only reaches used by either sp/sum chinook or steelhead (according to StreamNet)
  filter(chnk == TRUE | sthd == TRUE)

# combinations of species/life stages and threshholds
species = c("chnk", "sthd")
life_stage = c("spawn", "parr")
threshold = c("abv_opt", "abv_max", "abv_acute")

# assign temp (c) values to each (chnk spawn, chnk parr, sthd parr)
temp_c_values = c(
  14.5, 16, 18, # above optimum
  17.7, 19, 19, # above maximum
  20, 22, 22    # above acute
)

# create data frame of species/life stage temp threshhold values
thresh_df = expand.grid(species = species,
                        life_stage = life_stage,
                        threshold = threshold) %>%
  filter(!(species == "sthd" & life_stage == "spawn")) %>%
  mutate(temp_c = temp_c_values)

results_df = NULL

# loop over species
for (spc in species) {
  
  # grab appropriate trt populations polygons
  if (spc == "chnk") { pops = chnk_pops %>% select(popid = TRT_POPID, mpg = MPG) }
  if (spc == "sthd") { pops = sthd_pops %>% select(popid = TRT_POPID, mpg = MPG) }
  
  # filter thresh_df for species of interest
  spc_thresh_df = thresh_df %>%
    filter(species == spc)
  
  # loop over populations
  for (p in 1:nrow(pops)) {
    
    # grab population polygon
    pop_poly = pops[p,]
    
    cat(paste0("Calculating suitable rkms in population ", pop_poly$popid, ".\n"))
    
    pop_norwest_sf = srb_norwest_sf %>%
      # trim to spatial extents for chnk or sthd (according to streamnet)
      filter(.data[[spc]] == TRUE) %>%
      st_intersection(pop_poly) %>%
      st_drop_geometry()
    
    pop_results = spc_thresh_df %>%
      mutate(popid = pop_poly$popid,
             mpg = pop_poly$mpg) %>%
      mutate(spc_extent_km = sum(pop_norwest_sf$reach_leng_m, na.rm = T) / 1000) %>%
      rowwise() %>%
      mutate(
        rec_hist_km  = sum(pop_norwest_sf$reach_leng_m[pop_norwest_sf$rec_hist <= temp_c], na.rm = T) / 1000,
        proj_2040_km = sum(pop_norwest_sf$reach_leng_m[pop_norwest_sf$proj_2040 <= temp_c], na.rm = T) / 1000,
        proj_2080_km = sum(pop_norwest_sf$reach_leng_m[pop_norwest_sf$proj_2080 <= temp_c], na.rm = T) / 1000
      ) %>%
      ungroup()
    
    # append pop results to results_df
    results_df = bind_rows(results_df, pop_results)
    
  } # end population polygon
  
} # end species polygon

# calculate proportion of habitat loss
srb_results_df = results_df %>%
  mutate(p_loss_2040 = (rec_hist_km - proj_2040_km) / rec_hist_km,
         p_loss_2080 = (rec_hist_km - proj_2080_km) / rec_hist_km)

# chinook spawning dotplot
chnk_spawn_loss_p = srb_results_df %>%
  filter(species == "chnk" & life_stage == "spawn" & threshold == "abv_max") %>%
  filter(!spc_extent_km == 0) %>%
  ggplot() +
  geom_point(aes(x = p_loss_2040, y = fct_reorder(popid, p_loss_2080, .desc = F), color = mpg), shape = 1, size = 3) +
  geom_point(aes(x = p_loss_2080, y = fct_reorder(popid, p_loss_2080, .desc = F), color = mpg), shape = 16, size = 3) +
  #scale_color_viridis_d(option = "viridis") +
  theme_minimal() +
  labs(
    title = "Chinook Salmon, Spawning",
    x = "Proportion of Current Habitat Exceeding Max Temps by 2040 (open) and 2080 (closed)",
    y = "Population",
    color = "MPG"
  ) +
  theme(
    axis.text.y = element_text(size = 10),
    legend.position = "bottom"
  )
chnk_spawn_loss_p

# save dotplot
ggsave(here("output/figures/chnk_spawn_hab_loss.pdf"), width = 8.5, height = 11)

# chinook spawning map
chnk_spawn_loss_map = chnk_pops %>%
  select(popid = TRT_POPID,
         geometry) %>%
  left_join(srb_results_df %>%
              filter(species == "chnk" & life_stage == "spawn" & threshold == "abv_max") %>%
              select(popid, p_loss_2080)) %>%
  ggplot() +
  geom_sf(aes(fill = p_loss_2080),
          color = "black",
          size = 0.5) +
  scale_fill_gradient(low = "white", high = "red") +
  theme_minimal() +
  labs(title = "Proportion of Current sp/sum Chinook Salmon Habitat Exceeding Max Spawn Temps by 2080",
       fill = "Proportion")
chnk_spawn_loss_map

# save map
ggsave(here("output/figures/chnk_spawn_hab_loss_map.pdf"), width = 8.5, height = 11)

### END SCRIPT
