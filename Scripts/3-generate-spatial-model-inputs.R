## a296
## Sarah Chisholm (ApexRMS)
## June 30 2022
##
## Build cavity nests st-sim library

## Workspace ----

# Set environment variable TZ when running on AWS EC2 instance
Sys.setenv(TZ='UTC')

# Load libraries
library(rsyncrosim)
library(tidyverse)
library(terra)
library(sf)

# Define directories
spatialDataDir <- file.path("Data", "Spatial")
tabularDataDir <- file.path("Data", "Tabular")
modelInputsDir <- "Model-Inputs"

# Parameters
# Target crs
targetCrs <- "epsg: 3005"

# Target extent
targetExtent <- c(1229152, 1309432, 760673, 819713)

# of columns: 892
# # of rows: 656

# Target resolution
targetResolution <- 90

# Load spaital data
# VRI shapefile (appended with aspen cover)
vriShapefile <- vect(x = file.path(spatialDataDir, "vri-aspen-percent-cover.shp"))

# AAFC Land Cover raster
landcoverRaster <- rast(file.path(spatialDataDir, "LU2015_u10", "LU2015_u10", "LU2015_u10_v3_2021_06.tif"))

## Initial Conditions ----
# Create template raster of study area
templateRaster <- rast()
crs(templateRaster) <- targetCrs
ext(templateRaster) <- targetExtent
res(templateRaster) <- targetResolution

# Primary Stratum ----
becVariantRaster <- rasterize(x = vriShapefile,
                              y = templateRaster, 
                              field = "BEC_VAR_")

# State Class ----
# Rasterize VRI leading species data and reclassify
speciesRaster <- rasterize(x = vriShapefile,
                           y = templateRaster,
                           field = "ledngID")

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
stateClassRaster <- ifel(landcoverRaster == 40, landcoverRaster + speciesRaster, landcoverRaster)

# Age Raster ----
ageRaster <- rasterize(x = vriShapefile,
                       y = templateRaster,
                       field = "PROJ_AGE_1")

## Initial Stocks ----
# Initial Aspen Cover
aspenCoverRaster <- rasterize(x = vriShapefile,
                              y = templateRaster,
                              field = "AT_PCT") 

aspenCoverRaster <- ifel(landcoverRaster == 40, aspenCoverRaster, 0)

# Initial quadratic mean diameter 
diameterRaster <- rasterize(x = vriShapefile,
                            y = templateRaster,
                            field = "DIAM_12") 

diameterRaster <- ifel(landcoverRaster == 40, diameterRaster, 0)

# Write rasters to disk ----
# Primary stratum
writeRaster(x = becVariantRaster,
            filename = file.path(modelInputsDir, "primary-stratum.tif"),
            overwrite = TRUE)

# State Class
writeRaster(x = stateClassRaster,
            filename = file.path(modelInputsDir, "state-class.tif"),
            overwrite = TRUE)

# Age Raster
writeRaster(x = ageRaster,
            filename = file.path(modelInputsDir, "age.tif"),
            overwrite = TRUE)

# Initial Aspen Cover
writeRaster(x = aspenCoverRaster,
            filename = file.path(modelInputsDir, "initial-aspen-cover.tif"),
            overwrite = TRUE)

# Initial Diameter
writeRaster(x = diameterRaster,
            filename = file.path(modelInputsDir, "initial-diameter.tif"),
            overwrite = TRUE)
