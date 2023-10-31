## a296
## Sarah Chisholm (ApexRMS)
## June 30 2022
##
## Create spatial model inputs for cavity nests model

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Load libraries
library(tidyverse)
library(terra)
library(sf)

# Define directories
spatialDataDir <- file.path("Data", "Spatial")
tabularDataDir <- file.path("Data", "Tabular")
modelInputsDir <- file.path("Model-Inputs", "Spatial")

# Parameters
# Target crs
targetCrs <- "epsg: 3005"

# Target extent
targetExtent <- c(1229152, 1309432, 760673, 819713)

# Target resolution
targetResolution <- 90

# Buffer distance (m)
bufferDistance <- 100

# Load spaital data
# VRI shapefile (appended with aspen cover)
vriShapefile <- vect(x = file.path(spatialDataDir, "vri-aspen-percent-cover.shp"))

# AAFC Land Cover raster
landcoverRaster <- rast(file.path(spatialDataDir, "LU2015_u10", "LU2015_u10", "LU2015_u10_v3_2021_06.tif"))

# Ownership layers
# Protected areas
protectedAreas <- vect(x = file.path(spatialDataDir, "cpcad-bc-dec2021-clip.shp")) %>% 
  project(y = targetCrs)

# Indian reserves
indianReserves <- vect(x = file.path(spatialDataDir, "indian-reserves-canada-lands-admin-boundary-clip.shp"))

# CWS Federal Lands
cwsLands <- vect(x = file.path(spatialDataDir, "cws-federal-lands-inventory-2019-department-clip.shp"))

# BC Parcels
bcParcels <- st_read(dsn = spatialDataDir, layer = "bc-parcels-clip") %>%  
  mutate(OwnershipCode = case_when(OWNER_TYPE == "Crown Agency" ~ 3,
                                   OWNER_TYPE == "Crown Provincial" ~ 3,
                                   OWNER_TYPE == "Federal" ~ 2,
                                   OWNER_TYPE == "Mixed Ownership" ~ 3,
                                   OWNER_TYPE == "Municipal" ~ 2,
                                   OWNER_TYPE == "None" ~ 3,
                                   OWNER_TYPE == "Private" ~ 2,
                                   OWNER_TYPE == "Unknown" ~ 3)) %>% 
  vect()


# Historic Cutblocks
cutblocks <- st_read(dsn = file.path(spatialDataDir, "Consolidated_Cutblocks", "Consolidated_Cutblocks", "Consolidated_Cut_Block.gdb"),
                 layer = "consolidated-cutblocks-vri-extent")

# Historic Fires
fires <- st_read(dsn = file.path(spatialDataDir, "BCGW_7113060B_1656359757658_8108", "PROT_HISTORICAL_FIRE_POLYS_SP.gdb"),
                     layer = "WHSE_LAND_AND_NATURAL_RESOURCE_PROT_HISTORICAL_FIRE_POLYS_SP")

# Sample sites
sites <- st_read(file.path(spatialDataDir, "eccc-sample-plot-data-append-vri.shp")) 
  
## Template raster ----
# Create template raster of study area
templateRaster <- rast()
crs(templateRaster) <- targetCrs
ext(templateRaster) <- targetExtent
res(templateRaster) <- targetResolution

## Initial Conditions ----
## Primary Stratum ----
becVariantRaster <- rasterize(x = vriShapefile,
                              y = templateRaster, 
                              field = "BEC_VAR_")

## Secondary Stratum (Ownership) ----
# Make a backgroup value
fillRaster <- aggregate(vriShapefile) %>% 
  rasterize(y = templateRaster)

fillRaster[fillRaster == 1] <- 3

### Baseline ----
# Rasterize input layers
# Protected areas
protectedAreasRaster <- rasterize(x = protectedAreas,
                                  y = templateRaster,
                                  field = "OBJECTID")

protectedAreasRaster[protectedAreasRaster > 0] <- 1

# Indian reserves (private land)
indianReservesRaster <- rasterize(x = indianReserves,
                                  y = templateRaster,
                                  field = "OBJECTID_1")

indianReservesRaster[indianReservesRaster > 0] <- 2

# CWS Federal Lands (private land)
cwsLandsRaster <- rasterize(x = cwsLands,
                            y = templateRaster,
                            field = "OBJECTID")

cwsLandsRaster[cwsLandsRaster > 0] <- 2

# BC Parcels
bcParcelsRaster <- rasterize(x = bcParcels, 
                             y = templateRaster,
                             field = "OwnershipCode")

# Merge to create baseline ownership raster
baselineOwnershipRaster <- merge(protectedAreasRaster, indianReservesRaster,
                           cwsLandsRaster, bcParcelsRaster, fillRaster)

### Aspen protection ----
# Apply a 100m buffer to aspen dominant polygons
aspenPolygons <- st_read(dsn = spatialDataDir,
                        layer = "vri-aspen-percent-cover") %>% 
  # mutate(SpeciesCode = case_when(ledngID == "AT" ~ 1,
  #                                ledngID != "AT" ~ 0)) %>% 
  filter(ledngID == 1) %>% 
  st_buffer(dist = bufferDistance)

