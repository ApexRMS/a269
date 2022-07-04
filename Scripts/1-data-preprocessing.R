## a269
## Sarah Chisholm 
##
## Data prep

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Define directories
spatialDataDir <- file.path("Data", "Spatial")
tabularDataDir <- file.path("Data", "Tabular")

# Load libraries
library(sf)
library(terra)
library(tidyverse)

# Load data
# Spatial
# VRI shapefile clipped to study area
vri <- st_read(dsn = file.path(spatialDataDir, "VRI_Cariboo_Near.gdb"), layer = "VRI_Clipped_Cariboo")

# Tabular
# ECCC sample plot data (Andrea Norris)
habitatDf <-     read_csv(file.path(tabularDataDir, "Habitat selection - full dataset (30.03.2022).csv"))

coordinatesDf <- read_csv(file.path(tabularDataDir,"stationcoords_wSHP_latlong.csv")) %>% 
                 rename(Site_coords = Site)

speciesDf <-     read_csv(file.path(tabularDataDir, "Nest tree coordinates for woodpeckers.csv")) %>% 
                 mutate(TreeID = TreeID %>% as.character) %>% 
                 rename(Bird_spp = Spp)

## Generate aspen percent cover field ----
# Filter VRI data for species fields
vriTibble <- vri %>% 
  select(FEATURE_ID, SPECIES_CD_1, SPECIES_PCT_1, SPECIES_CD_2, SPECIES_PCT_2,
         SPECIES_CD_3, SPECIES_PCT_3, SPECIES_CD_4, SPECIES_PCT_4,
         SPECIES_CD_5, SPECIES_PCT_5, SPECIES_CD_6, SPECIES_PCT_6, )

# Generate individual sf objects for species levels and filter for aspen
dominantCover1 <- vriTibble %>%
  select(FEATURE_ID, SPECIES_CD_1, SPECIES_PCT_1) %>%
  filter(SPECIES_CD_1 == "AT") %>%
  select(FEATURE_ID, SPECIES_PCT_1) %>%
  rename(AT_PCT = SPECIES_PCT_1)

dominantCover2 <- vriTibble %>%
  select(FEATURE_ID, SPECIES_CD_2, SPECIES_PCT_2) %>%
  filter(SPECIES_CD_2 == "AT") %>%
  select(FEATURE_ID, SPECIES_PCT_2) %>%
  rename(AT_PCT = SPECIES_PCT_2)

dominantCover3 <- vriTibble %>%
  select(FEATURE_ID, SPECIES_CD_3, SPECIES_PCT_3) %>%
  filter(SPECIES_CD_3 == "AT") %>%
  select(FEATURE_ID, SPECIES_PCT_3) %>%
  rename(AT_PCT = SPECIES_PCT_3)

dominantCover4 <- vriTibble %>%
  select(FEATURE_ID, SPECIES_CD_4, SPECIES_PCT_4) %>%
  filter(SPECIES_CD_4 == "AT") %>%
  select(FEATURE_ID, SPECIES_PCT_4) %>%
  rename(AT_PCT = SPECIES_PCT_4)

dominantCover5 <- vriTibble %>%
  select(FEATURE_ID, SPECIES_CD_5, SPECIES_PCT_5) %>%
  filter(SPECIES_CD_5 == "AT") %>%
  select(FEATURE_ID, SPECIES_PCT_5) %>%
  rename(AT_PCT = SPECIES_PCT_5)

dominantCover6 <- vriTibble %>%
  select(FEATURE_ID, SPECIES_CD_6, SPECIES_PCT_6) %>%
  filter(SPECIES_CD_6 == "AT") %>%
  select(FEATURE_ID, SPECIES_PCT_6) %>%
  rename(AT_PCT = SPECIES_PCT_6)

# Bind all records of aspen together as a dataframe
aspenCover <- rbind(dominantCover1, dominantCover2, dominantCover3, 
                    dominantCover4, dominantCover5, dominantCover6) %>% 
  st_drop_geometry()

# Memory management
rm(vriTibble,dominantCover1, dominantCover2, dominantCover3, 
   dominantCover4, dominantCover5, dominantCover6)

