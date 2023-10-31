## a296
## Sarah Chisholm (ApexRMS)
## July 2022
##
## Historic fir analysis
##
## This code:                                                                                                               
## 1. Computes the annual probability of historic fires per BEC variant    
## 2. Computes the normalized fire distribution
## 3. Determines the fire size class distribution  

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Load libraries
library(tidyverse)
library(sf)
library(units)

# Define directories
tabularDataDir <- file.path("Data", "Tabular")
spatialDataDir <- file.path("Data", "Spatial")
tabularModelInputsDir <- file.path("Model-Inputs", "Tabular")
spatialModelInputsDir <- file.path("Model-Inputs", "Spatial")
libraryDir <- "Libraries"

# Load spatial data
# VRI data with aspen % cover
vriAspenPercentCoverage <- st_read(dsn = spatialDataDir, 
                                   layer = "vri-aspen-percent-cover")%>%
  mutate(LEADING =case_when(LEADING == "Trembling Aspen" ~ "Trembling Aspen",
                            LEADING == "Lodgepole Pine (Interior)" ~ "Lodgepole Pine",
                            LEADING == "Douglas Fir Interior" ~ "Douglas Fir",
                            LEADING == "Spruce Hybrid" ~ "Spruce Hybrid",
                            LEADING == "Douglas Fir" ~ "Douglas Fir",
                            LEADING == "Lodgepole Pine" ~ "Lodgepole Pine",
                            LEADING == "Lodgepole Pine (Coast)" ~ "Lodgepole Pine"))

# Historical Fire Perimeters data
firePerimeters <- st_read(dsn = file.path(spatialDataDir,
                                          "BCGW_7113060B_1656359757658_8108", 
                                          "PROT_HISTORICAL_FIRE_POLYS_SP.gdb"),
                layer = "WHSE_LAND_AND_NATURAL_RESOURCE_PROT_HISTORICAL_FIRE_POLYS_SP") %>% 
  mutate(fireYear = FIRE_DATE %>% str_remove("-.*"))

## Historic Fire ----
### Transition Multipliers ----
# Step 1: dissolve vri to make bec sf object
# BEC sf object
becSf <- vriAspenPercentCoverage %>% 
  select(BEC_ZONE_S) %>% 
  group_by(BEC_ZONE_S) %>% 
  summarise

# Calculate total area per BEC
becArea <- becSf %>% 
  st_area %>% 
  drop_units %>% 
  tibble %>% 
  rename(becAreaSqM = ".") %>% 
  mutate(bec = c("Bunch Grass:very dry warm", 
                 "Interior Douglas-fir:dry cool", 
                 "Interior Douglas-fir:very dry mild", 
                 "Sub-Boreal Pine - Spruce:moist cool", 
                 "Sub-Boreal Spruce:dry warm"))

# Step 2: union fire perimeters with bec sf
# zzz: This step was done in QGIS
# Fires per BEC - made in QGIS
fireYearPerBec <- st_read(dsn = "./Data/Spatial", layer = "fire-per-bec") %>% 
  mutate(fireYear = FIRE_DATE %>% str_remove("/.*")) %>% 
  select(fireYear, BEC_ZONE_S) %>% 
  drop_na()

# Create a tibble of BEC variants and all years from 1919 to 2021
becYears <- tibble(
  bec = rep(c("Bunch Grass:very dry warm", 
              "Interior Douglas-fir:dry cool", 
              "Interior Douglas-fir:very dry mild", 
              "Sub-Boreal Pine - Spruce:moist cool", 
              "Sub-Boreal Spruce:dry warm"), each = 103),
  year = rep(seq(1919, 2021), times = 5),
  fireArea = 0)