# Convert buffered aspen polygons to raster
aspenDominant <- rasterize(x = aspenPolygons,
                           y = templateRaster,
                           field = "ledngID")
aspenDominant[is.na(aspenDominant)] <- 0

# Mask buffered aspen raster by non-forest or non-grassland cells
stateClassReclassMatrix = matrix(data = c(20,30,40,41,42,43,44,50,60,70,90,
                                          1,1,NA,NA,NA,NA,NA,1,NA,1,1),
                                 nrow = 11,
                                 ncol = 2)

stateClassRaster <- rast(file.path(modelInputsDir, "state-class.tif")) %>% 
  classify(rcl = stateClassReclassMatrix)

# Get Aspen buffer cells to exclude
aspenToExclude <- aspenDominant * stateClassRaster
aspenToExclude[is.na(aspenToExclude)] <- 0

# Remove buffered aspen cells that fall in a non-forest or non-grassland cell
protectedAspen <- aspenDominant - aspenToExclude
protectedAspen[protectedAspen == 0] <- NA

# Mask this by public lands in the baseline ownership raster
publicLands <- rast(file.path(modelInputsDir, "ownership-baseline.tif"))
publicLands[publicLands !=3 ] <- NA

maskedProtectedAspen <- protectedAspen %>% 
  mask(mask = publicLands)

# Merge maskedProtectedAspen with baseline ownership raster
baselineOwnershipRaster <- rast(file.path(modelInputsDir, "ownership-baseline.tif"))
aspenProtectionOwnershipRaster <- merge(maskedProtectedAspen, baselineOwnershipRaster)

### Military training land protection ----
cwsLands <- st_read(dsn = spatialDataDir, layer = "cws-federal-lands-inventory-2019-department-clip") %>%
  mutate(OwnershipCode = case_when(Custodian == "Department of National Defence" ~ 1,
                                   Custodian == "Fisheries and Oceans Canada" ~ 2,
                                   Custodian == "Indigenous and Northern Affairs Canada" ~ 2,
                                   Custodian == "Royal Canadian Mounted Police" ~ 2,
                                   Custodian == "Transport Canada" ~ 2)) %>% 
  vect()

cwsLandsRaster <- rasterize(x = cwsLands,
                            y = templateRaster,
                            field = "OwnershipCode")

militaryTraningProtectionOwnershipRaster <- merge(protectedAreasRaster, indianReservesRaster,
                                 cwsLandsRaster, bcParcelsRaster, fillRaster)

## Time Since Transition (Clearcuts) ----
# Calculate time since last cut (relative to 2016)
tstRaster <- cutblocks %>% 
  filter(Harvest_Ye <= 2016) %>% 
  mutate(TimeSinceCut = 2016 - Harvest_Ye) %>% 
  filter(TimeSinceCut <= 60) %>% 
  rasterize(y = templateRaster, 
            field = "TimeSinceCut")

tstRaster[is.na(tstRaster)] <- 61
tstRaster <- tstRaster %>%
  mask(mask = becVariantRaster)

## State Class ----
# Rasterize VRI leading species data and reclassify
speciesReclassMatrix <- matrix(data = c(0,1,2,3,4,0,41,42,43,44),
                               nrow = 5, 
                               ncol = 2)

speciesRaster <- rasterize(x = vriShapefile,
                           y = templateRaster,
                           field = "ledngID") %>% 
  classify(rcl = speciesReclassMatrix)

# Reclassify land cover into more broad classes
landcoverReclassMatrix <- matrix(data = c(21,22,24,25,28,29,31,41,42,43,44,49,51,52,61,62,71,91,
                                          20,20,20,20,20,20,30,40,40,40,40,40,50,50,60,60,70,90),
                                 nrow = 18,
                                 ncol = 2)

# Project, crop, resample, and reclassify landcover raster
landcoverRaster <- landcoverRaster %>% 
  project(y = templateRaster,
          method = "near") %>% 
  classify(rcl = landcoverReclassMatrix) %>% 
  mask(mask = becVariantRaster)

# Combine landcover and species rasters
# If land cover = forest (4), add species code
stateClassRaster <- ifel(speciesRaster == 0, speciesRaster + landcoverRaster, speciesRaster)

## Age Raster ----
ageRaster <- rasterize(x = vriShapefile,
                       y = templateRaster,
                       field = "PROJ_AGE_1")

## Initial Stocks ----
# Initial Aspen Cover
aspenCoverRaster <- rasterize(x = vriShapefile,
                              y = templateRaster,
                              field = "AT_PCT") 

aspenCoverRaster <- ifel(speciesRaster != 0, aspenCoverRaster, 0)

# Initial quadratic mean diameter 
diameterRaster <- rasterize(x = vriShapefile,
                            y = templateRaster,
                            field = "DIAM_12") 

diameterRaster <- ifel(speciesRaster != 0, diameterRaster, 0)

