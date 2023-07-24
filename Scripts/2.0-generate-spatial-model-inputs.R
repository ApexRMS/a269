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

# Filepath of csv to write sampled vri QMD values to
sampledQMDValuesFilename <- file.path(tabularDataDir, "sampled-vri-qmd.csv")

# Load spaital data
# VRI shapefile as a SpatVector (appended with aspen cover)
vriSpatVector <- vect(x = file.path(spatialDataDir, "vri-aspen-percent-cover.shp"))

# VRI shapefile as an sf object (appended with aspen cover)
vriSf <- st_read(dsn = spatialDataDir, layer = "vri-aspen-percent-cover") %>% 
  select(FEATURE, BEC_VAR_, ledngID, PROJ_AGE_1, DIAM_12) %>% 
  filter(!is.na(ledngID))

# AAFC Land Cover raster
landcoverRaster <- rast(file.path(spatialDataDir, "AAFC", "LU2015_u10", "LU2015_u10", "LU2015_u10_v3_2021_06.tif"))

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

# Historical Fire Perimeters data
firePerimeters <- st_read(dsn = file.path(spatialDataDir,
                                          "BCGW_7113060B_1656359757658_8108", 
                                          "PROT_HISTORICAL_FIRE_POLYS_SP.gdb"),
                          layer = "WHSE_LAND_AND_NATURAL_RESOURCE_PROT_HISTORICAL_FIRE_POLYS_SP") %>% 
  mutate(fireYear = FIRE_DATE %>% str_remove("-.*"))

## Template raster ----
# Create template raster of study area
templateRaster <- rast()
crs(templateRaster) <- targetCrs
ext(templateRaster) <- targetExtent
res(templateRaster) <- targetResolution

## Initial Conditions ----
## Primary Stratum ----
becVariantRaster <- rasterize(x = vriSpatVector,
                              y = templateRaster, 
                              field = "BEC_VAR_")

## Secondary Stratum (Ownership) ----
# Make a backgroup value
fillRaster <- aggregate(vriSpatVector) %>% 
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

## State Class ----
# Rasterize VRI leading species data and reclassify
speciesReclassMatrix <- matrix(data = c(0,1,2,3,4,0,41,42,43,44),
                               nrow = 5, 
                               ncol = 2)

speciesRaster <- rasterize(x = vriSpatVector,
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

### Forest mask ----
# Get unique state class values and reclassify into binary forest values
stateClassValues <- stateClassRaster[] %>% unique() %>% as.vector()
forestValues <- case_when((stateClassValues >= 40 & stateClassValues <= 44) ~ 1,
                          (stateClassValues < 40 | stateClassValues > 44) ~ 0)

# Create reclass matrix
forestReclass <- data.frame(StateClass = stateClassValues,
                            Forest = forestValues) %>% 
  as.matrix()

# Reclassify state class raster to binary forest mask
forestMaskRaster <- stateClassRaster %>% 
  classify(rcl = forestReclass)

## Time Since Transition ----
### Clearcuts ----
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

#### Cut mask ----
cutMaskRaster <- tstRaster

# Where tst <= 60, set to cut (1), where > 60 set to no cut (0)
cutMaskRaster[cutMaskRaster <= 60] <- 1
cutMaskRaster[cutMaskRaster > 60] <- 0

# Mask out non-forest cells
cutMaskRaster <- cutMaskRaster * forestMaskRaster

### Fire ----
timeSinceFire <- firePerimeters %>% 
  mutate(fireYear = fireYear %>% as.numeric()) %>% 
  filter(fireYear <= 2016) %>% 
  mutate(TimeSinceFire = 2016 - fireYear) %>% 
  rasterize(y = templateRaster, 
            field = "TimeSinceFire")

timeSinceFire <- timeSinceFire %>%
  mask(mask = becVariantRaster)

## Age Raster ----
ageRaster <- rasterize(x = vriSpatVector,
                       y = templateRaster,
                       field = "PROJ_AGE_1")

## Initial Stocks ----
### Initial Aspen Cover ----
aspenCoverRaster <- rasterize(x = vriSpatVector,
                              y = templateRaster,
                              field = "AT_PCT") 

aspenCoverRaster <- ifel(speciesRaster != 0, aspenCoverRaster, 0)

### Initial quadratic mean diameter ----
becVariants <- vriSf$BEC_VAR_ %>% unique()
forestTypes <- vriSf$ledngID %>% unique()

# Drop geometry column of vriSf
vriDf <- st_drop_geometry(vriSf)

# Write an emtpy output csv to disk
tibble(FEATURE = integer(0), 
       DIAM_12 = numeric(0)) %>% 
  write_csv(file.path(tabularDataDir, "sampled-vri-qmd.csv"))

# Loop over each combination of bec variant and forest type to randomly sample diameter values
for(becVariant in becVariants){
  for(forestType in forestTypes){
    
    #becVariant <- 5
    #forestType <- 2
    
    # Get diameters for a given BEC variant and forest state class
    diametersToSample <- vriDf %>% 
      filter(BEC_VAR_ == becVariant & 
             ledngID == forestType &
             !is.na(DIAM_12)) %>% 
      pull(DIAM_12)
    
    # Randomly sample from vector of diameters (diametersToSample)
    # Assign these values to features without a diameter 
    vriDf %>% 
      filter(BEC_VAR_ == becVariant & 
               ledngID == forestType &
               is.na(DIAM_12)) %>% 
      mutate(DIAM_12 = sample(diametersToSample,
                              size = length(DIAM_12),
                              replace = TRUE)) %>% 
      select(FEATURE, DIAM_12) %>% 
      # Write sampled qmd values to disk
      write_csv(sampledQMDValuesFilename, append = TRUE)
 }
}

# Join sampled QMD values to vriSf and rasterize diameter column
sampledQMDValues <- read_csv(sampledQMDValuesFilename)

diameterRaster <- vriSf %>% 
  left_join(y = sampledQMDValues,
            by = "FEATURE") %>% 
  mutate(DIAM_12.x = case_when(is.na(DIAM_12.x) ~ DIAM_12.y,
                               !is.na(DIAM_12.x) ~ DIAM_12.x)) %>% 
  rename(DIAM_12 = DIAM_12.x) %>% 
  select(-DIAM_12.y) %>% 
  vect() %>% 
  rasterize(y = templateRaster,
            field = "DIAM_12")
  
diameterRaster[is.na(diameterRaster)] <- 0
diameterRaster <- diameterRaster %>% 
  mask(mask = becVariantRaster)

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

# Forest Mask
writeRaster(x = forestMaskRaster,
            filename = file.path(modelInputsDir, "forest-mask.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# Cut Mask
writeRaster(x = cutMaskRaster,
            filename = file.path(modelInputsDir, "cut-mask.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)

# Time since fire  
writeRaster(x = timeSinceFire,
            filename = file.path(modelInputsDir, "time-since-fire.tif"),
            datatype = "INT2S",
            NAflag = -9999L,
            overwrite = TRUE)