# Join the aspen percent cover field to the VRI dataset based on polygon ID
# Remove fields that aren't needed
vri <- vri %>% 
  left_join(y = aspenCover, by = "FEATURE_ID") %>% 
  select(FEATURE_ID, LINE_3_TREE_SPECIES, LINE_4_CLASSES_INDEXES, LINE_5_VEGETATION_COVER, SPECIES_CD_1, 
         BEC_ZONE_CODE, BEC_SUBZONE, BEC_VARIANT, BEC_PHASE,
         QUAD_DIAM_125, QUAD_DIAM_175,
         PROJ_AGE_1, PROJ_AGE_CLASS_CD_1, PROJ_AGE_2, PROJ_AGE_CLASS_CD_2, 
         AT_PCT, PROJECTED_DATE) %>% 
  mutate(BEC_ZONE_SUBZONE = str_c(BEC_ZONE_CODE, BEC_SUBZONE), 
         BEC_ZONE_SUBZONE = case_when(BEC_ZONE_SUBZONE == "BGxw" ~ "Bunch Grass:warm",
                                      BEC_ZONE_SUBZONE == "IDFdk" ~ "Interior Douglas-fir:dry cool",
                                      BEC_ZONE_SUBZONE == "IDFxm" ~ "Interior Douglas-fir:mild",
                                      BEC_ZONE_SUBZONE == "SBPSmk" ~ "Sub-Boreal Pine - Spruce:moist cool",
                                      BEC_ZONE_SUBZONE == "SBSdw" ~ "Sub-Boreal Spruce:dry warm") %>% as.factor,
         BEC_VAR_CODE = case_when(BEC_ZONE_SUBZONE == "Bunch Grass:warm" ~ 1,
                                  BEC_ZONE_SUBZONE == "Interior Douglas-fir:dry cool" ~ 2,
                                  BEC_ZONE_SUBZONE == "Interior Douglas-fir:mild" ~ 3,
                                  BEC_ZONE_SUBZONE == "Sub-Boreal Pine - Spruce:moist cool" ~ 4,
                                  BEC_ZONE_SUBZONE == "Sub-Boreal Spruce:dry warm" ~5) %>% as.numeric,
         LEADING_SPECIES = case_when(SPECIES_CD_1 == "AT" ~ "Trembling Aspen",
                                     SPECIES_CD_1 == "PLI" ~ "Lodgepole Pine (Interior)",
                                     SPECIES_CD_1 == "FDI" ~ "Douglas Fir Interior",
                                     SPECIES_CD_1 == "SX" ~ "Spruce Hybrid",
                                     SPECIES_CD_1 == "FD" ~ "Douglas Fir",
                                     SPECIES_CD_1 == "PL" ~ "Lodgepole Pine",
                                     SPECIES_CD_1 == "AC" ~ "Poplar",
                                     SPECIES_CD_1 == "SW" ~ "White Spruce",
                                     SPECIES_CD_1 == "ACT" ~ "Black Cottonwood",
                                     SPECIES_CD_1 == "PLC" ~ "Lodgepole Pine (Coast)",
                                     SPECIES_CD_1 == "EP" ~ "Paper Birch",
                                     SPECIES_CD_1 == "BL" ~ "Subalpine Fir",
                                     SPECIES_CD_1 == "PY" ~ "Yellow Pine",
                                     SPECIES_CD_1 == "HW" ~ "Western Hemlock") %>% as.factor) %>% 
  rename(DIAM_125 = QUAD_DIAM_125,
         DIAM_175 = QUAD_DIAM_175,
         AGE_CLASS1 = PROJ_AGE_CLASS_CD_1,
         AGE_CLASS2 = PROJ_AGE_CLASS_CD_2)

# Write shapefile to disk
st_write(vri,
         dsn = ".", 
         layer = "vri-aspen-percent-cover",
         driver = "ESRI Shapefile",
         append = FALSE)
## Merge ECCC sample plot data ----
# Divide habitat data set by coordinate reference systems
# Transform coordinates from WGS and UTM 10 (NAD 83) to EPSG 3005
df1 <- habitatDf %>% 
  filter(type == "available") %>% 
  mutate(Site_Point = str_c(Site, "-", Point)) %>% 
  left_join(y = coordinatesDf, by = c("Site_Point" = "SITENUM")) %>% 
  vect(geom = c("longitude", "latitude"), crs = "epsg:4326") %>% 
  project(y = "epsg:3005")

df2 <- habitatDf %>% 
  filter(type == "selected") %>% 
  left_join(y = speciesDf, by = c("Point" = "TreeID")) %>% 
  vect(geom = c("Easting (NAD83)", "Northing (NAD 83)"), crs = "epsg:26910") %>% 
  project(y = "epsg:3005")

# Combine datasets
speciesData <- rbind(df1, df2)

speciesGeomtry <- geom(speciesData)

speciesData$x <- speciesGeomtry[, 3]
speciesData$y <- speciesGeomtry[, 4]

speciesData <- speciesData %>% 
  st_as_sf() %>% 
  #filter(!st_is_empty(.)) %>%
  rename(SITENUM = Site_Point) %>% 
  select(-Site_coords, -X_COORD, -Y_COORD, -`UTM Zone`) %>% 
  tibble()

st_write(speciesData, dsn = "./Data", layer = "eccc-sample-plot-data", driver = "ESRI Shapefile")
write_csv(speciesData, file.path(tabularDataDir, "eccc-sample-plots-merged.csv"))


## Append VRI data fields to sample plot data frame ----
# Leading species
# Aspen % cover
# BEC zone/subzone
# quad_diam_125
# proj_age
# age_class

# Load sample plot data as a SpatVector object
samplePlots <- vect(read_csv(file.path(tabularDataDir, "eccc-sample-plots-merged.csv")), 
                    geom = c("x", "y"), crs = "epsg:3005") %>% 
               st_as_sf()

# Select VRI fields to be appended to plot data
vriSubset <- vri %>% 
  mutate(VRI_BEC = str_c(BEC_ZONE_C, "-", BEC_SUB)) %>% 
  select(FEATURE, BEC_ZONE_C, BEC_SUB, VRI_BEC, LEADING, PROJ_AGE_1, AGE_CLASS1, DIAM_12, AT_PCT) %>% 
  rename(VRI_ID = FEATURE, 
         VRI_BEC_ZONE = BEC_ZONE_C,
         VRI_BEC_SUBZONE = BEC_SUB,
         VRI_SPP = LEADING,
         VRI_AGE = PROJ_AGE_1,
         VRI_CLASS = AGE_CLASS1,
         VRI_DIAM = DIAM_12,
         VRI_AT_PCT = AT_PCT)

# Perform spatial intersection of VRI polygons and sample plot points
samplePlotsVriVector <- st_intersection(samplePlots, vriSubset) 
samplePlotsVriTibble <- st_intersection(samplePlots, vriSubset) %>%
  tibble

# Write tabular and spatial data to disk
st_write(samplePlotsVriVector, 
         dsn = "./Data", 
         layer = "eccc-sample-plot-data-append-vri", 
         driver = "ESRI Shapefile",
         append = FALSE)

write_csv(samplePlotsVriTibbleFilter, file.path(tabularDataDir, "Habitat selection - full dataset - append VRI (12.06.2022).csv"))