## Mean decay ----
meanDecayRaster <- sites %>% 
  tibble %>% 
  select(BEC_ZON, Men_dcy) %>% 
  na.omit %>% 
  group_by(BEC_ZON) %>% 
  # Get mean decay by BEC zone
  summarise(MeanDecay = mean(Men_dcy)) %>% 
  mutate(BEC_ZON = case_when(BEC_ZON == "Interior Douglas-fir:mild" ~ "Interior Douglas-fir:very dry mild",
                             BEC_ZON != "Interior Douglas-fir:mild " ~ BEC_ZON)) %>% 
  # Add an NA row for Bunchgrass (no sample sites in BG)
  bind_rows(tibble(BEC_ZON = "Bunch Grass:very dry warm",
                   MeanDecay = .$MeanDecay[.$BEC_ZON == "Interior Douglas-fir:very dry mild"])) %>% 
  # Join mean decay values with raster IDs for BEC zone
  left_join(vriShapefile %>% 
              st_as_sf %>% 
              tibble %>% 
              select(BEC_ZONE_S, BEC_VAR_) %>% 
              distinct,
            by = join_by(BEC_ZON == BEC_ZONE_S)) %>% 
  select(-BEC_ZON) %>%
  select(BEC_VAR_, MeanDecay) %>% 
  as.matrix() %>% 
  # Reclassify BEC raster with mean decay values
  classify(x = becVariantRaster, rcl = .)

names(meanDecayRaster) <- "Mean_decay"

## Spatial Transition Multipliers ----
### Historic Fires ----
fireYears <- fires %>% filter(FIRE_YEAR >= 2016) %>% pull(FIRE_YEAR) %>% unique

for(fireYear in seq(min(fireYears),max(fireYears))){
  
  outputFile <- "tm-fire-" %>% str_c(fireYear %>% as.character(), ".tif")
  
  fires %>% 
    filter(FIRE_YEAR == fireYear) %>% 
    vect %>% 
    rasterize(y = templateRaster) %>% 
    classify(rcl = matrix(data = c(1, NA, 1, 0), ncol = 2, nrow = 2)) %>% 
    mask(mask = becVariantRaster) %>% 
    writeRaster(file.path(modelInputsDir, outputFile),
                datatype = "INT2S",
                NAflag = -9999L,
                overwrite = TRUE)
}

### Historic Cuts ----
cutYears <- cutblocks %>% filter(Harvest_Ye >= 2016) %>% pull(Harvest_Ye) %>% unique

for(cutYear in seq(min(cutYears),max(cutYears))){
  
  outputFile <- "tm-cut-" %>% str_c(cutYear %>% as.character(), ".tif")
  
  cutblocks %>% 
    filter(Harvest_Ye == cutYear) %>% 
    vect %>% 
    rasterize(y = templateRaster) %>% 
    classify(rcl = matrix(data = c(1, NA, 1, 0), ncol = 2, nrow = 2)) %>% 
    mask(mask = becVariantRaster) %>% 
    writeRaster(file.path(modelInputsDir, outputFile),
                datatype = "INT2S",
                NAflag = -9999L,
                overwrite = TRUE)
}

### Reset Disturbances ----
tmRaster <- becVariantRaster
tmRaster[!is.na(tmRaster)] <- 1
writeRaster(tmRaster,
            file.path(modelInputsDir, "tm-cut-2022.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

writeRaster(tmRaster,
            file.path(modelInputsDir, "tm-fire-2022.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)
## Write rasters to disk ----
# Primary stratum
writeRaster(x = becVariantRaster,
            filename = file.path(modelInputsDir, "primary-stratum.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# Ownership - baseline
writeRaster(x = baselineOwnershipRaster,
            filename = file.path(modelInputsDir, "secondary-stratum-baseline.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# Ownership - aspen protection
writeRaster(x = aspenProtectionOwnershipRaster,
            filename = file.path(modelInputsDir, "secondary-stratum-aspen-protection.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# Ownership - military training land protection
writeRaster(x = militaryTraningProtectionOwnershipRaster,
            filename = file.path(modelInputsDir, "secondary-stratum-military-training-land-protection.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# Time Since Transition (Clearcuts)
writeRaster(x = tstRaster,
            filename = file.path(modelInputsDir, "time-since-cut.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# State Class
writeRaster(x = stateClassRaster,
            filename = file.path(modelInputsDir, "state-class.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# Age Raster
writeRaster(x = ageRaster,
            filename = file.path(modelInputsDir, "age.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# Initial Aspen Cover
writeRaster(x = aspenCoverRaster,
            filename = file.path(modelInputsDir, "initial-aspen-cover.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# Initial Diameter
writeRaster(x = diameterRaster,
            filename = file.path(modelInputsDir, "initial-diameter.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# Mean decay
writeRaster(x = meanDecayRaster,
            filename = file.path(modelInputsDir, "mean-decay.tif"),
            datatype = "FLT4S",
            NAflag = -9999L,
            overwrite = TRUE)