# Fire area per year per bec
fireAreaYearPerBec <- fireYearPerBec %>%   
  # Get the area of fires
  st_area %>%  
  drop_units %>% 
  tibble %>% 
  rename(fireAreaSqM = ".") %>% 
  # attach year of the fire to area of the fire
  bind_cols(fireYearPerBec) %>% 
  mutate(fireYear = fireYear %>% as.integer,
         fireAreaHa = fireAreaSqM * 1e-4, 
         bec = BEC_ZONE_S) %>% 
  select(bec, fireYear, fireAreaHa) %>% 
  right_join(becYears, by = c("bec" = "bec", "fireYear" = "year")) %>% 
  mutate(fireAreaHa = case_when(is.na(fireAreaHa) ~ fireArea,
                                # add years that had no fires
                                !is.na(fireAreaHa) ~ fireAreaHa)) %>%
  group_by(bec, fireYear) %>% 
  # get the total area per bec burned for all years from 1919 - 2021
  summarise(totalFireAreaHa = sum(fireAreaHa)) %>%  
  ungroup

# Calculate probability of fire per bec
fireProbabilityPerBec <- fireAreaYearPerBec %>% 
  # join bec total area
  left_join(becArea, by = c("bec" = "bec")) %>% 
  mutate(becAreaHa = becAreaSqM * 1e-4,
         # calculate proportion of bec area burned per year
         proportionBecAreaBurned = totalFireAreaHa / becAreaHa) %>% 
  group_by(bec) %>% 
  # get the mean proportion of area burned per bec
  summarise(meanAnnualFireProbability = mean(proportionBecAreaBurned))
             
write_csv(fireProbabilityPerBec, 
          file.path(tabularModelInputsDir,
                    "Transition Multipliers - Historic Fire.csv"))

### Distribution ----
normalizedFireDistribution <- fireAreaYearPerBec %>% 
  # Get the total area burned per year
  group_by(fireYear) %>% 
  summarise(annualAreaBurned = sum(totalFireAreaHa)) %>% 
  # Calculate mean area burned
  mutate(avgAreaBurned = mean(annualAreaBurned),
         # Caluclate normalized distribution of fire area
         normalizedDistribution = annualAreaBurned / avgAreaBurned) 

# Get the frequency of fire sizes
frequencyTable <- count(normalizedFireDistribution, normalizedDistribution) %>% 
  mutate(Distribution = "Historic Fire") %>% 
  rename(Value = normalizedDistribution,
         "Relative Frequency" = n) %>% 
  select(Distribution, Value, `Relative Frequency`)

write_csv(frequencyTable, 
          file.path(tabularModelInputsDir, "Distribution - Historic Fire.csv"))

### Transition Size Distribution ----
# Check the historic range of fire sizes
fireAreaYearPerBec %>% 
  # Get the total area burned per year
  group_by(fireYear) %>% 
  summarise(annualAreaBurned = sum(totalFireAreaHa)) %>% 
  summarise(burnAreaMin = min(annualAreaBurned),
            burnAreaMax = max(annualAreaBurned))
  
#Historical fire sizes range from 0 - 39051 Ha

# Group fire sizes into categories
fireSizeDistribution <- fireAreaYearPerBec %>% 
  # Get the total area burned per year
  group_by(fireYear) %>% 
  summarise(annualAreaBurned = sum(totalFireAreaHa)) %>% 
  # Assign fire size to a bin
  mutate(MaximumArea = 
           case_when(annualAreaBurned <= 1 ~ 1,
                     annualAreaBurned >1 & annualAreaBurned <= 10 ~ 10, 
                     annualAreaBurned >10 & annualAreaBurned <= 100 ~ 100, 
                     annualAreaBurned >100 & annualAreaBurned <= 1000 ~ 1000, 
                     annualAreaBurned >1000 & annualAreaBurned <= 10000 ~ 10000,
                     annualAreaBurned > 10000 ~ 39051) %>% 
           as.factor) %>% 
  # Count number of years per category
  group_by(MaximumArea) %>% 
  summarise(RelativeAmount = n_distinct(fireYear))

write_csv(fireSizeDistribution, 
          file.path(tabularModelInputsDir,
                    "Transition Size Distribution - Historic Fire.csv"))